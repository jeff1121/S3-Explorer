import 'package:app/services/s3_client.dart';
import 'package:aws_client/s3_2006_03_01.dart' as aws;

/// ACL Permission types
enum AclPermission {
  read,
  write,
  readAcp,
  writeAcp,
  fullControl,
}

extension AclPermissionExt on AclPermission {
  String toS3String() {
    switch (this) {
      case AclPermission.read:
        return 'READ';
      case AclPermission.write:
        return 'WRITE';
      case AclPermission.readAcp:
        return 'READ_ACP';
      case AclPermission.writeAcp:
        return 'WRITE_ACP';
      case AclPermission.fullControl:
        return 'FULL_CONTROL';
    }
  }

  static AclPermission fromS3String(String permission) {
    switch (permission.toUpperCase()) {
      case 'READ':
        return AclPermission.read;
      case 'WRITE':
        return AclPermission.write;
      case 'READ_ACP':
        return AclPermission.readAcp;
      case 'WRITE_ACP':
        return AclPermission.writeAcp;
      case 'FULL_CONTROL':
        return AclPermission.fullControl;
      default:
        throw ArgumentError('Unknown permission: $permission');
    }
  }
}

/// ACL Grantee types
enum GranteeType {
  canonicalUser,
  amazonCustomerByEmail,
  group,
}

/// ACL Grant representation
class Grant {
  Grant({
    required this.grantee,
    required this.granteeType,
    required this.permission,
  });

  final String grantee;
  final GranteeType granteeType;
  final AclPermission permission;

  @override
  String toString() =>
      'Grant($grantee, $granteeType, ${permission.toS3String()})';
}

/// ACL result for a bucket or object
class AclResult {
  AclResult({
    required this.owner,
    required this.grants,
  });

  final String owner;
  final List<Grant> grants;

  @override
  String toString() => 'AclResult(owner: $owner, grants: ${grants.length})';
}

/// CORS configuration for a bucket
class CorsConfiguration {
  CorsConfiguration({
    required this.rules,
  });

  final List<CorsRule> rules;

  Map<String, dynamic> toJson() => {
        'rules': rules.map((r) => r.toJson()).toList(),
      };

