import 'dart:async';

import 'package:app/models/entities.dart';
import 'package:app/services/object_service.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Sync mode
enum SyncMode {
  oneWay,   // Source to target only
  mirror,   // Source to target with deletion of extra files
}

/// Conflict policy when file exists
enum ConflictPolicy {
  overwrite,  // Overwrite target
  skip,       // Skip if exists
  keepBoth,   // Keep both (rename new)
}

/// Sync job configuration
class SyncJob {
  SyncJob({
    required this.id,
    required this.name,
    required this.source,
    required this.target,
    required this.mode,
    required this.conflictPolicy,
    required this.status,
    this.filesScanned = 0,
    this.filesTransferred = 0,
    this.bytesTransferred = 0,
    this.totalBytes = 0,
    this.errors = const [],
  });

  final String id;
  final String name;
  final EndpointRef source;
  final EndpointRef target;
  final SyncMode mode;
  final ConflictPolicy conflictPolicy;
  final TransferStatus status;
  final int filesScanned;
  final int filesTransferred;
  final int bytesTransferred;
  final int totalBytes;
  final List<String> errors;

  SyncJob copyWith({
    String? id,
    String? name,
    EndpointRef? source,
    EndpointRef? target,
    SyncMode? mode,
    ConflictPolicy? conflictPolicy,
    TransferStatus? status,
    int? filesScanned,
    int? filesTransferred,
    int? bytesTransferred,
    int? totalBytes,
    List<String>? errors,
  }) {
    return SyncJob(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      target: target ?? this.target,
      mode: mode ?? this.mode,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
      status: status ?? this.status,
      filesScanned: filesScanned ?? this.filesScanned,
      filesTransferred: filesTransferred ?? this.filesTransferred,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      errors: errors ?? this.errors,
    );
  }

  @override
  String toString() => 'SyncJob($name, $status, $filesTransferred/$filesScanned files)';
}

/// Sync operation summary
class SyncSummary {
  SyncSummary({
    required this.jobId,
    required this.filesScanned,
    required this.filesAdded,
    required this.filesUpdated,
    required this.filesDeleted,
    required this.filesSkipped,
    required this.bytesTransferred,
    required this.errors,
    required this.startTime,
    required this.endTime,
  });

  final String jobId;
  final int filesScanned;
  final int filesAdded;
  final int filesUpdated;
  final int filesDeleted;
  final int filesSkipped;
  final int bytesTransferred;
  final List<String> errors;
  final DateTime startTime;
  final DateTime endTime;

  Duration get duration => endTime.difference(startTime);

  @override
  String toString() =>
      'SyncSummary($filesScanned scanned, $filesAdded added, $filesUpdated updated, $filesDeleted deleted, ${errors.length} errors, ${duration.inSeconds}s)';
}

/// Service for syncing/mirroring between S3 locations
class SyncService with ChangeNotifier {
  SyncService({required this.objectService, required this.client, required this.queue});

  final ObjectService objectService;
  final S3Client client;
  final TransferQueue queue;
  final _uuid = const Uuid();
  final List<SyncJob> _jobs = [];

  List<SyncJob> get jobs => List.unmodifiable(_jobs);

  /// Start a sync job
  Future<SyncJob> startSync({
    required String name,
    required EndpointRef source,
    required EndpointRef target,
    required SyncMode mode,
    required ConflictPolicy conflictPolicy,
  }) async {
    final job = SyncJob(
      id: _uuid.v4(),
      name: name,
      source: source,
      target: target,
      mode: mode,
      conflictPolicy: conflictPolicy,
      status: TransferStatus.running,
    );

    _jobs.add(job);
    notifyListeners();

    // Run sync in background
    _executeSync(job);

    return job;
  }

  Future<void> _executeSync(SyncJob job) async {
    try {
      final startTime = DateTime.now();
      int filesScanned = 0;
      int filesAdded = 0;
      int filesUpdated = 0;
      int filesDeleted = 0;
      int filesSkipped = 0;
      int bytesTransferred = 0;
      final errors = <String>[];

      // Get source and target objects
      final sourceObjects = await objectService.listObjects(
        job.source.bucket!,
        prefix: job.source.key,
      );
      filesScanned = sourceObjects.length;

      final targetObjects = await objectService.listObjects(
        job.target.bucket!,
        prefix: job.target.key,
      );

      // Create map of target keys for quick lookup
      final targetKeys = <String, ObjectNode>{};
      for (final obj in targetObjects) {
        targetKeys[obj.key] = obj;
      }

      // Process each source object
      for (final sourceObj in sourceObjects) {
        final relativeKey = job.source.key != null ? sourceObj.key.substring(job.source.key!.length) : sourceObj.key;
        final targetKey = job.target.key != null ? '${job.target.key}$relativeKey' : relativeKey;

        final targetObj = targetKeys.remove(targetKey);

        if (targetObj == null) {
          // File doesn't exist in target, add it
          try {
            await objectService.copy(
              job.source.bucket!,
              sourceObj.key,
              job.target.bucket!,
              targetKey,
            );
            filesAdded++;
            bytesTransferred += sourceObj.sizeBytes;
          } catch (e) {
            errors.add('加入 $targetKey 失敗: $e');
          }
        } else {
          // File exists in target
          if (job.conflictPolicy == ConflictPolicy.overwrite) {
            // Check if source is newer or different size
            if (sourceObj.lastModified.isAfter(targetObj.lastModified) || sourceObj.sizeBytes != targetObj.sizeBytes) {
              try {
                await objectService.copy(
                  job.source.bucket!,
                  sourceObj.key,
                  job.target.bucket!,
                  targetKey,
                );
                filesUpdated++;
                bytesTransferred += sourceObj.sizeBytes;
              } catch (e) {
                errors.add('更新 $targetKey 失敗: $e');
              }
            } else {
              filesSkipped++;
            }
          } else {
            filesSkipped++;
          }
        }
      }

      // If mirror mode, delete files that exist in target but not in source
      if (job.mode == SyncMode.mirror && targetKeys.isNotEmpty) {
        try {
          await objectService.deleteObjects(job.target.bucket!, targetKeys.keys.toList());
          filesDeleted = targetKeys.length;
        } catch (e) {
          errors.add('刪除多餘檔案失敗: $e');
        }
      }

      // Update job status
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = job.copyWith(
          status: TransferStatus.completed,
          filesScanned: filesScanned,
          filesTransferred: filesAdded + filesUpdated,
          bytesTransferred: bytesTransferred,
          errors: errors,
        );
        notifyListeners();
      }
    } catch (e) {
      final index = _jobs.indexWhere((j) => j.id == job.id);
      if (index != -1) {
        _jobs[index] = job.copyWith(
          status: TransferStatus.failed,
          errors: [...job.errors, '同步失敗: $e'],
        );
        notifyListeners();
      }
    }
  }

  /// Cancel a sync job
  void cancelSync(String jobId) {
    final index = _jobs.indexWhere((j) => j.id == jobId);
    if (index != -1 && _jobs[index].status == TransferStatus.running) {
      _jobs[index] = _jobs[index].copyWith(status: TransferStatus.canceled);
      notifyListeners();
    }
  }

  /// Remove completed/failed/canceled job from list
  void removeJob(String jobId) {
    _jobs.removeWhere((j) => j.id == jobId);
    notifyListeners();
  }
}
