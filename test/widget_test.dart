import 'package:flutter_test/flutter_test.dart';
import 'package:aarambha_app/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const AarambhaApp());
    expect(find.text('Aarambha Cosmetics'), findsWidgets);
  });
}
