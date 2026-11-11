import 'package:epub_reader/reader/back_stack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places are forgotten after 3 page turns', () {
    final s = BackStack();
    s.push('/a');
    expect(s.pageTurned(), isFalse);
    expect(s.pageTurned(), isFalse);
    expect(s.isNotEmpty, isTrue);
    expect(s.pageTurned(), isTrue);
    expect(s.isEmpty, isTrue);
    expect(s.pop(), isNull);
  });

  test('a new link or jump starts the count again', () {
    final s = BackStack();
    s.push('/a');
    s.pageTurned();
    s.pageTurned();
    s.push('/b');
    expect(s.pageTurned(), isFalse);
    expect(s.pageTurned(), isFalse);
    expect(s.pop(), '/b');
    expect(s.pop(), '/a');
  });

  test('back starts the count again for the places left', () {
    final s = BackStack();
    s.push('/a');
    s.push('/b');
    s.pageTurned();
    s.pageTurned();
    expect(s.pop(), '/b');
    expect(s.pageTurned(), isFalse);
    expect(s.pageTurned(), isFalse);
    expect(s.isNotEmpty, isTrue);
    expect(s.pageTurned(), isTrue);
    expect(s.isEmpty, isTrue);
  });

  test('page turns with no places do nothing', () {
    final s = BackStack();
    for (var i = 0; i < 5; i++) {
      expect(s.pageTurned(), isFalse);
    }
    // The count does not carry over to a later place.
    s.push('/a');
    expect(s.pageTurned(), isFalse);
    expect(s.isNotEmpty, isTrue);
  });
}
