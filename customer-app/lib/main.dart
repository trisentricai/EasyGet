import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/theme/app_theme.dart';
import 'src/routing/app_router.dart';

Future<void> main() async {
  // Firebase (Google + email auth) reads google-services.json on Android.
  // A missing config only affects Firebase paths — classic login is untouched.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // No Firebase config (or init failure): Firebase login stays disabled.
  }
  runApp(const ProviderScope(child: EasyGetApp()));
}

class EasyGetApp extends ConsumerWidget {
  const EasyGetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'EasyGet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
