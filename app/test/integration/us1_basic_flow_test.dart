import 'dart:io';

import 'package:app/models/entities.dart';
import 'package:app/services/object_service.dart';
import 'package:app/services/s3_client.dart';
import 'package:app/services/transfer_queue.dart';
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
    test('US1 basic flow (skipped)', () {
      expect(true, isTrue);
    }, skip: 'Set env vars: ${missing.join(', ')} to run integration against S3/MinIO');
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

  group('US1 basic flow', () {
    late TransferQueue queue;
    late S3Client client;
    late ObjectService service;

    setUp(() {
      queue = TransferQueue();
      client = S3Client(profile: profile);
      service = ObjectService(client: client, queue: queue);
    });

    tearDown(() {
      client.close();
    });

    test('list -> upload -> download -> delete', () async {
      final bucketName = bucket!.toLowerCase().replaceAll('_', '-');
      final buckets = await service.listBuckets();
      print('Available buckets: $buckets');
      
      // Create bucket if it doesn't exist
      if (!buckets.contains(bucketName)) {
        print('Bucket $bucketName not found, creating...');
        await client.raw.createBucket(bucket: bucketName);
        print('Bucket $bucketName created');
      } else {
        print('Bucket $bucketName already exists');
      }

      final tempDir = await Directory.systemTemp.createTemp('s3-desktop-us1-');
      final payload = 'hello-world-${const Uuid().v4()}';
      final uploadFile = File(p.join(tempDir.path, 'upload.txt'));
      await uploadFile.writeAsString(payload);

      final key = 'desktop-us1/${const Uuid().v4()}.txt';
      final uploadTask = await service.upload(bucketName, key, uploadFile.path);
      await queue.waitFor(uploadTask.id).timeout(const Duration(seconds: 15));

      final downloadPath = p.join(tempDir.path, 'download.txt');
      final downloadTask = await service.download(bucketName, key, downloadPath);
      await queue.waitFor(downloadTask.id).timeout(const Duration(seconds: 15));

      final downloaded = await File(downloadPath).readAsString();
      expect(downloaded, equals(payload));

      await service.deleteObjects(bucketName, [key]);
      await tempDir.delete(recursive: true);
    });
  });
}
