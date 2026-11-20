// Line shift rules: where the text settles after a vertical drag, what a
// shifted view shows, and where the page turns of an aligned run go.
import 'package:epub_reader/reader/line_shift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Three pages of 10 lines, each line 30 rows high. Page 2 ends a chapter
/// after 4 lines, so it is short. Page 3 starts the next chapter after a
/// forced page break. The book ends after 24 lines (row 720).
ShiftGeometry _book({int? coverFrom, int? coverTo}) {
  final lines = <LineSpan>[for (var i = 0; i < 24; i++) LineSpan(i * 30, i * 30 + 30)];
  return ShiftGeometry(
    pages: const [PageSpan(1, 0, 300), PageSpan(2, 300, 120), PageSpan(3, 420, 300, forced: true)],
    lines: lines,
    minY: 0,
    maxY: 420,
    areaTop: 40,
    areaHeight: 300,
    bookEnd: 720,
    coverFrom: coverFrom,
    coverTo: coverTo,
  );
}

ShiftTurn _turn(ShiftGeometry g, ViewSpan current, List<ViewSpan> history, {required bool forward}) =>
    alignedTurn(g, current, forward: forward, history: history);

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

  group('forced page breaks', () {
    test('engine rows carry the forced flag', () {
      final g = ShiftGeometry.fromRows(
        pages: const [
          [1, 0, 300, 0],
          [2, 300, 300, 1],
          [3, 600, 300],
        ],
        lines: const [],
        minY: 0,
        maxY: 600,
        areaTop: 0,
        areaHeight: 300,
      );
      expect([for (final p in g.pages) p.forced], [false, true, false]);
    });

    test('a view ends at a forced page break', () {
      final g = _book();
      // Rows 330 to 630 would show 10 lines; the chapter ends at row 420.
      expect(g.visibleEnd(330), 420);
      expect(g.nextBreak(330), 420);
      expect(g.nextBreak(420), isNull);
    });

    test('the section of a row starts at the last forced break before it', () {
      final g = _book();
      expect(g.sectionStart(419), isNull);
      expect(g.sectionStart(420), 420);
      expect(g.sectionStart(600), 420);
    });
  });

  group('aligned turns', () {
    test('forward continues at the end of the view: no line shows again', () {
      final g = _book();
      final history = <ViewSpan>[];
      // Shifted 3 lines into page 1: rows 90 to 390.
      final v0 = ViewSpan(90, g.visibleEnd(90));
      expect(v0, const ViewSpan(90, 390));
      // The next view starts at row 390 and stops before the chapter start.
      expect(_turn(g, v0, history, forward: true), const TurnToView(ViewSpan(390, 420)));
      expect(history, [v0]);
    });

    test('forward onto a page start shows that fixed page', () {
      final g = _book();
      final history = <ViewSpan>[const ViewSpan(90, 390)];
      // The view before the chapter start ends where page 3 starts.
      expect(_turn(g, const ViewSpan(390, 420), history, forward: true), const TurnToPage(3));
      // A page start without a forced break works the same.
      expect(_turn(g, const ViewSpan(60, 300), <ViewSpan>[], forward: true), const TurnToPage(2));
      // The views stay in the history: back from page 3 returns to them.
      expect(history, const [ViewSpan(90, 390), ViewSpan(390, 420)]);
    });

    test('back after forward returns to the same views', () {
      final g = _book();
      final history = <ViewSpan>[];
      const v0 = ViewSpan(90, 390);
      final v1 = (_turn(g, v0, history, forward: true) as TurnToView).view;
      expect(_turn(g, v1, history, forward: false), const TurnToView(v0));
      expect(history, isEmpty);
    });

    test('back without history ends where the view starts', () {
      final g = _book();
      // Shifted 7 lines into page 3: the 7 lines above fill the back view
      // (the screen holds 10, but the chapter starts at row 420).
      expect(_turn(g, const ViewSpan(630, 720), <ViewSpan>[], forward: false), const TurnToView(ViewSpan(420, 630)));
      // In page 1 the back view starts at the start of the book.
      expect(_turn(g, const ViewSpan(90, 390), <ViewSpan>[], forward: false), const TurnToView(ViewSpan(0, 90)));
    });

    test('forward after a back view returns to the view it came from', () {
      final g = _book();
      final history = <ViewSpan>[];
      const v0 = ViewSpan(630, 720);
      final back = (_turn(g, v0, history, forward: false) as TurnToView).view;
      expect(_turn(g, back, history, forward: true), TurnToView(ViewSpan(v0.start, g.visibleEnd(v0.start))));
    });

    test('a back view fills the screen with whole lines', () {
      // Lines of 40 rows: 300 rows above the view hold 7 whole lines.
      final g = ShiftGeometry(
        pages: const [PageSpan(1, 0, 280), PageSpan(2, 280, 280)],
        lines: [for (var i = 0; i < 14; i++) LineSpan(i * 40, i * 40 + 40)],
        minY: 0,
        maxY: 280,
        areaTop: 0,
        areaHeight: 300,
        bookEnd: 560,
      );
      // From row 400: rows 100 to 400 can show; the first whole line starts at 120.
      expect(g.backStart(400), 120);
    });

    test('back from a view at a page start shows the fixed page before it', () {
      final g = _book();
      expect(_turn(g, const ViewSpan(420, 720), <ViewSpan>[], forward: false), const TurnToPage(2));
      expect(_turn(g, const ViewSpan(0, 90), <ViewSpan>[], forward: false), const TurnNone());
    });

    test('forward from the end of the book does nothing', () {
      final g = _book();
      final history = <ViewSpan>[];
      // A view can start after the start of the last page.
      expect(_turn(g, const ViewSpan(630, 720), history, forward: true), const TurnNone());
      expect(history, isEmpty);
    });

    test('a tall picture is split between two views', () {
      const g = ShiftGeometry(
        pages: [PageSpan(1, 0, 300), PageSpan(2, 300, 300)],
        lines: [LineSpan(0, 30), LineSpan(30, 400), LineSpan(400, 430)],
        minY: 0,
        maxY: 300,
        areaTop: 0,
        areaHeight: 300,
        bookEnd: 600,
      );
      // No whole line fits below row 30: the view shows all its rows.
      final v0 = ViewSpan(30, g.visibleEnd(30));
      expect(v0, const ViewSpan(30, 330));
      // The next view shows the rest of the picture and the line after it.
      expect(_turn(g, v0, <ViewSpan>[], forward: true), const TurnToView(ViewSpan(330, 430)));
    });
  });

  group('rows without text', () {
    /// A chapter that ends at row 290 and a page 2 that starts the next
    /// chapter at row 300 (a forced break). Its title line starts at row
    /// 320 (padding above it).
    ShiftGeometry gaps() => ShiftGeometry(
      pages: const [PageSpan(1, 0, 290), PageSpan(2, 300, 300, forced: true)],
      lines: [
        for (var i = 0; i < 9; i++) LineSpan(20 + i * 30, 50 + i * 30),
        const LineSpan(320, 350),
        for (var i = 0; i < 8; i++) LineSpan(350 + i * 30, 380 + i * 30),
      ],
      minY: 0,
      maxY: 300,
      areaTop: 0,
      areaHeight: 300,
      bookEnd: 600,
    );

    test('forward skips the margin before a page start and shows that page', () {
      final g = gaps();
      // The view from the second line ends after the last line of chapter 1.
      final v = ViewSpan(50, g.visibleEnd(50));
      expect(v, const ViewSpan(50, 290));
      expect(g.nextStart(290), 300);
      expect(_turn(g, v, <ViewSpan>[], forward: true), const TurnToPage(2));
    });

    test('back from the first line of a chapter shows the page before it', () {
      final g = gaps();
      // Only the padding of the title lies between the chapter start and
      // the first line: there is nothing to show above it in this chapter.
      expect(g.backStart(320), isNull);
      expect(_turn(g, const ViewSpan(320, 600), <ViewSpan>[], forward: false), const TurnToPage(1));
    });

    test('forward skips rows without text inside a page', () {
      final g = ShiftGeometry(
        pages: const [PageSpan(1, 0, 600)],
        lines: const [LineSpan(0, 30), LineSpan(30, 60), LineSpan(100, 130)],
        minY: 0,
        maxY: 0,
        areaTop: 0,
        areaHeight: 60,
        bookEnd: 600,
      );
      // A paragraph margin from row 60 to 100: the next view starts at 100.
      expect(_turn(g, const ViewSpan(0, 60), <ViewSpan>[], forward: true), const TurnToView(ViewSpan(100, 130)));
    });
  });

  group('geometry', () {
    test('covers tells whether the lines of some rows are loaded', () {
      final g = _book(coverFrom: 0, coverTo: 600);
      expect(g.covers(90, 390), isTrue);
      expect(g.covers(390, 690), isFalse);
      // Rows outside the book count as covered.
      expect(g.covers(-300, 0), isTrue);
      expect(_book(coverFrom: 120, coverTo: 720).covers(420, 1020), isTrue);
      expect(_book().covers(-1000, 5000), isTrue);
    });

    test('lineTopAt gives the top of the line that holds a row', () {
      final g = _book();
      expect(g.lineTopAt(95), 90);
      expect(g.lineTopAt(90), 90);
      expect(g.lineTopAt(5000), 5000);
    });
  });
}
