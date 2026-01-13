import 'package:app/models/entities.dart';
import 'package:app/services/logging.dart';
import 'package:app/services/profile_storage.dart';
import 'package:app/services/s3_client.dart';
import 'package:flutter/foundation.dart';

class ConnectionViewModel extends ChangeNotifier {
  ConnectionViewModel({required ProfileStorage storage, required AppLogger logger})
      : _storage = storage,
        _logger = logger;

  final ProfileStorage _storage;
  final AppLogger _logger;

  List<ConnectionProfile> profiles = [];
  ConnectionProfile? selected;

  // Draft fields bound to the form
  String name = '';
  String endpointText = '';
  String region = '';
  String accessKeyId = '';
  String secretKey = '';
  String defaultBucket = '';
  String defaultPrefix = '';
  int concurrency = 3;
  int partSizeMb = 8;
  int retryMaxAttempts = 3;
  int retryBackoffMs = 500;

  bool loading = false;
  bool saving = false;
  bool testing = false;
  String? errorMessage;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    profiles = await _storage.load();
    if (profiles.isEmpty) {
      profiles = [_storage.createTemplate()];
    }
    selected = profiles.first;
    _applyProfile(selected!);
    loading = false;
    notifyListeners();
  }

  void _applyProfile(ConnectionProfile profile) {
    name = profile.name;
    endpointText = profile.endpoint.toString();
    region = profile.region;
    accessKeyId = profile.accessKeyId;
    secretKey = profile.secretKey;
    defaultBucket = profile.defaultBucket ?? '';
    defaultPrefix = profile.defaultPrefix ?? '';
    concurrency = profile.concurrency;
    partSizeMb = profile.partSizeMb;
    retryMaxAttempts = profile.retryPolicy.maxAttempts;
    retryBackoffMs = profile.retryPolicy.backoffMs;
  }

  void updateDraft({
    String? name,
    String? endpoint,
    String? region,
    String? accessKeyId,
    String? secretKey,
    String? defaultBucket,
    String? defaultPrefix,
    int? concurrency,
    int? partSizeMb,
    int? retryMaxAttempts,
    int? retryBackoffMs,
  }) {
    this.name = name ?? this.name;
    endpointText = endpoint ?? endpointText;
    this.region = region ?? this.region;
    this.accessKeyId = accessKeyId ?? this.accessKeyId;
    this.secretKey = secretKey ?? this.secretKey;
    this.defaultBucket = defaultBucket ?? this.defaultBucket;
    this.defaultPrefix = defaultPrefix ?? this.defaultPrefix;
    this.concurrency = concurrency ?? this.concurrency;
    this.partSizeMb = partSizeMb ?? this.partSizeMb;
    this.retryMaxAttempts = retryMaxAttempts ?? this.retryMaxAttempts;
    this.retryBackoffMs = retryBackoffMs ?? this.retryBackoffMs;
    notifyListeners();
  }

  String? validateDraft() {
    if (name.trim().isEmpty) return '名稱必填';
    final uri = Uri.tryParse(endpointText.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Endpoint URL 需包含 http/https';
    }
    if (accessKeyId.trim().isEmpty || secretKey.trim().isEmpty) {
      return 'AccessKey 與 SecretKey 必填';
    }
    if (partSizeMb < 5) return '分段大小需 >= 5MB';
    if (concurrency < 1) return '並行數需 >= 1';
    if (retryMaxAttempts < 0 || retryBackoffMs < 0) return '重試參數需為正整數';
    return null;
  }

  ConnectionProfile _buildProfileFromDraft() {
    final uri = Uri.parse(endpointText.trim());
    return ConnectionProfile(
      id: selected?.id ?? _storage.createTemplate().id,
      name: name.trim(),
      endpoint: uri,
      region: region.trim(),
      accessKeyId: accessKeyId.trim(),
      secretKey: secretKey.trim(),
      defaultBucket: defaultBucket.isEmpty ? null : defaultBucket.trim(),
      defaultPrefix: defaultPrefix.isEmpty ? null : defaultPrefix.trim(),
      concurrency: concurrency,
      partSizeMb: partSizeMb,
      retryPolicy: RetryPolicy(maxAttempts: retryMaxAttempts, backoffMs: retryBackoffMs),
    );
  }

  Future<void> saveProfile(ConnectionProfile profile) async {
    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      profiles[idx] = profile;
    } else {
      profiles.add(profile);
    }
    await _storage.save(profiles);
    _logger.info('Saved profile ${profile.name}');
    notifyListeners();
  }

  Future<String?> saveDraft() async {
    final validation = validateDraft();
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return validation;
    }
    saving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final profile = _buildProfileFromDraft();
      selected = profile;
      await saveProfile(profile);
      return null;
    } catch (e, st) {
      _logger.error('Failed to save profile', e, st);
      errorMessage = e.toString();
      return errorMessage;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<ConnectionProfile> addTemplate() async {
    final profile = _storage.createTemplate();
    profiles.add(profile);
    await _storage.save(profiles);
    selected = profile;
    _applyProfile(profile);
    notifyListeners();
    return profile;
  }

  void select(String id) {
    selected = profiles.firstWhere((p) => p.id == id, orElse: () => selected ?? profiles.first);
    if (selected != null) {
      _applyProfile(selected!);
    }
    errorMessage = null;
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (selected == null) return;
    profiles.removeWhere((p) => p.id == selected!.id);
    if (profiles.isEmpty) {
      final template = _storage.createTemplate();
      profiles.add(template);
      selected = template;
      _applyProfile(template);
    } else {
      selected = profiles.first;
      _applyProfile(selected!);
    }
    await _storage.save(profiles);
    notifyListeners();
  }

  Future<String?> testConnection() async {
    final validation = validateDraft();
    if (validation != null) {
      errorMessage = validation;
      notifyListeners();
      return validation;
    }
    testing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final profile = _buildProfileFromDraft();
      final client = S3Client(profile: profile);
      await client.listBuckets();
      _logger.info('Connection test succeeded for ${profile.endpoint}');
      return null;
    } catch (e, st) {
      _logger.error('Connection test failed', e, st);
      // Extract more useful error message
      String msg;
      if (e.toString().contains('InvalidBucketName')) {
        msg = 'Invalid bucket name. Bucket names must be valid DNS names.';
      } else if (e.toString().contains('InvalidAccessKeyId')) {
        msg = 'Invalid access key ID.';
      } else if (e.toString().contains('SignatureDoesNotMatch')) {
        msg = 'Invalid secret access key.';
      } else if (e.toString().contains('NoSuchBucket')) {
        msg = 'Bucket does not exist.';
      } else if (e.toString().contains('AccessDenied')) {
        msg = 'Access denied. Check your IAM permissions.';
      } else {
        msg = e.toString();
      }
      errorMessage = msg;
      return errorMessage;
    } finally {
      testing = false;
      notifyListeners();
    }
  }
}
