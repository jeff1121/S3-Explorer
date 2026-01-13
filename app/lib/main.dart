import 'package:app/features/browser/browser_screen.dart';
import 'package:app/features/connection/connection_screen.dart';
import 'package:app/models/entities.dart';
import 'package:app/services/providers.dart';
import 'package:app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final providers = AppProviders();
  runApp(AppRoot(providers: providers));
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key, required this.providers});

  final AppProviders providers;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers.asList(),
      child: MaterialApp.router(
        title: 'S3 Explorer',
        theme: NowUITheme.themeData,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ConnectionScreen(),
    ),
    GoRoute(
      path: '/browser',
      builder: (context, state) {
        final profile = state.extra as ConnectionProfile?;
        if (profile == null) {
          return const _MissingProfile();
        }
        return BrowserScreen(profile: profile);
      },
    ),
  ],
);

class _MissingProfile extends StatelessWidget {
  const _MissingProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('尚未選擇連線設定'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('返回連線設定'),
            )
          ],
        ),
      ),
    );
  }
}
