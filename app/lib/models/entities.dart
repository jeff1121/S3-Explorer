import 'package:equatable/equatable.dart';

class ConnectionProfile extends Equatable {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.region,
    required this.accessKeyId,
    required this.secretKey,
    this.defaultBucket,
    this.defaultPrefix,
    this.concurrency = 3,
    this.partSizeMb = 8,
    this.retryPolicy = const RetryPolicy(),
  });

  final String id;
  final String name;
  final Uri endpoint;
  final String region;
  final String accessKeyId;
  final String secretKey;
  final String? defaultBucket;
  final String? defaultPrefix;
  final int concurrency;
  final int partSizeMb;
  final RetryPolicy retryPolicy;

  ConnectionProfile copyWith({
    String? name,
    Uri? endpoint,
    String? region,
    String? accessKeyId,
    String? secretKey,
    String? defaultBucket,
    String? defaultPrefix,
    int? concurrency,
    int? partSizeMb,
    RetryPolicy? retryPolicy,
  }) {
    return ConnectionProfile(
      id: id,
      name: name ?? this.name,
      endpoint: endpoint ?? this.endpoint,
      region: region ?? this.region,
      accessKeyId: accessKeyId ?? this.accessKeyId,
      secretKey: secretKey ?? this.secretKey,
      defaultBucket: defaultBucket ?? this.defaultBucket,
      defaultPrefix: defaultPrefix ?? this.defaultPrefix,
      concurrency: concurrency ?? this.concurrency,
      partSizeMb: partSizeMb ?? this.partSizeMb,
      retryPolicy: retryPolicy ?? this.retryPolicy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        endpoint,
        region,
        accessKeyId,
        secretKey,
        defaultBucket,
        defaultPrefix,
        concurrency,
        partSizeMb,
        retryPolicy
      ];
}

class RetryPolicy extends Equatable {
  const RetryPolicy({this.maxAttempts = 3, this.backoffMs = 500});
  final int maxAttempts;
  final int backoffMs;
  @override
  List<Object?> get props => [maxAttempts, backoffMs];
}

class ObjectNode extends Equatable {
  const ObjectNode({
    required this.bucket,
    required this.key,
    required this.isFolder,
    required this.sizeBytes,
    required this.lastModified,
    this.etag,
    this.acl,
    this.contentType,
  });

  final String bucket;
  final String key;
  final bool isFolder;
  final int sizeBytes;
  final DateTime lastModified;
  final String? etag;
  final String? acl;
  final String? contentType;

  @override
  List<Object?> get props =>
      [bucket, key, isFolder, sizeBytes, lastModified, etag, acl, contentType];
}

enum TransferType { upload, download, copy, move, delete, sync }

enum TransferStatus { pending, running, paused, failed, completed, canceled }

class TransferProgress extends Equatable {
  const TransferProgress(
      {this.bytesTransferred = 0,
      this.totalBytes = 0,
      this.partsCompleted,
      this.partsTotal});
  final int bytesTransferred;
  final int totalBytes;
  final int? partsCompleted;
  final int? partsTotal;

  TransferProgress copyWith(
      {int? bytesTransferred,
      int? totalBytes,
      int? partsCompleted,
      int? partsTotal}) {
    return TransferProgress(
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      partsCompleted: partsCompleted ?? this.partsCompleted,
      partsTotal: partsTotal ?? this.partsTotal,
    );
  }

  @override
  List<Object?> get props =>
      [bytesTransferred, totalBytes, partsCompleted, partsTotal];
}

class EndpointRef extends Equatable {
  const EndpointRef({this.profileId, this.bucket, this.key, this.localPath});
  final String? profileId;
  final String? bucket;
  final String? key;
  final String? localPath;
  @override
  List<Object?> get props => [profileId, bucket, key, localPath];
}

class TransferTask extends Equatable {
  TransferTask({
    required this.id,
    required this.type,
    required this.source,
    required this.target,
    this.useMultipart = true,
    this.partSizeMb,
    this.concurrency,
    this.overwrite = true,
    this.status = TransferStatus.pending,
    this.progress = const TransferProgress(),
    this.retryCount = 0,
    this.error,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final TransferType type;
  final EndpointRef source;
  final EndpointRef target;
  final bool useMultipart;
  final int? partSizeMb;
  final int? concurrency;
  final bool overwrite;
  final TransferStatus status;
  final TransferProgress progress;
  final int retryCount;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransferTask copyWith({
    TransferStatus? status,
    TransferProgress? progress,
    int? retryCount,
    String? error,
    DateTime? updatedAt,
  }) {
    return TransferTask(
      id: id,
      type: type,
      source: source,
      target: target,
      useMultipart: useMultipart,
      partSizeMb: partSizeMb,
      concurrency: concurrency,
      overwrite: overwrite,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        source,
        target,
        useMultipart,
        partSizeMb,
        concurrency,
        overwrite,
        status,
        progress,
        retryCount,
        error,
        createdAt,
        updatedAt
      ];
}

class SyncJob extends Equatable {
  const SyncJob({
    required this.id,
    required this.source,
    required this.target,
    required this.mode,
    required this.conflictPolicy,
    this.status = SyncStatus.pending,
    this.summary = const SyncSummary(),
  });

  final String id;
  final EndpointRef source;
  final EndpointRef target;
  final SyncMode mode;
  final ConflictPolicy conflictPolicy;
  final SyncStatus status;
  final SyncSummary summary;

  @override
  List<Object?> get props =>
      [id, source, target, mode, conflictPolicy, status, summary];
}

enum SyncMode { oneWay, mirror }

enum ConflictPolicy { overwrite, skip, keepBoth }

enum SyncStatus { pending, running, failed, completed }

class SyncSummary extends Equatable {
  const SyncSummary(
      {this.added = 0, this.updated = 0, this.skipped = 0, this.conflicts = 0});
  final int added;
  final int updated;
  final int skipped;
  final int conflicts;
  @override
  List<Object?> get props => [added, updated, skipped, conflicts];
}

class PresignedUrlRecord extends Equatable {
  PresignedUrlRecord({
    required this.id,
    required this.bucket,
    required this.key,
    required this.action,
    required this.expiresAt,
    required this.url,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String id;
  final String bucket;
  final String key;
  final PresignAction action;
  final DateTime expiresAt;
  final DateTime generatedAt;
  final Uri url;

  @override
  List<Object?> get props =>
      [id, bucket, key, action, expiresAt, generatedAt, url];
}

enum PresignAction { get, put }

class Bookmark extends Equatable {
  const Bookmark(
      {required this.id,
      required this.label,
      required this.bucket,
      required this.prefix,
      required this.profileId});
  final String id;
  final String label;
  final String bucket;
  final String prefix;
  final String profileId;
  @override
  List<Object?> get props => [id, label, bucket, prefix, profileId];
}

class PolicyItem extends Equatable {
  const PolicyItem(
      {required this.scope,
      required this.type,
      this.statementSummary,
      this.cannedAcl,
      this.lastSyncedAt});
  final PolicyScope scope;
  final PolicyType type;
  final String? statementSummary;
  final String? cannedAcl;
  final DateTime? lastSyncedAt;
  @override
  List<Object?> get props =>
      [scope, type, statementSummary, cannedAcl, lastSyncedAt];
}

enum PolicyScope { bucket, object }

enum PolicyType { acl, policy, cors }
