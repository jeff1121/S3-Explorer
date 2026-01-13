import 'package:app/services/s3_client.dart';
import 'package:aws_client/s3_2006_03_01.dart' as aws;

/// Presigned URL action types
enum PresignAction {
  get,
  put,
}

/// Presigned URL request
class PresignRequest {
  PresignRequest({
    required this.bucket,
    required this.key,
    required this.action,
    required this.expiresInSeconds,
  });

  final String bucket;
  final String key;
  final PresignAction action;
  final int expiresInSeconds;
}

/// Presigned URL result
class PresignResult {
  PresignResult({
    required this.url,
    required this.expiresAt,
  });

  final String url;
  final DateTime expiresAt;

  @override
  String toString() => 'PresignResult($url, expires: $expiresAt)';
}

/// Service for generating presigned URLs
class PresignService {
  PresignService({required this.client});

  final S3Client client;

  /// Generate presigned URL
  /// 
  /// Note: aws_client does not provide built-in presigned URL generation.
  /// This is a simplified implementation that returns the S3 object URL.
  /// For production use, consider implementing proper SigV4 presigning.
  Future<PresignResult> generatePresignedUrl(PresignRequest request) async {
    if (request.expiresInSeconds < 60 || request.expiresInSeconds > 604800) {
      throw ArgumentError('expiresInSeconds must be between 60 and 604800 (7 days)');
    }

    final endpoint = client.profile.endpoint.toString().replaceAll(RegExp(r'/$'), '');
    final url = '$endpoint/${request.bucket}/${request.key}';

    // TODO: Implement actual SigV4 presigning
    // For now, return a simple URL with expiration timestamp
    // In production, this should generate proper AWS SigV4 signed URLs
    
    final expiresAt = DateTime.now().add(Duration(seconds: request.expiresInSeconds));

    return PresignResult(
      url: url,
      expiresAt: expiresAt,
    );
  }

  /// Generate presigned URL for GET (download)
  Future<PresignResult> generateGetUrl({
    required String bucket,
    required String key,
    int expiresInSeconds = 3600,
  }) {
    return generatePresignedUrl(
      PresignRequest(
        bucket: bucket,
        key: key,
        action: PresignAction.get,
        expiresInSeconds: expiresInSeconds,
      ),
    );
  }

  /// Generate presigned URL for PUT (upload)
  Future<PresignResult> generatePutUrl({
    required String bucket,
    required String key,
    int expiresInSeconds = 3600,
  }) {
    return generatePresignedUrl(
      PresignRequest(
        bucket: bucket,
        key: key,
        action: PresignAction.put,
        expiresInSeconds: expiresInSeconds,
      ),
    );
  }
}
