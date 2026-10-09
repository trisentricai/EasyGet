import 'package:easyget/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first frame shows the EASYGET brand text', (tester) async {
    await tester.pumpWidget(const EasyGetApp());
    expect(find.text('EASYGET'), findsOneWidget);
  });
}
