import 'dart:io';
import 'package:app/models/entities.dart';
import 'package:app/services/sigv4_presigner.dart';
import 'package:aws_client/s3_2006_03_01.dart' as aws;
import 'package:flutter/foundation.dart';

class S3Client {
  S3Client({required this.profile, aws.S3? client})
      : _s3 = client ??
            aws.S3(
                region: profile.region,
                endpointUrl: profile.endpoint.toString(),
                credentials: aws.AwsClientCredentials(
                    accessKey: profile.accessKeyId,
                    secretKey: profile.secretKey));

  final ConnectionProfile profile;
  final aws.S3 _s3;

  aws.S3 get raw => _s3;

  Future<List<String>> listBuckets() async {
    final resp = await _s3.listBuckets();
    final buckets = resp.buckets ?? [];
    return buckets.where((b) => b.name != null).map((b) => b.name!).toList();
  }

  Future<List<ObjectNode>> listObjects(String bucket, {String? prefix}) async {
    final effectivePrefix = (prefix == null || prefix.isEmpty) ? null : prefix;
    try {
      final resp = await _s3.listObjectsV2(
          bucket: bucket, prefix: effectivePrefix, delimiter: '/');
      final nodes = <ObjectNode>[];
      final now = DateTime.now();

      final folders = resp.commonPrefixes ?? [];
      for (final folder in folders) {
        final key = folder.prefix ?? '';
        nodes.add(
          ObjectNode(
            bucket: bucket,
            key: key,
            isFolder: true,
            sizeBytes: 0,
            lastModified: now,
          ),
        );
      }

      final contents = resp.contents ?? [];
      for (final obj in contents) {
        try {
          final key = obj.key ?? '';
          if (key.isEmpty || key.endsWith('/')) continue; // skip folder markers
          nodes.add(
            ObjectNode(
              bucket: bucket,
              key: key,
              isFolder: false,
              sizeBytes: obj.size?.toInt() ?? 0,
              lastModified: obj.lastModified ?? now,
              etag: obj.eTag,
              contentType: null,
            ),
          );
        } catch (e) {
          // Skip objects that cause parsing errors (e.g., unknown checksum algorithms)
          debugPrint('Warning: Failed to parse object ${obj.key}: $e');
        }
      }

      nodes.sort((a, b) => a.key.compareTo(b.key));
      return nodes;
    } catch (e) {
      // If the error is about unknown checksum algorithm, try to handle it
      if (e.toString().contains('ChecksumAlgorithm') ||
          e.toString().contains('CRC64NVME')) {
        debugPrint(
            'Warning: Encountered unknown checksum algorithm, retrying without parsing checksums');
        // Return empty list for now, or implement a workaround
        return [];
      }
      rethrow;
    }
  }

  Future<int> uploadObject(String bucket, String key,
      {required String localPath}) async {
    final file = File(localPath);
    final bytes = await file.readAsBytes();
    await _s3.putObject(
        bucket: bucket,
        key: _cleanKey(key),
        body: bytes,
        contentLength: bytes.length);
    return bytes.length;
  }

  Future<int> downloadObject(String bucket, String key,
      {required String localPath}) async {
    final resp = await _s3.getObject(bucket: bucket, key: _cleanKey(key));
    final data = resp.body ?? Uint8List(0);
    final file = File(localPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(data);
    return data.length;
  }

  Future<void> deleteObject(String bucket, String key) async {
    await _s3.deleteObject(bucket: bucket, key: _cleanKey(key));
  }

  Future<void> deleteObjects(String bucket, List<String> keys) async {
    for (final key in keys) {
      await deleteObject(bucket, key);
    }
  }

  Future<void> copyObject(
      {required String sourceBucket,
      required String sourceKey,
      required String destinationBucket,
      required String destinationKey,
      bool overwrite = true}) async {
    final source = '${_cleanKey(sourceBucket)}/${_cleanKey(sourceKey)}';
    await _s3.copyObject(
      bucket: destinationBucket,
      key: _cleanKey(destinationKey),
      copySource: source,
      metadataDirective: overwrite ? aws.MetadataDirective.replace : null,
    );
  }

  Future<void> moveObject(
      {required String sourceBucket,
      required String sourceKey,
      required String destinationBucket,
      required String destinationKey,
      bool overwrite = true}) async {
    await copyObject(
      sourceBucket: sourceBucket,
      sourceKey: sourceKey,
      destinationBucket: destinationBucket,
      destinationKey: destinationKey,
      overwrite: overwrite,
    );
    await deleteObject(sourceBucket, sourceKey);
  }

  Future<String> generatePresignedUrl(String bucket, String key,
      {required PresignAction action, required Duration expiresIn}) async {
    final presigner = SigV4Presigner(
      endpoint: profile.endpoint,
      region: profile.region,
      accessKeyId: profile.accessKeyId,
      secretKey: profile.secretKey,
    );
    return presigner.presign(
      method: action == PresignAction.get ? 'GET' : 'PUT',
      bucket: bucket,
      key: _cleanKey(key),
      expiresIn: expiresIn,
    );
  }

  Future<void> setObjectAcl(
      String bucket, String key, aws.ObjectCannedACL acl) async {
    await _s3.putObjectAcl(
      bucket: bucket,
      key: _cleanKey(key),
      acl: acl,
    );
  }

  String getPublicUrl(String bucket, String key) {
    final sanitized = _cleanKey(key);
    return '${profile.endpoint}/$bucket/$sanitized';
  }

  void close() {
    _s3.close();
  }

  String _cleanKey(String key) {
    return key.replaceFirst(RegExp(r'^/+'), '');
  }
}
