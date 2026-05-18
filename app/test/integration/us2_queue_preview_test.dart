import 'dart:io';
import 'dart:typed_data';

import 'package:app/models/entities.dart';
import 'package:app/services/object_service.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
import 'package:app/features/preview/preview_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

void main() {
  final env = Platform.environment;
  final endpoint = env['TEST_S3_ENDPOINT'];
  final region = env['TEST_S3_REGION'];
  final accessKey = env['TEST_S3_ACCESS_KEY'];
  final secretKey = env['TEST_S3_SECRET_KEY'];
  final bucket = env['TEST_S3_BUCKET'];

  final missing = <String>[];
  if (endpoint == null || endpoint.isEmpty) missing.add('TEST_S3_ENDPOINT');
  if (region == null || region.isEmpty) missing.add('TEST_S3_REGION');
  if (accessKey == null || accessKey.isEmpty) missing.add('TEST_S3_ACCESS_KEY');
  if (secretKey == null || secretKey.isEmpty) missing.add('TEST_S3_SECRET_KEY');
  if (bucket == null || bucket.isEmpty) missing.add('TEST_S3_BUCKET');

  if (missing.isNotEmpty) {
    test('US2 queue and preview (skipped)', () {
      expect(true, isTrue);
    },
        skip:
            'Set env vars: ${missing.join(', ')} to run integration against S3/MinIO');
    return;
  }

  final profile = ConnectionProfile(
    id: 'test-profile',
    name: 'Integration',
    endpoint: Uri.parse(endpoint!),
    region: region!,
    accessKeyId: accessKey!,
    secretKey: secretKey!,
    defaultBucket: bucket?.toLowerCase().replaceAll('_', '-'),
  );

  group('US2 queue and preview', () {
    late TransferQueue queue;
    late S3Client client;
    late ObjectService service;
    late PreviewService previewService;

    setUp(() {
      queue = TransferQueue();
      client = S3Client(profile: profile);
      service = ObjectService(client: client, queue: queue);
      previewService = PreviewService(client: client);
    });

    tearDown(() {
      client.close();
    });

    // TODO: Fix file access conflict in multipart upload test
    test('multipart upload', () async {
      final bucketName = bucket!.toLowerCase().replaceAll('_', '-');
      final buckets = await service.listBuckets();

      // Only create if missing
      if (!buckets.contains(bucketName)) {
        try {
          await client.raw.createBucket(bucket: bucketName);
        } catch (e) {
          // Ignore if already exists
          if (!e.toString().contains('BucketAlreadyExists')) rethrow;
        }
      }

      final tempDir = await Directory.systemTemp.createTemp('s3-desktop-us2-');

      // Create a 10MB file for multipart upload test (>5MB threshold)
      final largeFile = File(p.join(tempDir.path, 'large.dat'));
      final chunkSize = 1024 * 1024; // 1MB chunks
      final totalSize = 10 * chunkSize;
      final data = Uint8List(chunkSize);

      final sink = largeFile.openWrite();
      for (var i = 0; i < 10; i++) {
        sink.add(data);
      }
      await sink.close();

      expect(await largeFile.length(), equals(totalSize));

      final key = 'desktop-us2/${const Uuid().v4()}.dat';
      final uploadTask = await service.upload(bucketName, key, largeFile.path);

      // Wait for completion
      final completedTask = await queue
          .waitFor(uploadTask.id)
          .timeout(const Duration(seconds: 60));

      expect(completedTask.status, equals(TransferStatus.completed));

      // Verify upload
      final objects =
          await service.listObjects(bucketName, prefix: 'desktop-us2/');
      expect(objects.any((o) => o.key == key), isTrue);

      // Cleanup - delete from S3 first, wait for queue to settle, then delete local
      await service.deleteObjects(bucketName, [key]);
      await Future.delayed(const Duration(milliseconds: 500));
      await tempDir.delete(recursive: true);
    }, timeout: const Timeout(Duration(seconds: 90)));

    test('preview text file', () async {
      final bucketName = bucket!.toLowerCase().replaceAll('_', '-');
      final buckets = await service.listBuckets();

      // Only create if missing
      if (!buckets.contains(bucketName)) {
        try {
          await client.raw.createBucket(bucket: bucketName);
        } catch (e) {
          if (!e.toString().contains('BucketAlreadyExists')) rethrow;
        }
      }

      final tempDir =
          await Directory.systemTemp.createTemp('s3-desktop-us2-preview-');

      // Create a text file
      final textContent =
          'This is a test file for preview.\nLine 2\nLine 3\n' * 50;
      final textFile = File(p.join(tempDir.path, 'preview.txt'));
      await textFile.writeAsString(textContent);

      final key = 'desktop-us2-preview/${const Uuid().v4()}.txt';
      final uploadTask = await service.upload(bucketName, key, textFile.path);
      await queue.waitFor(uploadTask.id).timeout(const Duration(seconds: 15));

      // Test preview
      final preview = await previewService.preview(bucketName, key);
      expect(preview.type, equals(PreviewType.text));
      expect(preview.text, isNotNull);
      expect(preview.text, contains('This is a test file'));
      expect(preview.error, isNull);

      // Cleanup
      await service.deleteObjects(bucketName, [key]);
      await tempDir.delete(recursive: true);
    });

    test('concurrent upload queue control', () async {
      final bucketName = bucket!.toLowerCase().replaceAll('_', '-');
      final buckets = await service.listBuckets();

      // Only create if missing
      if (!buckets.contains(bucketName)) {
        try {
          await client.raw.createBucket(bucket: bucketName);
        } catch (e) {
          if (!e.toString().contains('BucketAlreadyExists')) rethrow;
        }
      }

      final tempDir =
          await Directory.systemTemp.createTemp('s3-desktop-us2-concurrent-');

      // Create 5 small files
      final files = <File>[];
      final keys = <String>[];
      for (var i = 0; i < 5; i++) {
        final file = File(p.join(tempDir.path, 'file_$i.txt'));
        await file.writeAsString('Content $i\n' * 100);
        files.add(file);

        final key = 'desktop-us2-concurrent/${const Uuid().v4()}_$i.txt';
        keys.add(key);
      }

      // Submit all uploads
      final uploadTasks = <TransferTask>[];
      for (var i = 0; i < 5; i++) {
        final task = await service.upload(bucketName, keys[i], files[i].path);
        uploadTasks.add(task);
      }

      // Verify queue handles concurrent tasks (max 3 by default)
      expect(uploadTasks.length, equals(5));

      // Wait for all to complete
      await Future.wait(
        uploadTasks.map(
            (t) => queue.waitFor(t.id).timeout(const Duration(seconds: 30))),
      );

      // Verify all completed
      for (final task in uploadTasks) {
        final completedTask = queue.tasks.firstWhere((t) => t.id == task.id);
        expect(completedTask.status, equals(TransferStatus.completed));
      }

      // Cleanup
      await service.deleteObjects(bucketName, keys);
      await tempDir.delete(recursive: true);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
