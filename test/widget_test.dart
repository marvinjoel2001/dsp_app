import 'package:flutter_test/flutter_test.dart';
import 'package:dsp_driver_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenDspDriverApp());
    expect(find.byType(OpenDspDriverApp), findsOneWidget);
  });
}
