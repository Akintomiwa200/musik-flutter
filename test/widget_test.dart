import 'package:flutter_test/flutter_test.dart';

import 'package:musik/main.dart';

void main() {
  testWidgets('Musik app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MusikApp());
    await tester.pump();
    expect(find.text('Musik'), findsNothing);
  });
}
