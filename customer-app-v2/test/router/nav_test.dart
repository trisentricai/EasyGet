import 'dart:io';

import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/core/widgets/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// The exit-protocol contract: detail screens open with push (never go), so
/// the Android system back button walks the stack; popOrHome is the last
/// resort for stack-less entries (deep links).
/// Simulates the Android system back button (engine pop-route), which is the
/// exact path users hit — unlike `tester.pageBack`, which only taps an
/// on-screen button.
Future<void> systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pump(
    WidgetTester tester, {
    required String location,
  }) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              key: const Key('push-btn'),
              onPressed: () => context.push('/detail'),
              child: const Text('HOME'),
            ),
          ),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, _) => Scaffold(
            appBar: AppBar(
              leading: BackButton(
                onPressed: () => popOrHome(context),
              ),
            ),
            body: TextButton(
              key: const Key('back-btn'),
              onPressed: () => popOrHome(context),
              child: const Text('DETAIL'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('popOrHome pops a pushed route', (tester) async {
    await pump(tester, location: '/home');

    await tester.tap(find.byKey(const Key('push-btn')));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);

    await tester.tap(find.byKey(const Key('back-btn')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('popOrHome falls back to /home with an empty stack',
      (tester) async {
    await pump(tester, location: '/detail');

    await tester.tap(find.byKey(const Key('back-btn')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('system back walks a pushed stack', (tester) async {
    await pump(tester, location: '/home');

    await tester.tap(find.byKey(const Key('push-btn')));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);

    await systemBack(tester);
    expect(find.text('HOME'), findsOneWidget);
  });

  test('no code pushes tab roots (duplicate page keys)', () {
    // Pushing a StatefulShellRoute branch (go_router) trips the framework
    // duplicate-page-key assertion (navigator.dart:4032). Tabs go();
    // details push(). Query strings and deeper paths (/browse/all,
    // /product/x) are fine — only the exact tab roots are banned.
    final pattern =
        RegExp(r"\.push\('/(home|browse|search|cart|orders)(\?[^']*)?'\)");
    final offenders = <String>[];
    for (final entry in Directory('lib').listSync(recursive: true)) {
      final file = File(entry.path);
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'Tab roots must go(), never push(): $offenders');
  });
}