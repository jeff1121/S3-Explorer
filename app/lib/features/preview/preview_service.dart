import 'dart:convert';
import 'dart:typed_data';

import 'package:app/services/s3_client.dart';

enum PreviewType { text, image, unsupported }

class PreviewResult {
  PreviewResult({required this.type, required this.contentType, required this.contentLength, this.text, this.bytes, this.error});

  final PreviewType type;
  final String contentType;
  final int contentLength;
  final String? text;
  final Uint8List? bytes;
  final String? error;
}

class PreviewService {
  PreviewService({required this.client, this.maxBytes = 131072});

  final S3Client client;
  final int maxBytes;

  Future<PreviewResult> preview(String bucket, String key) async {
    try {
      final resp = await client.raw.getObject(
        bucket: bucket,
        key: key,
        range: 'bytes=0-${maxBytes - 1}',
      );
      final data = resp.body ?? Uint8List(0);
      final contentType = resp.contentType ?? 'application/octet-stream';
      final length = resp.contentLength ?? data.length;

      if (contentType.startsWith('text/') || contentType.contains('json')) {
        final text = utf8.decode(data, allowMalformed: true);
        return PreviewResult(type: PreviewType.text, contentType: contentType, contentLength: length, text: text);
      }
      if (contentType.startsWith('image/')) {
        return PreviewResult(type: PreviewType.image, contentType: contentType, contentLength: length, bytes: data);
      }
      return PreviewResult(type: PreviewType.unsupported, contentType: contentType, contentLength: length, error: '不支援的格式');
    } catch (e) {
      return PreviewResult(type: PreviewType.unsupported, contentType: 'unknown', contentLength: 0, error: e.toString());
    }
  }
}
