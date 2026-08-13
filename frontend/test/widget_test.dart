import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('MiDosis app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MiDosisApp());
    expect(find.text('MiDosis'), findsOneWidget);
  });
}
