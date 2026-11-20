import 'package:epub_reader/reader/back_stack.dart';
import 'package:epub_reader/reader/widgets/back_place_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackStack', () {
    test('back returns the places in reverse order', () {
      final s = BackStack();
      expect(s.isEmpty, isTrue);
      s.push('/a');
      s.push('/b');
      expect(s.isNotEmpty, isTrue);
      expect(s.pop()?.xpointer, '/b');
      expect(s.isNotEmpty, isTrue);
      expect(s.pop()?.xpointer, '/a');
      expect(s.isEmpty, isTrue);
      expect(s.pop(), isNull);
    });

    test('a place keeps the kind of view: fixed page or shifted view', () {
      final s = BackStack();
      s.push('/a');
      s.push('/b', shifted: true);
      final b = s.pop()!;
      expect(b.xpointer, '/b');
      expect(b.shifted, isTrue);
      final a = s.pop()!;
      expect(a.xpointer, '/a');
      expect(a.shifted, isFalse);
    });

    test('clear forgets all places', () {
      final s = BackStack();
      s.push('/a');
      s.push('/b');
      s.clear();
      expect(s.isEmpty, isTrue);
      expect(s.pop(), isNull);
      // A new link after a clear saves a place again.
      s.push('/c');
      expect(s.pop()?.xpointer, '/c');
    });

    test('clear on an empty stack does nothing', () {
      final s = BackStack();
      s.clear();
      expect(s.isEmpty, isTrue);
    });
  });

  group('BackPlaceButton', () {
    late int backs;
    late int clears;

    Future<void> pump(WidgetTester tester) {
      backs = 0;
      clears = 0;
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BackPlaceButton(onBack: () => backs++, onClear: () => clears++),
            ),
          ),
        ),
      );
    }

    testWidgets('a tap goes back', (tester) async {
      await pump(tester);
      await tester.tap(find.byType(BackPlaceButton));
      await tester.pump();
      expect(backs, 1);
      expect(clears, 0);
    });

    testWidgets('a long press clears and does not go back', (tester) async {
      await pump(tester);
      await tester.longPress(find.byType(BackPlaceButton));
      await tester.pump();
      expect(clears, 1);
      expect(backs, 0);
    });

    testWidgets('no tooltip, a screen-reader label instead', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      expect(find.byType(Tooltip), findsNothing);
      expect(find.bySemanticsLabel(BackPlaceButton.label), findsOneWidget);
      semantics.dispose();
    });
  });
}
