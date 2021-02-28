import 'package:flutter_test/flutter_test.dart';
import 'package:slide_puzzle/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final width = 4, height = 4;
    final tiles = (width * height - 1);

    await tester.pumpWidget(PuzzleApp());

    expect(find.text('0'), findsNothing);
    expect(find.text('Clicks: 0'), findsOneWidget);
    expect(find.text('Tiles left: $tiles'), findsOneWidget);

    for (var i = 1; i < tiles; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }
  });
}
