import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/engagement/data/app_update_repository.dart';
import 'package:easyget/features/engagement/presentation/update_gate.dart';
import 'package:easyget/models/app_update_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeAppUpdateRepo implements AppUpdateRepository {
  AppUpdateInfo info = const AppUpdateInfo(updateAvailable: false);
  bool fail = false;

  @override
  Future<AppUpdateInfo> checkUpdate(
      {required String platform, required String version}) async {
    if (fail) throw Exception('boom');
    return info;
  }
}

class _FakeUrlOpener implements UrlOpener {
  String? launched;

  @override
  Future<bool> open(String url) async {
    launched = url;
    return true;
  }
}

class _FakePackageInfo extends PackageInfo {
  _FakePackageInfo()
      : super(
          appName: 'EasyGet',
          packageName: 'com.trisentric.easyget',
          version: '1.0.0',
          buildNumber: '1',
        );
}

Future<ProviderContainer> _pumpGate(
  WidgetTester tester, {
  required _FakeAppUpdateRepo repo,
  required _FakeUrlOpener urls,
}) async {
  final container = ProviderContainer(overrides: [
    appUpdateRepositoryProvider.overrideWithValue(repo),
    packageInfoProvider.overrideWith((_) async => _FakePackageInfo()),
    urlOpenerProvider.overrideWithValue(urls),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: UpdateGate(child: Text('APP')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('no update shows nothing', (tester) async {
    await _pumpGate(
      tester,
      repo: _FakeAppUpdateRepo(),
      urls: _FakeUrlOpener(),
    );

    expect(find.text('APP'), findsOneWidget);
    expect(find.textContaining('Update'), findsNothing);
  });

  testWidgets('optional update offers Later and Update', (tester) async {
    final urls = _FakeUrlOpener();
    await _pumpGate(
      tester,
      repo: _FakeAppUpdateRepo()
        ..info = const AppUpdateInfo(
          updateAvailable: true,
          version: '1.1.0',
          releaseNotes: 'Faster everything.',
          downloadUrl: 'https://example.test/app.apk',
        ),
      urls: urls,
    );

    expect(find.textContaining('1.1.0'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(urls.launched, 'https://example.test/app.apk');
  });

  testWidgets('Later dismisses for this launch', (tester) async {
    await _pumpGate(
      tester,
      repo: _FakeAppUpdateRepo()
        ..info = const AppUpdateInfo(
          updateAvailable: true,
          version: '1.1.0',
          downloadUrl: 'https://example.test/app.apk',
        ),
      urls: _FakeUrlOpener(),
    );

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1.1.0'), findsNothing);
  });

  testWidgets('mandatory update has no Later', (tester) async {
    await _pumpGate(
      tester,
      repo: _FakeAppUpdateRepo()
        ..info = const AppUpdateInfo(
          updateAvailable: true,
          version: '2.0.0',
          isMandatory: true,
          downloadUrl: 'https://example.test/app.apk',
        ),
      urls: _FakeUrlOpener(),
    );

    expect(find.text('Later'), findsNothing);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('check failure stays silent', (tester) async {
    await _pumpGate(
      tester,
      repo: _FakeAppUpdateRepo()..fail = true,
      urls: _FakeUrlOpener(),
    );

    expect(find.text('APP'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}