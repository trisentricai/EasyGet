import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/account/presentation/account_providers.dart';
import 'features/engagement/data/order_watcher.dart';

void main() {
  runApp(ProviderScope(
    overrides: [
      // Deep-link target for tapped order alerts (avoids an import cycle:
      // the watcher must not import the router, which imports engagement).
      routerForNotificationsProvider.overrideWith((ref) =>
          _GoRouterShim(ref.watch(routerProvider))),
    ],
    child: const EasyGetApp(),
  ));
}

class _GoRouterShim implements GoRouterShim {
  _GoRouterShim(this._router);
  final GoRouter _router;

  @override
  void go(String location) => _router.go(location);
}

class EasyGetApp extends ConsumerStatefulWidget {
  const EasyGetApp({super.key});

  @override
  ConsumerState<EasyGetApp> createState() => _EasyGetAppState();
}

class _EasyGetAppState extends ConsumerState<EasyGetApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Foreground order-status alerts (idempotent; silent when logged out
      // or when notifications are denied).
      ref.read(orderWatcherProvider.notifier).start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EasyGet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
