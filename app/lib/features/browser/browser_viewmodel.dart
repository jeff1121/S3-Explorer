import 'dart:io';
import 'package:app/models/entities.dart';
import 'package:app/services/object_service.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:app/features/browser/drag_drop_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:aws_client/s3_2006_03_01.dart' as aws;

class BrowserViewModel extends ChangeNotifier {
  BrowserViewModel({required this.profile, required this.objectService, required this.queue});

  final ConnectionProfile profile;
  final ObjectService objectService;
  final TransferQueue queue;

  List<String> buckets = [];
  List<ObjectNode> objects = [];
  Set<String> selectedKeys = {};
  String? currentBucket;
  String prefix = '';
  bool loading = false;
  bool working = false;
  String? error;

  List<TransferTask> get tasks => queue.tasks;

  Future<void> init() async {
    loading = true;
    notifyListeners();
    try {
      buckets = await objectService.listBuckets();
      currentBucket = profile.defaultBucket ?? (buckets.isNotEmpty ? buckets.first : null);
      prefix = _normalizePrefix(profile.defaultPrefix ?? '');
      if (currentBucket != null) {
        await refresh();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (currentBucket == null) return;
    loading = true;
    notifyListeners();
    try {
      objects = await objectService.listObjects(currentBucket!, prefix: prefix.isEmpty ? null : prefix);
      error = null;
    } catch (e) {
      // Handle known errors with friendly messages
      if (e.toString().contains('ChecksumAlgorithm') || e.toString().contains('CRC64NVME')) {
        error = 'AWS S3 returned unsupported checksum algorithm. Please upgrade aws_client package or use different S3 endpoint.';
      } else {
        error = e.toString();
      }
    }
    loading = false;
    notifyListeners();
  }

  void setBucket(String bucket) {
    currentBucket = bucket;
    prefix = '';
    selectedKeys.clear();
    refresh();
  }

  void setPrefix(String value) {
    prefix = _normalizePrefix(value);
    refresh();
  }

  void toggleSelection(ObjectNode node) {
    if (selectedKeys.contains(node.key)) {
      selectedKeys.remove(node.key);
    } else {
      selectedKeys.add(node.key);
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedKeys.clear();
    notifyListeners();
  }

  List<ObjectNode> get selectedNodes => objects.where((o) => selectedKeys.contains(o.key)).toList();

  Future<void> uploadFiles(List<String> paths) async {
    if (currentBucket == null || paths.isEmpty) return;
    try {
      for (final path in paths) {
        // Skip directories - only upload files
        final entity = FileSystemEntity.typeSync(path);
        if (entity != FileSystemEntityType.file) {
          debugPrint('[BrowserViewModel] Skipping non-file: $path');
          continue;
        }
        
        final key = _toKey(p.basename(path));
        queue.enqueue(
          type: TransferType.upload,
          source: EndpointRef(localPath: path),
          target: EndpointRef(
            profileId: profile.id,
            bucket: currentBucket!,
            key: key,
          ),
          executor: (task, controller) async {
            final bytesUploaded = await objectService.client.uploadObject(
              task.target.bucket!,
              task.target.key!,
              localPath: task.source.localPath!,
            );
            controller.reportProgress(
              task.progress.copyWith(
                bytesTransferred: bytesUploaded,
                totalBytes: bytesUploaded,
              ),
            );
          },
        );
      }
      // Refresh after all uploads are queued
      await Future.delayed(const Duration(milliseconds: 100));
      await refresh();
    } catch (e) {
      debugPrint('[BrowserViewModel] Upload error: $e');
      error = 'Upload failed: $e';
      notifyListeners();
    }
  }

  Future<void> uploadFilesWithStructure(List<FileUploadInfo> files) async {
    if (currentBucket == null || files.isEmpty) return;
    try {
      for (final file in files) {
        final key = _toKey(file.relativePath);
        queue.enqueue(
          type: TransferType.upload,
          source: EndpointRef(localPath: file.localPath),
          target: EndpointRef(
            profileId: profile.id,
            bucket: currentBucket!,
            key: key,
          ),
          executor: (task, controller) async {
            final bytesUploaded = await objectService.client.uploadObject(
              task.target.bucket!,
              task.target.key!,
              localPath: task.source.localPath!,
            );
            controller.reportProgress(
              task.progress.copyWith(
                bytesTransferred: bytesUploaded,
                totalBytes: bytesUploaded,
              ),
            );
          },
        );
      }
      // Refresh after all uploads are queued
      await Future.delayed(const Duration(milliseconds: 100));
      await refresh();
    } catch (e) {
      debugPrint('[BrowserViewModel] Upload with structure error: $e');
      error = 'Upload failed: $e';
      notifyListeners();
    }
  }

  Future<void> deleteSelection() async {
    if (currentBucket == null || selectedKeys.isEmpty) return;
    working = true;
    notifyListeners();
    try {
      await objectService.deleteObjects(currentBucket!, selectedKeys.toList());
      selectedKeys.clear();
    } finally {
      working = false;
      await refresh();
    }
  }

  Future<void> downloadSelection(String directory) async {
    if (currentBucket == null || selectedKeys.isEmpty) return;
    try {
      for (final node in selectedNodes) {
        if (node.isFolder) continue; // Skip folders
        final localPath = p.join(directory, p.basename(node.key));
        queue.enqueue(
          type: TransferType.download,
          source: EndpointRef(
            profileId: profile.id,
            bucket: currentBucket!,
            key: node.key,
          ),
          target: EndpointRef(localPath: localPath),
          executor: (task, controller) async {
            final bytesDownloaded = await objectService.client.downloadObject(
              task.source.bucket!,
              task.source.key!,
              localPath: task.target.localPath!,
            );
            controller.reportProgress(
              task.progress.copyWith(
                bytesTransferred: bytesDownloaded,
                totalBytes: bytesDownloaded,
              ),
            );
          },
        );
      }
      // Refresh after all downloads are queued
      await Future.delayed(const Duration(milliseconds: 100));
      await refresh();
    } catch (e) {
      debugPrint('[BrowserViewModel] Download error: $e');
      error = 'Download failed: $e';
      notifyListeners();
    }
  }

  Future<void> copySelection(String targetBucket, String targetPrefix, {bool move = false}) async {
    if (currentBucket == null || selectedKeys.isEmpty) return;
    working = true;
    notifyListeners();
    final normalizedPrefix = _normalizePrefix(targetPrefix);
    try {
      for (final node in selectedNodes) {
        final destKey = normalizedPrefix.isEmpty ? node.key : '$normalizedPrefix${node.key}';
        if (move) {
          await objectService.move(currentBucket!, node.key, targetBucket, destKey);
        } else {
          await objectService.copy(currentBucket!, node.key, targetBucket, destKey);
        }
      }
    } finally {
      working = false;
      await refresh();
    }
  }

  Future<List<String>> makeSelectedPublic() async {
    if (currentBucket == null || selectedKeys.isEmpty) return [];
    working = true;
    error = null;
    notifyListeners();
    
    final urls = <String>[];
    try {
      for (final node in selectedNodes) {
        if (node.isFolder) continue; // Skip folders
        
        // Set ACL to public-read
        await objectService.client.setObjectAcl(
          currentBucket!,
          node.key,
          aws.ObjectCannedACL.publicRead,
        );
        
        // Generate public URL
        final url = objectService.client.getPublicUrl(currentBucket!, node.key);
        urls.add(url);
      }
    } catch (e) {
      debugPrint('[BrowserViewModel] Make public error: $e');
      error = 'Failed to make objects public: $e';
    } finally {
      working = false;
      notifyListeners();
    }
    
    return urls;
  }

  String _toKey(String fileName) {
    if (prefix.isEmpty) return fileName;
    return '$prefix$fileName';
  }

  String _normalizePrefix(String value) {
    if (value.isEmpty) return '';
    return value.endsWith('/') ? value : '$value/';
  }
}
