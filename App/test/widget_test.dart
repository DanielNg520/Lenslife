import 'package:flutter_test/flutter_test.dart';
import 'package:lenslifeapp/main.dart';

void main() {
  testWidgets('LensLife app launches splash', (WidgetTester tester) async {
    await tester.pumpWidget(const LensLifeApp());
    await tester.pump();
    expect(find.text('Smarter lens care, clearer routines.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
