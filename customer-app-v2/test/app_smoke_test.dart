import 'package:easyget/core/storage/token_store.dart';
import 'package:easyget/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first frame shows the EASYGET brand text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No stored tokens -> boot resolves guest without any network call.
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        ],
        child: const EasyGetApp(),
      ),
    );
    await tester.pump();
    expect(find.text('EASYGET'), findsOneWidget);
  });
}
