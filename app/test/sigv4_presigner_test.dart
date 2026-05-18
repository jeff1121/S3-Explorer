import 'package:app/services/sigv4_presigner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presign creates SigV4 query parameters and preserves key segments', () {
    final presigner = SigV4Presigner(
      endpoint: Uri.parse('https://s3.example.com'),
      region: 'us-east-1',
      accessKeyId: 'AKIA_TEST',
      secretKey: 'secret',
    );

    final url = presigner.presign(
      method: 'GET',
      bucket: 'bucket',
      key: 'folder/../file name.txt',
      expiresIn: const Duration(minutes: 15),
      now: DateTime.utc(2026, 5, 18, 9, 0, 0),
    );

    final uri = Uri.parse(url);

    expect(url, contains('/bucket/folder/../file%20name.txt?'));
    expect(uri.queryParameters['X-Amz-Algorithm'], 'AWS4-HMAC-SHA256');
    expect(uri.queryParameters['X-Amz-Date'], '20260518T090000Z');
    expect(uri.queryParameters['X-Amz-Expires'], '900');
    expect(uri.queryParameters['X-Amz-SignedHeaders'], 'host');
    expect(uri.queryParameters['X-Amz-Signature'], isNotEmpty);
  });
}
