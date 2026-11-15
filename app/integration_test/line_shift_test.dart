// On-device check of the line shift in the reader screen. A vertical drag
// moves the text of sample.fb2 by whole lines, and the next page turn goes
// back to the fixed pages.
//
// Android: adb push test/fixtures/sample.fb2 /sdcard/Download/, then
//   flutter test integration_test/line_shift_test.dart -d <device> \
//     --dart-define=FIXTURES=/sdcard/Download
// HOLD (seconds, default 0) keeps each state on screen, to look at it.
import 'package:epub_reader/app_services.dart';
import 'package:epub_reader/reader/line_shift.dart';
import 'package:epub_reader/reader/reader_screen.dart';
import 'package:epub_reader/reader/widgets/reader_footer.dart';
import 'package:epub_reader/reader/widgets/shifted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String fixtures = String.fromEnvironment('FIXTURES');
const int hold = int.fromEnvironment('HOLD');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a vertical drag shifts the page by whole lines', (tester) async {
    if (fixtures.isEmpty) fail('Pass --dart-define=FIXTURES=<folder with sample.fb2>');
    final services = await AppServices.start();
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: MaterialApp(home: ReaderScreen(path: '$fixtures/sample.fb2')),
      ),
    );

    Future<void> until(bool Function() done, String what) async {
      for (var i = 0; i < 300; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (done()) return;
      }
      fail('timeout: $what');
    }

    Future<void> look(String state) async {
      // ignore: avoid_print
      print('STATE $state');
      if (hold > 0) await tester.pump(Duration(seconds: hold));
    }

    await until(() => find.byType(ReaderFooter).evaluate().isNotEmpty, 'the book opens');
    final c = tester.widget<ReaderFooter>(find.byType(ReaderFooter)).controller;

    Future<void> showPage(int page) async {
      await c.gotoPage(page);
      await until(() => c.displayPage == page && c.position?.page == page && !c.isShifted, 'page $page shows');
    }

    Future<ShiftGeometry> geometry(int page) async {
      final info = await services.engine.shiftInfo(page: page);
      return ShiftGeometry.fromRows(
        pages: info.pages,
        lines: info.lines,
        minY: info.minY,
        maxY: info.maxY,
        areaTop: info.areaTop,
        areaHeight: info.areaHeight,
      );
    }

    /// Drags the text by [rows] page pixels (positive: forward) and lets go.
    Future<void> drag(double rows, {String? state}) async {
      final size = tester.getSize(find.byType(ReaderScreen));
      final scale = c.pixelScale(size); // not exact (the footer), near enough to find the gesture distance
      final gesture = await tester.startGesture(size.center(Offset.zero));
      final sign = rows > 0 ? -1.0 : 1.0;
      // The first move is used up by the gesture detection.
      await gesture.moveBy(Offset(0, sign * 30));
      await tester.pump(const Duration(milliseconds: 20));
      const steps = 8;
      for (var i = 0; i < steps; i++) {
        await gesture.moveBy(Offset(0, -rows * scale / steps));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await until(
        () => c.shiftView != null && c.shiftView!.slices.length > 1 || rows.abs() < 40,
        'the drag moves the text',
      );
      if (state != null) await look(state);
      await gesture.up();
      await until(() => !(c.shiftView?.dragging ?? false), 'the text settles');
      await tester.pump(const Duration(milliseconds: 300));
    }

    // ---- Forward by three lines on page 2.
    await showPage(2);
    final g = await geometry(2);
    final page2 = g.page(2)!;
    final page3 = g.page(3)!;
    final lineTops = {for (final l in g.lines) l.top};
    final inside = [
      for (final l in g.lines)
        if (l.top > page2.start && l.bottom <= page2.end) l,
    ];
    final topOfPage = c.position!.xpointer;
    await look('page 2');
    await drag((inside[2].top - page2.start).toDouble(), state: 'drag forward');
    await until(() => c.isShifted && c.position?.xpointer != topOfPage, 'the position follows the shift');
    var view = c.shiftView!;
    // ignore: avoid_print
    print('SHIFT rests at ${view.y} (page 2 starts at ${page2.start}), end ${view.end}, page ${c.position!.page}');
    expect(find.byType(ShiftedPage), findsOneWidget);
    expect(view.dragging, isFalse);
    expect(view.y, greaterThan(page2.start));
    expect(view.y, lessThan(page2.end));
    expect(lineTops, contains(view.y.round()), reason: 'the view does not rest on a line top');
    expect(view.end, g.visibleEnd(view.y.round()));
    expect(c.displayPage, 2);
    expect(c.pageMarks, isEmpty);
    expect(c.pageLinks, isEmpty);
    await look('shifted forward');

    // ---- A page turn forward: the page with the first line below the view.
    final shiftedPosition = c.position!.xpointer;
    c.turnPage(1);
    await until(() => !c.isShifted && c.position?.page == 3 && c.displayPage == 3, 'forward turn shows page 3');
    expect(find.byType(ShiftedPage), findsNothing);
    expect(c.position!.xpointer, isNot(shiftedPosition));
    await look('page 3 after the turn');

    // ---- Back by two lines from page 3: the view starts in page 2.
    final before3 = [
      for (final l in g.lines)
        if (l.top >= page2.start && l.bottom <= page3.start) l,
    ];
    await drag(-(page3.start - before3[before3.length - 2].top).toDouble(), state: 'drag back');
    await until(() => c.isShifted && c.position?.page == 2, 'the position goes back with the shift');
    view = c.shiftView!;
    // ignore: avoid_print
    print('SHIFT rests at ${view.y} (page 3 starts at ${page3.start}), end ${view.end}, page ${c.position!.page}');
    expect(view.y, lessThan(page3.start));
    expect(lineTops, contains(view.y.round()));
    await look('shifted back');

    // ---- A page turn back: the page with the last line above the view.
    c.turnPage(-1);
    await until(() => !c.isShifted && c.position?.page == 2 && c.displayPage == 2, 'back turn shows page 2');
    await look('page 2 after the turn');

    // ---- Less than half a line: the view returns to the page.
    final lineHeight = inside[1].bottom - inside[1].top;
    final start = c.position!.xpointer;
    await drag(lineHeight / 4);
    await until(() => !c.isShifted, 'a short drag returns to the page');
    expect(c.displayPage, 2);
    expect(c.position!.xpointer, start);
    expect(find.byType(ShiftedPage), findsNothing);

    // ---- A drag to the start of the next page is that page.
    await drag((page3.start - page2.start).toDouble());
    await until(() => !c.isShifted && c.displayPage == 3 && c.position?.page == 3, 'a full page drag shows page 3');

    // ---- A jump leaves the shifted view.
    await drag((inside[2].top - page2.start).toDouble());
    await until(() => c.isShifted, 'shifted again');
    await showPage(1);
    expect(find.byType(ShiftedPage), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    services.engine.dispose();
  });
}