  static CorsConfiguration fromJson(Map<String, dynamic> json) {
    return CorsConfiguration(
      rules: (json['rules'] as List<dynamic>?)
              ?.map((r) => CorsRule.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CorsRule {
  CorsRule({
    required this.allowedOrigins,
    required this.allowedMethods,
    this.allowedHeaders,
    this.exposeHeaders,
    this.maxAgeSeconds,
  });

  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String>? allowedHeaders;
  final List<String>? exposeHeaders;
  final int? maxAgeSeconds;

  Map<String, dynamic> toJson() => {
        'allowedOrigins': allowedOrigins,
        'allowedMethods': allowedMethods,
        if (allowedHeaders != null) 'allowedHeaders': allowedHeaders,
        if (exposeHeaders != null) 'exposeHeaders': exposeHeaders,
        if (maxAgeSeconds != null) 'maxAgeSeconds': maxAgeSeconds,
      };

  static CorsRule fromJson(Map<String, dynamic> json) {
    return CorsRule(
      allowedOrigins: (json['allowedOrigins'] as List<dynamic>).cast<String>(),
      allowedMethods: (json['allowedMethods'] as List<dynamic>).cast<String>(),
      allowedHeaders:
          (json['allowedHeaders'] as List<dynamic>?)?.cast<String>(),
      exposeHeaders: (json['exposeHeaders'] as List<dynamic>?)?.cast<String>(),
      maxAgeSeconds: json['maxAgeSeconds'] as int?,
    );
  }
}

/// Service for managing S3 bucket and object permissions
class PermissionsService {
  PermissionsService({required this.client});

  final S3Client client;

  /// Get ACL for a bucket
  Future<AclResult> getBucketAcl(String bucket) async {
    try {
      final result = await client.raw.getBucketAcl(bucket: bucket);
      final owner = result.owner?.id ?? 'unknown';
      final grants = (result.grants ?? []).map((g) {
        final grantee = g.grantee?.id ??
            g.grantee?.uri ??
            g.grantee?.emailAddress ??
            'unknown';
        final permissionValue = g.permission?.value ?? 'READ';
        final permission = AclPermissionExt.fromS3String(permissionValue);
        return Grant(
          grantee: grantee,
          granteeType: _mapGranteeType(g.grantee?.type.value),
          permission: permission,
        );
      }).toList();
      return AclResult(owner: owner, grants: grants);
    } catch (e) {
      throw Exception('無法取得 Bucket ACL: $e');
    }
  }

  /// Get ACL for an object
  Future<AclResult> getObjectAcl(String bucket, String key) async {
    try {
      final result = await client.raw.getObjectAcl(bucket: bucket, key: key);
      final owner = result.owner?.id ?? 'unknown';
      final grants = (result.grants ?? []).map((g) {
        final grantee = g.grantee?.id ??
            g.grantee?.uri ??
            g.grantee?.emailAddress ??
            'unknown';
        final permissionValue = g.permission?.value ?? 'READ';
        final permission = AclPermissionExt.fromS3String(permissionValue);
        return Grant(
          grantee: grantee,
          granteeType: _mapGranteeType(g.grantee?.type.value),
          permission: permission,
        );
      }).toList();
      return AclResult(owner: owner, grants: grants);
    } catch (e) {
      throw Exception('無法取得物件 ACL: $e');
    }
  }

  /// Set ACL for a bucket (canned ACL)
  Future<void> setBucketAcl(String bucket, String cannedAcl) async {
    try {
      await client.raw.putBucketAcl(
        bucket: bucket,
        acl: aws.BucketCannedACL.values.firstWhere(
          (e) => e.value == cannedAcl,
          orElse: () => aws.BucketCannedACL.private,
        ),
      );
    } catch (e) {
      throw Exception('無法設定 Bucket ACL: $e');
    }
  }

  /// Set ACL for an object (canned ACL)
  Future<void> setObjectAcl(String bucket, String key, String cannedAcl) async {
    try {
      await client.raw.putObjectAcl(
        bucket: bucket,
        key: key,
        acl: aws.ObjectCannedACL.values.firstWhere(
          (e) => e.value == cannedAcl,
          orElse: () => aws.ObjectCannedACL.private,
        ),
      );
    } catch (e) {
      throw Exception('無法設定物件 ACL: $e');
    }
  }

  /// Get bucket policy (returns JSON string)
  Future<String?> getBucketPolicy(String bucket) async {
    try {
      final result = await client.raw.getBucketPolicy(bucket: bucket);
      return result.policy;
    } catch (e) {
      if (e.toString().contains('NoSuchBucketPolicy')) {
        return null;
      }
      throw Exception('無法取得 Bucket Policy: $e');
    }
  }

  /// Set bucket policy (JSON string)
  Future<void> setBucketPolicy(String bucket, String policyJson) async {
    try {
      await client.raw.putBucketPolicy(bucket: bucket, policy: policyJson);
    } catch (e) {
      throw Exception('無法設定 Bucket Policy: $e');
    }
  }

  /// Delete bucket policy
  Future<void> deleteBucketPolicy(String bucket) async {
    try {
      await client.raw.deleteBucketPolicy(bucket: bucket);
    } catch (e) {
      throw Exception('無法刪除 Bucket Policy: $e');
    }
  }

  /// Get bucket CORS configuration
  Future<CorsConfiguration?> getBucketCors(String bucket) async {
    try {
      final result = await client.raw.getBucketCors(bucket: bucket);
      final rules = (result.cORSRules ?? []).map((r) {
        return CorsRule(
          allowedOrigins: r.allowedOrigins,
          allowedMethods: r.allowedMethods,
          allowedHeaders: r.allowedHeaders,
          exposeHeaders: r.exposeHeaders,
          maxAgeSeconds: r.maxAgeSeconds,
        );
      }).toList();
      return CorsConfiguration(rules: rules);
    } catch (e) {
      if (e.toString().contains('NoSuchCORSConfiguration')) {
        return null;
      }
      throw Exception('無法取得 CORS 設定: $e');
    }
  }

  /// Set bucket CORS configuration
  Future<void> setBucketCors(String bucket, CorsConfiguration config) async {
    try {
      final corsRules = config.rules.map((r) {
        return aws.CORSRule(
          allowedOrigins: r.allowedOrigins,
          allowedMethods: r.allowedMethods,
          allowedHeaders: r.allowedHeaders,
          exposeHeaders: r.exposeHeaders,
          maxAgeSeconds: r.maxAgeSeconds,
        );
      }).toList();
      await client.raw.putBucketCors(
        bucket: bucket,
        cORSConfiguration: aws.CORSConfiguration(cORSRules: corsRules),
      );
    } catch (e) {
      throw Exception('無法設定 CORS: $e');
    }
  }

  /// Delete bucket CORS configuration
  Future<void> deleteBucketCors(String bucket) async {
    try {
      await client.raw.deleteBucketCors(bucket: bucket);
    } catch (e) {
      throw Exception('無法刪除 CORS 設定: $e');
    }
  }

  GranteeType _mapGranteeType(String? type) {
    if (type == null) return GranteeType.canonicalUser;
    switch (type.toLowerCase()) {
      case 'canonicaluser':
        return GranteeType.canonicalUser;
      case 'amazoncustomerbyemail':
        return GranteeType.amazonCustomerByEmail;
      case 'group':
        return GranteeType.group;
      default:
        return GranteeType.canonicalUser;
    }
  }
}
