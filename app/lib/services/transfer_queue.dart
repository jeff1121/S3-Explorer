import 'dart:async';
import 'dart:collection';

import 'package:app/models/entities.dart';
import 'package:app/services/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

typedef TransferExecutor = Future<void> Function(TransferTask task, TransferController control);

class TransferController {
  TransferController({required this.onProgress});

  final void Function(TransferProgress progress) onProgress;
  bool _paused = false;
  bool _canceled = false;
  Completer<void>? _resumeCompleter;

  void reportProgress(TransferProgress progress) => onProgress(progress);

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
    _resumeCompleter?.complete();
    _resumeCompleter = null;
  }

  void cancel() {
    _canceled = true;
    _resumeCompleter?.complete();
    _resumeCompleter = null;
  }

  bool get isCanceled => _canceled;

  Future<void> waitIfPaused() async {
    while (_paused && !_canceled) {
      _resumeCompleter ??= Completer<void>();
      await _resumeCompleter!.future;
    }
    if (_canceled) throw StateError('Task canceled');
  }

  void throwIfCanceled() {
    if (_canceled) throw StateError('Task canceled');
  }
}

/// Transfer queue with concurrency control and pause/resume/cancel support.
///
/// Performance Parameters:
/// - [maxConcurrent]: Maximum number of concurrent transfers (default: 3)
///   - Recommended range: 1-10
///   - Higher values = faster for multiple small files
///   - Lower values = more stable for large files or slow connections
///
/// Usage:
/// ```dart
/// final queue = TransferQueue(maxConcurrent: 5);
/// final task = await queue.enqueue(
///   type: TransferType.upload,
///   source: EndpointRef(localPath: '/path/to/file'),
///   target: EndpointRef(bucket: 'my-bucket', key: 'my-key'),
/// );
/// await queue.waitFor(task.id);
/// ```
class TransferQueue with ChangeNotifier {
  TransferQueue({AppLogger? logger, this.maxConcurrent = 3}) : _logger = logger ?? const AppLogger();

  final AppLogger _logger;
  
  /// Maximum number of tasks that can run concurrently.
  /// Default: 3. Recommended range: 1-10.
  final int maxConcurrent;
  final _uuid = const Uuid();
  final List<TransferTask> _tasks = [];
  final Map<String, TransferExecutor> _executors = {};
  final Map<String, Completer<TransferTask>> _completers = {};
  final Map<String, TransferController> _controllers = {};
  final Queue<TransferTask> _pending = Queue();
  final Set<String> _running = {};

  List<TransferTask> get tasks => List.unmodifiable(_tasks);

  Future<TransferTask> waitFor(String taskId) {
    final completer = _completers[taskId];
    if (completer != null) {
      return completer.future;
    }
    final existing = _tasks.where((t) => t.id == taskId).cast<TransferTask?>().firstWhere((t) => t != null, orElse: () => null);
    if (existing != null && (existing.status == TransferStatus.completed || existing.status == TransferStatus.failed || existing.status == TransferStatus.canceled)) {
      return Future.value(existing);
    }
    return Future.error(StateError('Task $taskId not found'));
  }

  TransferTask enqueue({
    required TransferType type,
    required EndpointRef source,
    required EndpointRef target,
    bool useMultipart = true,
    int? partSizeMb,
    int? concurrency,
    bool overwrite = true,
    TransferProgress? progress,
    TransferExecutor? executor,
  }) {
    final task = TransferTask(
      id: _uuid.v4(),
      type: type,
      source: source,
      target: target,
      useMultipart: useMultipart,
      partSizeMb: partSizeMb,
      concurrency: concurrency,
      overwrite: overwrite,
      status: TransferStatus.pending,
      progress: progress ?? const TransferProgress(),
    );
    _tasks.add(task);
    if (executor != null) {
      _executors[task.id] = executor;
    }
    _controllers[task.id] = TransferController(onProgress: (p) => _updateProgress(task.id, p));
    _completers[task.id] = Completer<TransferTask>();
    _pending.add(task);
    notifyListeners();
    _tryDequeue();
    return task;
  }

  void pause(String taskId) {
    _controllers[taskId]?.pause();
    _updateStatus(taskId, TransferStatus.paused);
  }

  void resume(String taskId) {
    _controllers[taskId]?.resume();
    _updateStatus(taskId, TransferStatus.running);
  }

  void cancel(String taskId) {
    _controllers[taskId]?.cancel();
    _pending.removeWhere((t) => t.id == taskId);
    _updateStatus(taskId, TransferStatus.canceled);
    _completeTask(taskId, error: StateError('Task canceled'));
  }

  void _updateStatus(String taskId, TransferStatus status) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(status: status);
    notifyListeners();
  }

  void _updateProgress(String taskId, TransferProgress progress) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    _tasks[index] = _tasks[index].copyWith(progress: progress);
    notifyListeners();
  }

  void _tryDequeue() {
    if (_running.length >= maxConcurrent) return;
    if (_pending.isEmpty) return;
    final next = _pending.removeFirst();
    _running.add(next.id);
    _runTask(next);
  }

  Future<void> _runTask(TransferTask task) async {
    _updateStatus(task.id, TransferStatus.running);
    try {
      final executor = _executors[task.id];
      final controller = _controllers[task.id];
      if (controller == null) throw StateError('No controller for task ${task.id}');
      controller.throwIfCanceled();
      await controller.waitIfPaused();
      if (executor != null) {
        await executor(task, controller);
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        controller.reportProgress(task.progress.copyWith(bytesTransferred: task.progress.totalBytes == 0 ? 1 : task.progress.totalBytes));
      }
      controller.throwIfCanceled();
      _updateStatus(task.id, TransferStatus.completed);
      _logger.info('Task ${task.id} completed');
      _completeTask(task.id);
    } catch (e, st) {
      _logger.error('Task ${task.id} failed', e, st);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(status: TransferStatus.failed, error: e.toString());
        notifyListeners();
      }
      _completeTask(task.id, error: e);
    } finally {
      _running.remove(task.id);
      _executors.remove(task.id);
      _controllers.remove(task.id);
      _tryDequeue();
    }
  }

  void _completeTask(String taskId, {Object? error}) {
    final completer = _completers.remove(taskId);
    if (completer == null || completer.isCompleted) return;
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      completer.completeError(StateError('Task $taskId missing after completion'));
      return;
    }
    final task = _tasks[index];
    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete(task);
    }
  }
}
