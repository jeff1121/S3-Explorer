import 'dart:convert';
import 'dart:io';

import 'package:app/models/entities.dart';
import 'package:uuid/uuid.dart';

class ProfileStorage {
  ProfileStorage({Directory? homeDir}) : _homeDir = homeDir ?? Directory('${_userHome()}/.config/s3_desktop');

  final Directory _homeDir;
  final _uuid = const Uuid();

  File get _file => File('${_homeDir.path}/profiles.json');

  Future<List<ConnectionProfile>> load() async {
    if (!await _file.exists()) return [];
    final text = await _file.readAsString();
    if (text.isEmpty) return [];
    final List<dynamic> jsonList = json.decode(text) as List<dynamic>;
    return jsonList.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<ConnectionProfile> profiles) async {
    if (!await _homeDir.exists()) {
      await _homeDir.create(recursive: true);
    }
    final jsonList = profiles.map(_toJson).toList();
    await _file.writeAsString(json.encode(jsonList));
  }

  ConnectionProfile createTemplate() {
    return ConnectionProfile(
      id: _uuid.v4(),
      name: 'Default',
      endpoint: Uri.parse('https://play.min.io'),
      region: 'us-east-1',
      accessKeyId: '',
      secretKey: '',
    );
  }

  Map<String, dynamic> _toJson(ConnectionProfile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'endpoint': profile.endpoint.toString(),
      'region': profile.region,
      'accessKeyId': profile.accessKeyId,
      'secretKey': profile.secretKey,
      'defaultBucket': profile.defaultBucket,
      'defaultPrefix': profile.defaultPrefix,
      'concurrency': profile.concurrency,
      'partSizeMb': profile.partSizeMb,
      'retryPolicy': {
        'maxAttempts': profile.retryPolicy.maxAttempts,
        'backoffMs': profile.retryPolicy.backoffMs,
      },
    };
  }

  ConnectionProfile _fromJson(Map<String, dynamic> json) {
    return ConnectionProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      endpoint: Uri.parse(json['endpoint'] as String),
      region: json['region'] as String,
      accessKeyId: json['accessKeyId'] as String,
      secretKey: json['secretKey'] as String,
      defaultBucket: json['defaultBucket'] as String?,
      defaultPrefix: json['defaultPrefix'] as String?,
      concurrency: (json['concurrency'] as num?)?.toInt() ?? 3,
      partSizeMb: (json['partSizeMb'] as num?)?.toInt() ?? 8,
      retryPolicy: RetryPolicy(
        maxAttempts: (json['retryPolicy']?['maxAttempts'] as num?)?.toInt() ?? 3,
        backoffMs: (json['retryPolicy']?['backoffMs'] as num?)?.toInt() ?? 500,
      ),
    );
  }
}

String _userHome() {
  final env = Platform.environment;
  return env['HOME'] ?? env['USERPROFILE'] ?? '.';
}
