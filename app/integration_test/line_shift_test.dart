// On-device check of the line shift in the reader screen. A vertical drag
// moves the text by whole lines, and the page turns after it continue from
// the shifted line until the next chapter start. A new layout and a reopen
// keep the shifted view.
//
// The test writes its own book (two long chapters and a footnote) to the
// temporary folder of the app, so it needs no fixture files:
//   flutter test integration_test/line_shift_test.dart -d <device>
// HOLD (seconds, default 0) keeps each state on screen, to look at it.
import 'dart:io';

import 'package:epub_reader/app_services.dart';
import 'package:epub_reader/reader/line_shift.dart';
import 'package:epub_reader/reader/reader_screen.dart';
import 'package:epub_reader/reader/widgets/reader_footer.dart';
import 'package:epub_reader/reader/widgets/shifted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const int hold = int.fromEnvironment('HOLD');

/// Two chapters of 60 paragraphs. Each chapter starts on a new page (the
/// FB2 style sheet). Paragraph 5 of chapter 1 has a footnote link.
String _book() {
  final b = StringBuffer()
    ..write('<?xml version="1.0" encoding="utf-8"?>\n')
    ..write('<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0" ')
    ..write('xmlns:l="http://www.w3.org/1999/xlink">\n')
    ..write('<description><title-info><book-title>Aligned</book-title>')
    ..write('<author><first-name>Test</first-name><last-name>Book</last-name></author>')
    ..write('<lang>en</lang></title-info></description>\n')
    ..write('<body>\n<title><p>Aligned</p></title>\n');
  for (var c = 1; c <= 2; c++) {
    b.write('<section><title><p>Chapter $c</p></title>\n');
    for (var i = 1; i <= 60; i++) {
      final note = c == 1 && i == 5 ? ' <a l:href="#n1" type="note">[1]</a>' : '';
      b.write(
        '<p>Chapter $c, paragraph $i. The river ran slow and wide under the low grey sky, '
        'and the ferry crossed it twice a day.$note</p>\n',
      );
    }
    b.write('</section>\n');
  }
  b.write('</body>\n<body name="notes"><section id="n1"><title><p>1</p></title>');
  b.write('<p>The note.</p></section></body>\n</FictionBook>\n');
  return b.toString();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('page turns after a line shift continue from the shifted line', (tester) async {
    final dir = Directory('${Directory.systemTemp.path}/line_shift_test')..createSync(recursive: true);
    final path = '${dir.path}/aligned.fb2';
    File(path).writeAsStringSync(_book());
    final services = await AppServices.start();
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: MaterialApp(home: ReaderScreen(path: path)),
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
    await until(() => c.toc.length >= 2, 'the table of contents');
    final chapter1 = c.toc.firstWhere((e) => e.title.contains('Chapter 1')).page;
    final chapter2 = c.toc.firstWhere((e) => e.title.contains('Chapter 2')).page;
    // ignore: avoid_print
    print('BOOK ${c.pageCount} pages, chapter 1 on page $chapter1, chapter 2 on page $chapter2');
    expect(chapter2 - chapter1, greaterThan(3), reason: 'chapter 1 must be long enough for some turns');

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
        bookEnd: info.bookEnd,
      );
    }

    /// Lines of [page] after its first line.
    List<LineSpan> inside(ShiftGeometry g, int page) {
      final p = g.page(page)!;
      return [
        for (final l in g.lines)
          if (l.top > p.start && l.bottom <= p.end) l,
      ];
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

    ViewSpan current() => ViewSpan(c.shiftView!.y.round(), c.shiftView!.end!);

    /// Waits until the shifted view is [view] and the position follows it.
    Future<void> shows(ViewSpan view, String what) async {
      await until(
        () =>
            c.shiftView != null &&
            !c.shiftView!.dragging &&
            c.shiftView!.y.round() == view.start &&
            c.shiftView!.end == view.end,
        what,
      );
    }

    // ---- Shift by three lines at the start of chapter 1.
    await showPage(chapter1);
    final g1 = await geometry(chapter1);
    final lines1 = inside(g1, chapter1);
    await drag((lines1[2].top - g1.page(chapter1)!.start).toDouble(), state: 'drag forward');
    await until(() => c.isShifted && c.shiftView?.end != null, 'the view rests shifted');
    final v0 = current();
    expect(find.byType(ShiftedPage), findsOneWidget);
    expect(v0.start, lines1[2].top);
    expect(c.pageMarks, isEmpty);
    expect(c.pageLinks, isEmpty);
    await look('shifted forward');

    // ---- Forward turns continue at the end of each view, up to chapter 2.
    final views = [v0];
    for (var turn = 0; turn < 40 && c.isShifted; turn++) {
      final before = views.last;
      final xp = c.position!.xpointer;
      c.turnPage(1);
      await until(() => !c.isShifted || c.shiftView!.y.round() != before.start, 'forward turn ${turn + 1}');
      if (!c.isShifted) break;
      final now = current();
      expect(now.start, before.end, reason: 'turn ${turn + 1}: a line shows again or is skipped');
      await until(() => c.position?.xpointer != xp, 'the position follows turn ${turn + 1}');
      views.add(now);
      if (turn == 0) await look('aligned turn');
    }
    // ignore: avoid_print
    print('ALIGNED ${views.length} views: $views');
    expect(views.length, greaterThan(3));
    await until(() => !c.isShifted && c.displayPage == chapter2 && c.position?.page == chapter2, 'chapter 2 shows');
    final g2 = await geometry(chapter2);
    expect(views.last.end, g2.page(chapter2)!.start, reason: 'the last view ends where chapter 2 starts');
    await look('chapter 2 after the run');

    // ---- Back returns to the same views, in reverse order.
    for (var i = views.length - 1; i >= 0; i--) {
      c.turnPage(-1);
      await shows(views[i], 'back to view $i');
    }
    // Without history the back view ends where the view starts. Chapter 1
    // starts 3 lines above, so the back view holds these 3 lines.
    final firstLine = g1.lines.firstWhere((l) => l.top >= g1.page(chapter1)!.start).top;
    c.turnPage(-1);
    await shows(ViewSpan(firstLine, v0.start), 'back view above the first view');
    await look('back view at the chapter start');
    // The view starts at the chapter start: back shows the page before it.
    c.turnPage(-1);
    await until(() => !c.isShifted && c.displayPage == chapter1 - 1, 'the page before chapter 1');

    // ---- A highlight shows in a shifted view, where its text is.
    final middle = chapter1 + 1;
    await showPage(middle);
    final size = tester.getSize(find.byType(ReaderScreen));
    await c.selectWordAt(c.toPagePixels(size.center(Offset.zero), size));
    await until(() => c.selection != null && c.pageMarks['sel'] != null, 'a word is selected');
    await c.addHighlight();
    await until(() => c.pageMarks.keys.any((k) => int.tryParse(k) != null), 'the highlight shows on the page');
    final id = c.pageMarks.keys.firstWhere((k) => int.tryParse(k) != null);
    final onPage = c.pageMarks[id]!.first;
    final gm = await geometry(middle);
    await drag((inside(gm, middle)[1].top - gm.page(middle)!.start).toDouble());
    await until(() => c.isShifted && c.shiftMarks[id] != null && c.shiftView?.end != null, 'the highlight in rows');
    final inRows = c.shiftMarks[id]!.first;
    final view = c.shiftView!;
    expect(inRows.left, onPage.left);
    expect(inRows.top - gm.page(middle)!.start + view.areaTop, onPage.top);
    // A tap on it finds it (the tap opens its sheet in the app).
    final tap = Offset((inRows.left + inRows.right) / 2, view.areaTop + (inRows.top - view.y) + 2);
    expect(c.annotationAt(tap)?.id.toString(), id);
    await look('highlight in a shifted view');
    await c.deleteAnnotation(c.annotationAt(tap)!);

    // ---- A footnote link works in a shifted view, and back returns to it.
    await showPage(chapter1);
    await until(() => c.pageLinks.isNotEmpty, 'the footnote link on the page');
    await drag((lines1[0].top - g1.page(chapter1)!.start).toDouble());
    await until(() => c.isShifted && c.shiftLinks.isNotEmpty && c.shiftView?.end != null, 'links in rows');
    final shifted = current();
    final box = c.shiftLinks.first.boxes.first;
    final at = Offset(
      (box.left + box.right) / 2,
      c.shiftView!.areaTop + (box.top - c.shiftView!.y) + (box.bottom - box.top) / 2,
    );
    final link = c.linkAt(at);
    expect(link, isNotNull, reason: 'a tap on the link in the shifted view');
    await c.followLink(link!);
    await until(() => !c.isShifted && c.displayPage > chapter2, 'the footnote shows');
    await look('footnote');
    await c.goBack();
    await shows(shifted, 'back returns to the shifted view');
    await look('back in the shifted view');

    // ---- Less than half a line: the view returns to the page.
    await showPage(middle);
    final linesM = inside(gm, middle);
    final lineHeight = linesM[1].bottom - linesM[1].top;
    final start = c.position!.xpointer;
    await drag(lineHeight / 4);
    await until(() => !c.isShifted, 'a short drag returns to the page');
    expect(c.displayPage, middle);
    expect(c.position!.xpointer, start);
    expect(find.byType(ShiftedPage), findsNothing);

    // ---- A drag to the start of the next page is that page.
    await drag((gm.page(middle + 1)!.start - gm.page(middle)!.start).toDouble());
    await until(() => !c.isShifted && c.displayPage == middle + 1, 'a full page drag shows the next page');

    // ---- A jump leaves the shifted view.
    await drag((linesM[2].top - gm.page(middle)!.start).toDouble());
    await until(() => c.isShifted, 'shifted again');
    await showPage(1);
    expect(find.byType(ShiftedPage), findsNothing);

    // ---- A new layout keeps the shifted view at the same first line.
    await showPage(middle);
    final settings = services.settings.value;
    final fixedXp = c.position!.xpointer;
    await drag((linesM[2].top - gm.page(middle)!.start).toDouble());
    await until(() => c.isShifted && c.shiftView?.end != null, 'shifted before the new layout');
    await until(() => c.position?.xpointer != fixedXp, 'the position follows the shift');
    final shiftedXp = c.position!.xpointer!;
    await services.updateSettings(settings.copyWith(fontSize: settings.fontSize + 2));
    await until(
      () => c.isShifted && c.shiftView?.end != null && c.position?.xpointer == shiftedXp && c.pageCount != 16,
      'the shifted view after a font size change',
    );
    final row = (await services.engine.rowOf(shiftedXp))!;
    final around = await services.engine.shiftInfo(y: row);
    final g = ShiftGeometry.fromRows(
      pages: around.pages,
      lines: around.lines,
      minY: around.minY,
      maxY: around.maxY,
      areaTop: around.areaTop,
      areaHeight: around.areaHeight,
    );
    expect(c.shiftView!.y.round(), g.lineTopAt(row), reason: 'the view starts at the line of the position');
    await look('shifted view after a font size change');
    await services.updateSettings(settings);
    await until(() => c.isShifted && c.pageCount == 16 && c.position?.xpointer == shiftedXp, 'the old font size');

    // ---- A book that closes in a shifted view opens as that view.
    final viewBefore = current();
    final bookKey = c.bookId!;
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 100; i++) {
      final b = await services.db.bookById(bookKey);
      if (b != null && b.lastShifted && b.lastXPointer == shiftedXp) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
    final saved = (await services.db.bookById(bookKey))!;
    expect(saved.lastXPointer, shiftedXp);
    expect(saved.lastShifted, isTrue);
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: MaterialApp(home: ReaderScreen(path: path)),
      ),
    );
    await until(() => find.byType(ReaderFooter).evaluate().isNotEmpty, 'the book opens again');
    final c2 = tester.widget<ReaderFooter>(find.byType(ReaderFooter)).controller;
    await until(() => c2.isShifted && c2.shiftView?.end != null, 'the book opens as the shifted view');
    expect(c2.position!.xpointer, shiftedXp);
    expect(ViewSpan(c2.shiftView!.y.round(), c2.shiftView!.end!), viewBefore);
    expect(find.byType(ShiftedPage), findsOneWidget);
    await look('shifted view after reopen');
    // A turn from it is an aligned turn.
    c2.turnPage(1);
    await until(() => c2.isShifted && c2.shiftView!.y.round() == viewBefore.end, 'an aligned turn after reopen');

    // ---- A book that closes on a fixed page opens on that page.
    await c2.gotoPage(middle);
    await until(() => !c2.isShifted && c2.position?.page == middle, 'a fixed page');
    final fixedId = c2.bookId!;
    final pageXp = c2.position!.xpointer;
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 100; i++) {
      final b = await services.db.bookById(fixedId);
      if (b != null && !b.lastShifted && b.lastXPointer == pageXp) break;
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: MaterialApp(home: ReaderScreen(path: path)),
      ),
    );
    await until(() => find.byType(ReaderFooter).evaluate().isNotEmpty, 'the book opens a third time');
    final c3 = tester.widget<ReaderFooter>(find.byType(ReaderFooter)).controller;
    await until(() => c3.isOpen && c3.displayPage == middle, 'the fixed page after reopen');
    await tester.pump(const Duration(milliseconds: 300));
    expect(c3.isShifted, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    services.engine.dispose();
  });
}
