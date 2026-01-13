import 'dart:io';

import 'package:app/models/entities.dart';
import 'package:app/services/multipart_uploader.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:path/path.dart' as p;

class ObjectService {
  ObjectService({required this.client, required this.queue});

  final S3Client client;
  final TransferQueue queue;

  Future<List<String>> listBuckets() => client.listBuckets();

  Future<List<ObjectNode>> listObjects(String bucket, {String? prefix}) => client.listObjects(bucket, prefix: prefix);

  Future<TransferTask> upload(String bucket, String key, String localPath) async {
    final file = File(localPath);
    final totalBytes = await file.length();
    final initial = TransferProgress(totalBytes: totalBytes);
    final useMultipart = totalBytes > 5 * 1024 * 1024;
    final uploader = MultipartUploader(client: client, maxConcurrent: client.profile.concurrency);
    return queue.enqueue(
      type: TransferType.upload,
      source: EndpointRef(localPath: localPath, profileId: client.profile.id),
      target: EndpointRef(bucket: bucket, key: key, profileId: client.profile.id),
      useMultipart: useMultipart,
      partSizeMb: client.profile.partSizeMb,
      concurrency: client.profile.concurrency,
      progress: initial,
      executor: (task, control) async {
        control.throwIfCanceled();
        await control.waitIfPaused();
        control.reportProgress(initial.copyWith(bytesTransferred: 0));
        if (useMultipart) {
          await uploader.upload(
            bucket: bucket,
            key: key,
            filePath: localPath,
            partSizeMb: client.profile.partSizeMb,
            control: control,
          );
          control.reportProgress(initial.copyWith(bytesTransferred: totalBytes));
        } else {
          final transferred = await client.uploadObject(bucket, key, localPath: localPath);
          control.reportProgress(initial.copyWith(bytesTransferred: transferred));
        }
      },
    );
  }

  Future<TransferTask> download(String bucket, String key, String localPath) async {
    final initial = TransferProgress(totalBytes: 0);
    return queue.enqueue(
      type: TransferType.download,
      source: EndpointRef(bucket: bucket, key: key, profileId: client.profile.id),
      target: EndpointRef(localPath: localPath, profileId: client.profile.id),
      useMultipart: false,
      progress: initial,
      executor: (task, control) async {
        control.throwIfCanceled();
        await control.waitIfPaused();
        control.reportProgress(initial.copyWith(bytesTransferred: 0));
        final transferred = await client.downloadObject(bucket, key, localPath: localPath);
        control.reportProgress(initial.copyWith(bytesTransferred: transferred, totalBytes: transferred));
      },
    );
  }

  Future<TransferTask> copy(String sourceBucket, String sourceKey, String destinationBucket, String destinationKey) async {
    final initial = const TransferProgress(totalBytes: 1);
    return queue.enqueue(
      type: TransferType.copy,
      source: EndpointRef(bucket: sourceBucket, key: sourceKey, profileId: client.profile.id),
      target: EndpointRef(bucket: destinationBucket, key: destinationKey, profileId: client.profile.id),
      useMultipart: false,
      progress: initial,
      executor: (task, control) async {
        control.throwIfCanceled();
        await control.waitIfPaused();
        control.reportProgress(initial.copyWith(bytesTransferred: 0));
        await client.copyObject(
          sourceBucket: sourceBucket,
          sourceKey: sourceKey,
          destinationBucket: destinationBucket,
          destinationKey: destinationKey,
        );
        control.reportProgress(initial.copyWith(bytesTransferred: 1));
      },
    );
  }

  Future<TransferTask> move(String sourceBucket, String sourceKey, String destinationBucket, String destinationKey) async {
    final initial = const TransferProgress(totalBytes: 1);
    return queue.enqueue(
      type: TransferType.move,
      source: EndpointRef(bucket: sourceBucket, key: sourceKey, profileId: client.profile.id),
      target: EndpointRef(bucket: destinationBucket, key: destinationKey, profileId: client.profile.id),
      useMultipart: false,
      progress: initial,
      executor: (task, control) async {
        control.throwIfCanceled();
        await control.waitIfPaused();
        control.reportProgress(initial.copyWith(bytesTransferred: 0));
        await client.moveObject(
          sourceBucket: sourceBucket,
          sourceKey: sourceKey,
          destinationBucket: destinationBucket,
          destinationKey: destinationKey,
        );
        control.reportProgress(initial.copyWith(bytesTransferred: 1));
      },
    );
  }

  Future<void> deleteObjects(String bucket, List<String> keys) => client.deleteObjects(bucket, keys);

  Future<String> downloadToDirectory(String bucket, ObjectNode node, String directoryPath) async {
    final destination = p.join(directoryPath, p.basename(node.key));
    await download(bucket, node.key, destination);
    return destination;
  }
}
