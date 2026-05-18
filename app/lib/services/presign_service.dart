import 'package:app/services/s3_client.dart';
import 'package:app/services/sigv4_presigner.dart';

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
  /// Uses AWS Signature Version 4 query signing for S3-compatible endpoints.
  Future<PresignResult> generatePresignedUrl(PresignRequest request) async {
    if (request.expiresInSeconds < 60 || request.expiresInSeconds > 604800) {
      throw ArgumentError(
          'expiresInSeconds must be between 60 and 604800 (7 days)');
    }

    final expiresAt =
        DateTime.now().add(Duration(seconds: request.expiresInSeconds));
    final presigner = SigV4Presigner(
      endpoint: client.profile.endpoint,
      region: client.profile.region,
      accessKeyId: client.profile.accessKeyId,
      secretKey: client.profile.secretKey,
    );
    final url = presigner.presign(
      method: request.action == PresignAction.get ? 'GET' : 'PUT',
      bucket: request.bucket,
      key: request.key,
      expiresIn: Duration(seconds: request.expiresInSeconds),
    );

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
