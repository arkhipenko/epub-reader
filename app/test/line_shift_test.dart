// Line shift rules: where the text settles after a vertical drag, what a
// shifted view shows, and which page a page turn shows after a shift.
import 'package:epub_reader/reader/line_shift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three pages of 10 lines, each line 30 rows high. Page 2 ends a chapter
/// after 4 lines, so it is short.
ShiftGeometry _book() {
  final lines = <LineSpan>[for (var i = 0; i < 24; i++) LineSpan(i * 30, i * 30 + 30)];
  return ShiftGeometry(
    pages: const [PageSpan(1, 0, 300), PageSpan(2, 300, 120), PageSpan(3, 420, 300)],
    lines: lines,
    minY: 0,
    maxY: 420,
    areaTop: 40,
    areaHeight: 300,
  );
}

void main() {
  group('settle', () {
    test('a drag of less than half a line returns to the start', () {
      final g = _book();
      expect(g.settle(14, 0), 0);
      expect(g.settle(-14 + 300, 300), 300);
    });

    test('exactly half a line stays at the start (the smaller move)', () {
      expect(_book().settle(15, 0), 0);
    });

    test('the text rests on the nearest line top', () {
      final g = _book();
      expect(g.settle(16, 0), 30); // one line forward
      expect(g.settle(95, 0), 90); // three lines forward
      expect(g.settle(310, 420), 300); // back from page 3, onto the start of page 2
      expect(g.settle(275, 300), 270); // one line back from page 2
    });

    test('the view does not leave the book', () {
      final g = _book();
      expect(g.settle(-200, 0), 0);
      expect(g.settle(5000, 300), 420);
    });

    test('without lines the view stays where the drag started', () {
      const g = ShiftGeometry(pages: [], lines: [], minY: 0, maxY: 1000, areaTop: 0, areaHeight: 300);
      expect(g.settle(140, 60), 60);
    });

    test('a tall picture has no line inside: the view stops before or after it', () {
      const g = ShiftGeometry(
        pages: [PageSpan(1, 0, 300), PageSpan(2, 300, 300)],
        lines: [LineSpan(0, 30), LineSpan(30, 260), LineSpan(260, 290), LineSpan(300, 330)],
        minY: 0,
        maxY: 300,
        areaTop: 0,
        areaHeight: 300,
      );
      expect(g.settle(120, 0), 30); // nearer to the top of the picture
      expect(g.settle(200, 0), 260); // nearer to the line after it
    });
  });

  group('visibleEnd', () {
    test('the view ends after its last whole line', () {
      final g = _book();
      // Rows 45 to 345: the line from 330 to 360 is cut and not shown.
      expect(g.visibleEnd(30), 330);
      expect(g.visibleEnd(45), 330);
    });

    test('a view without a whole line shows all its rows', () {
      const g = ShiftGeometry(
        pages: [PageSpan(1, 0, 300)],
        lines: [LineSpan(0, 500)],
        minY: 0,
        maxY: 0,
        areaTop: 0,
        areaHeight: 300,
      );
      expect(g.visibleEnd(0), 300);
    });
  });

  group('pages', () {
    test('pageAt gives the page that holds a row', () {
      final g = _book();
      expect(g.pageAt(0), 1);
      expect(g.pageAt(299), 1);
      expect(g.pageAt(300), 2);
      expect(g.pageAt(419), 2);
      expect(g.pageAt(420), 3);
      expect(g.pageAt(9999), 3);
    });

    test('a row between two pages belongs to the page after it', () {
      const g = ShiftGeometry(
        pages: [PageSpan(4, 0, 100), PageSpan(5, 120, 100)],
        lines: [],
        minY: 0,
        maxY: 120,
        areaTop: 0,
        areaHeight: 100,
      );
      expect(g.pageAt(110), 5);
    });

    test('a view that starts where a page starts is that page', () {
      final g = _book();
      expect(g.pageStartingAt(300)?.page, 2);
      expect(g.pageStartingAt(330), isNull);
    });
  });

  group('page turn after a shift', () {
    test('forward shows the page with the first line below the view', () {
      final g = _book();
      // Shifted 3 lines into page 1: the view shows rows 90 to 390 (the
      // rest of page 1 and 3 lines of page 2).
      const top = 90;
      final end = g.visibleEnd(top);
      expect(end, 390);
      final row = shiftTurnRow(forward: true, top: top, end: end);
      // The first line below the view is on page 2. Page 2 shows from its
      // start: its first 3 lines show again, no line is skipped.
      expect(shiftTurnPage(forward: true, found: g.pageAt(row)!, current: g.pageAt(top)!, pageCount: 3), 2);
    });

    test('back shows the page with the last line above the view', () {
      final g = _book();
      const top = 90;
      final row = shiftTurnRow(forward: false, top: top, end: g.visibleEnd(top));
      expect(row, 89);
      // The lines above the view are on page 1: page 1 shows from its start.
      expect(shiftTurnPage(forward: false, found: g.pageAt(row)!, current: g.pageAt(top)!, pageCount: 3), 1);
    });

    test('a view that ends on a page end goes to the next page without a repeat', () {
      final g = _book();
      // The view from row 120 shows rows 120 to 420: it ends where page 3 starts.
      expect(g.visibleEnd(120), 420);
      expect(shiftTurnPage(forward: true, found: g.pageAt(420)!, current: g.pageAt(120)!, pageCount: 3), 3);
    });

    test('a turn always leaves the shifted view in its direction', () {
      expect(shiftTurnPage(forward: true, found: 5, current: 5, pageCount: 9), 6);
      expect(shiftTurnPage(forward: true, found: 9, current: 9, pageCount: 9), 9);
      expect(shiftTurnPage(forward: false, found: 6, current: 5, pageCount: 9), 5);
      expect(shiftTurnPage(forward: false, found: 0, current: 1, pageCount: 9), 1);
    });
  });
}
