import 'package:app/main.dart';
import 'package:app/services/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('AppRoot renders connection screen', (WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'S3 Explorer',
      packageName: 'app',
      version: '1.0.1',
      buildNumber: '2',
      buildSignature: '',
    );

    await tester.pumpWidget(AppRoot(providers: AppProviders()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
