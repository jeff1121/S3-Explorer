import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app/models/entities.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:aws_client/s3_2006_03_01.dart' as aws;

/// Multipart uploader for large files with parallel part uploads.
///
/// Automatically triggered for files > 5MB by ObjectService.
///
/// Performance Parameters:
/// - [maxConcurrent]: Maximum number of parts uploaded in parallel (default: 3)
///   - Recommended range: 1-10
///   - Higher values = faster upload for large files with good bandwidth
///   - Lower values = more stable for unreliable connections
///
/// - [partSizeMb]: Size of each part in MB (minimum: 5MB, default: 8MB)
///   - Smaller parts = more parallelism, more S3 requests
///   - Larger parts = fewer requests, less overhead
///   - Recommended: 8-16MB for most use cases
///
/// S3 Limits:
/// - Minimum part size: 5MB (except last part)
/// - Maximum parts: 10,000
/// - Maximum object size: 5TB
///
/// Usage:
/// ```dart
/// final uploader = MultipartUploader(client: s3Client, maxConcurrent: 5);
/// await uploader.upload(
///   bucket: 'my-bucket',
///   key: 'large-file.dat',
///   filePath: '/path/to/file',
///   partSizeMb: 8,
///   control: transferController,
/// );
/// ```
class MultipartUploader {
  MultipartUploader({required this.client, this.maxConcurrent = 3});

  final S3Client client;

  /// Maximum number of parts that can be uploaded concurrently.
  /// Default: 3. Recommended range: 1-10.
  final int maxConcurrent;

  Future<void> upload({
    required String bucket,
    required String key,
    required String filePath,
    required int partSizeMb,
    required TransferController control,
  }) async {
    final file = File(filePath);
    final totalBytes = await file.length();
    if (totalBytes == 0) {
      throw StateError('檔案為空');
    }
    final partSize = max(partSizeMb, 5) * 1024 * 1024;
    final partCount = (totalBytes / partSize).ceil();
    final opened = await file.open();

    final createResp =
        await client.raw.createMultipartUpload(bucket: bucket, key: key);
    final uploadId = createResp.uploadId;
    if (uploadId == null) {
      await opened.close();
      throw StateError('無法建立 multipart upload');
    }

    final completedParts = <aws.CompletedPart>[];
    int partsCompleted = 0;

    Future<void> uploadPart(int partNumber) async {
      control.throwIfCanceled();
      await control.waitIfPaused();
      final start = (partNumber - 1) * partSize;
      final remaining = totalBytes - start;
      final size = remaining < partSize ? remaining : partSize;
      await opened.setPosition(start);
      final bytes = await opened.read(size);
      final resp = await client.raw.uploadPart(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        partNumber: partNumber,
        body: bytes,
      );
      completedParts
          .add(aws.CompletedPart(eTag: resp.eTag, partNumber: partNumber));
      partsCompleted += 1;
      control.reportProgress(TransferProgress(
        bytesTransferred: min(totalBytes, partNumber * partSize),
        totalBytes: totalBytes,
        partsCompleted: partsCompleted,
        partsTotal: partCount,
      ));
    }

    try {
      final workers = <Future<void>>[];
      int nextPart = 1;

      Future<void> spawn() async {
        while (true) {
          int? part;
          if (nextPart <= partCount) {
            part = nextPart;
            nextPart += 1;
          }
          if (part == null) break;
          await uploadPart(part);
        }
      }

      final parallel = min(maxConcurrent, partCount);
      for (var i = 0; i < parallel; i++) {
        workers.add(spawn());
      }
      await Future.wait(workers);

      completedParts
          .sort((a, b) => (a.partNumber ?? 0).compareTo(b.partNumber ?? 0));
      await client.raw.completeMultipartUpload(
        bucket: bucket,
        key: key,
        uploadId: uploadId,
        multipartUpload: aws.CompletedMultipartUpload(parts: completedParts),
      );
    } catch (e) {
      if (!control.isCanceled) {
        await client.raw
            .abortMultipartUpload(bucket: bucket, key: key, uploadId: uploadId);
      }
      rethrow;
    } finally {
      await opened.close();
    }
  }
}
