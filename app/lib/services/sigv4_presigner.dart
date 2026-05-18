import 'dart:convert';

import 'package:crypto/crypto.dart';

class SigV4Presigner {
  const SigV4Presigner({
    required this.endpoint,
    required this.region,
    required this.accessKeyId,
    required this.secretKey,
    this.service = 's3',
  });

  final Uri endpoint;
  final String region;
  final String accessKeyId;
  final String secretKey;
  final String service;

  String presign({
    required String method,
    required String bucket,
    required String key,
    required Duration expiresIn,
    DateTime? now,
  }) {
    final issuedAt = (now ?? DateTime.now().toUtc()).toUtc();
    final dateStamp = _dateStamp(issuedAt);
    final amzDate = _amzDate(issuedAt);
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final host = _hostHeader(endpoint);
    final canonicalUri = '/${_uriEncode(bucket)}/${_encodeKeyPath(key)}';
    final credential = '$accessKeyId/$credentialScope';
    final query = <String, String>{
      'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
      'X-Amz-Credential': credential,
      'X-Amz-Date': amzDate,
      'X-Amz-Expires': expiresIn.inSeconds.toString(),
      'X-Amz-SignedHeaders': 'host',
    };
    final canonicalQuery = _canonicalQuery(query);
    final canonicalRequest = [
      method.toUpperCase(),
      canonicalUri,
      canonicalQuery,
      'host:$host',
      '',
      'host',
      'UNSIGNED-PAYLOAD',
    ].join('\n');
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    final signature = _hmacHex(_signingKey(dateStamp), stringToSign);
    query['X-Amz-Signature'] = signature;

    final path = _joinEndpointPath(endpoint.path, canonicalUri);
    return '${_origin(endpoint)}$path?${_canonicalQuery(query)}';
  }

  List<int> _signingKey(String dateStamp) {
    final kDate = _hmac(utf8.encode('AWS4$secretKey'), dateStamp);
    final kRegion = _hmac(kDate, region);
    final kService = _hmac(kRegion, service);
    return _hmac(kService, 'aws4_request');
  }

  List<int> _hmac(List<int> key, String value) {
    return Hmac(sha256, key).convert(utf8.encode(value)).bytes;
  }

  String _hmacHex(List<int> key, String value) {
    return Hmac(sha256, key).convert(utf8.encode(value)).toString();
  }

  String _canonicalQuery(Map<String, String> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => '${_uriEncode(entry.key)}=${_uriEncode(entry.value)}')
        .join('&');
  }

  String _encodeKeyPath(String key) {
    return key
        .replaceFirst(RegExp(r'^/+'), '')
        .split('/')
        .map(_uriEncode)
        .join('/');
  }

  String _uriEncode(String value) {
    return Uri.encodeComponent(value)
        .replaceAll('+', '%20')
        .replaceAll('%7E', '~');
  }

  String _hostHeader(Uri uri) {
    final defaultPort = (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);
    return defaultPort ? uri.host : '${uri.host}:${uri.port}';
  }

  String _joinEndpointPath(String endpointPath, String canonicalUri) {
    final base = endpointPath == '/'
        ? ''
        : endpointPath.replaceFirst(RegExp(r'/+$'), '');
    return '$base$canonicalUri';
  }

  String _origin(Uri uri) {
    final defaultPort = (uri.scheme == 'https' && uri.port == 443) ||
        (uri.scheme == 'http' && uri.port == 80);
    return defaultPort
        ? '${uri.scheme}://${uri.host}'
        : '${uri.scheme}://${uri.host}:${uri.port}';
  }

  String _dateStamp(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}'
        '${value.month.toString().padLeft(2, '0')}'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _amzDate(DateTime value) {
    return '${_dateStamp(value)}T'
        '${value.hour.toString().padLeft(2, '0')}'
        '${value.minute.toString().padLeft(2, '0')}'
        '${value.second.toString().padLeft(2, '0')}Z';
  }
}
