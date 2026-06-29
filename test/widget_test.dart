import 'package:flutter_test/flutter_test.dart';
import 'package:uranus/src/app/app.dart';

void main() {
  testWidgets('Uranus app boots to splash screen', (tester) async {
    await tester.pumpWidget(const UranusApp());

    expect(find.text('Uranus'), findsOneWidget);
  });
}
