// On-device check of the OPDS screens against the live Project Gutenberg
// catalog: search, a book page whose description is not well-formed XML,
// the book sheet, a download, and the book in the reader.
//
// It needs network access and a new install (the default catalogs):
//   flutter test integration_test/opds_test.dart -d <device>
// HOLD (seconds, default 0) keeps the book sheet on screen, to look at it.
import 'dart:convert';
import 'dart:io';

import 'package:epub_reader/app_services.dart';
import 'package:epub_reader/opds/opds_screens.dart';
import 'package:epub_reader/reader/widgets/reader_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:xml/xml.dart';

const int hold = int.fromEnvironment('HOLD');
const String query = 'The Picture of Dorian Gray';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Project Gutenberg: search, book page, sheet, download, open', (tester) async {
    // Does the live page still have the defect? If not, this run shows
    // only that a valid page works; the unit test fixtures carry the proof.
    final http = HttpClient();
    final req = await http.getUrl(Uri.parse('https://www.gutenberg.org/ebooks/174.opds'));
    final res = await req.close();
    final raw = await res.transform(utf8.decoder).join();
    http.close();
    var defect = false;
    try {
      XmlDocument.parse(raw);
    } on XmlException {
      defect = true;
    }
    // ignore: avoid_print
    print('OPDS book 174 page from the server is not well-formed XML: $defect');

    final services = await AppServices.start();
    await tester.pumpWidget(
      ServicesScope(
        services: services,
        child: const MaterialApp(home: OpdsCatalogsScreen()),
      ),
    );

    Future<void> until(bool Function() done, String what, {int seconds = 60}) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (done()) return;
      }
      fail('timeout: $what');
    }

    bool shows(Finder f) => f.evaluate().isNotEmpty;
    // Draws frames for a while: animations run and network images arrive.
    // The test binding draws only the frames that the test pumps.
    Future<void> frames(double seconds) async {
      for (var i = 0; i < seconds * 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // Feed pages on the navigator stack. Covered routes are offstage.
    Iterable<Element> pages() => find.byType(OpdsFeedScreen, skipOffstage: false).evaluate();
    Finder textWith(String part) =>
        find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(part), description: 'text with "$part"');

    // The catalog list of a new install.
    await until(() => shows(find.text('Project Gutenberg')), 'the catalog list');
    await tester.tap(find.text('Project Gutenberg'));
    await until(() => shows(find.byTooltip('Search')), 'the Gutenberg root page');

    // Search.
    await tester.tap(find.byTooltip('Search'));
    await until(() => shows(find.byType(TextField)), 'the search dialog');
    await tester.enterText(find.byType(TextField), query);
    await tester.tap(find.widgetWithText(FilledButton, 'Search'));
    // List tiles on the page on top. (find.text alone also matches the
    // search field while the dialog closes.)
    Finder tiles() =>
        find.descendant(of: find.byType(OpdsFeedScreen).last, matching: find.widgetWithText(ListTile, query));
    await until(() => pages().length == 2 && shows(tiles()), 'the search results');
    expect(textWith('The catalog sent a page with errors'), findsNothing);

    // The result list holds navigation entries to the book pages. Book 174
    // is the first in the Gutenberg order; check the address anyway.
    final count = tiles().evaluate().length;
    var opened = false;
    for (var i = 0; i < count && !opened; i++) {
      await tester.tap(tiles().at(i));
      await until(() => pages().length == 3, 'a book page opens');
      final url = tester.widget<OpdsFeedScreen>(find.byType(OpdsFeedScreen).last).url;
      if (url.endsWith('/174.opds')) {
        opened = true;
      } else {
        await tester.pageBack();
        await until(() => pages().length == 2 && shows(tiles()), 'back to the results');
      }
    }
    expect(opened, isTrue, reason: 'book 174 is not in the search results');

    // The book page: before the correction it showed '">" expected'.
    final bookTile = tiles();
    await until(
      () => shows(bookTile) || shows(textWith('The catalog sent a page with errors')) || shows(textWith('expected')),
      'the book page loads',
    );
    expect(textWith('The catalog sent a page with errors'), findsNothing);
    expect(textWith('expected'), findsNothing);
    expect(bookTile, findsWidgets);

    // The book sheet: summary without tags or script source.
    await tester.tap(bookTile.first);
    await until(() => shows(textWith('Download EPUB')), 'the book sheet');
    // The sheet slides up. A tap before it stops hits the barrier behind
    // it, and the sheet closes.
    await frames(1);
    final summary = tester.widget<Text>(textWith('This edition').first).data!;
    // ignore: avoid_print
    print('OPDS sheet summary: ${summary.replaceAll('\n', ' | ')}');
    for (final bad in ['<', '>', 'function(', 'window.open', 'addEventListener', '<script']) {
      expect(summary, isNot(contains(bad)), reason: 'the summary shows "$bad"');
    }
    expect(summary, contains('Oscar Wilde'));
    if (hold > 0) {
      await frames(4); // the cover arrives over the network
      // ignore: avoid_print
      print('STATE book sheet');
      await frames(hold.toDouble());
    }

    // MOBI first (a format of the other change), then EPUB: the Open button
    // opens the last download.
    Future<String> download(String label) async {
      final button = textWith('Download $label').first;
      await tester.ensureVisible(button);
      await tester.tap(button);
      await until(() => shows(textWith('Saved to')) || shows(textWith('download stopped')), '$label download');
      final status = tester.widget<Text>(textWith('Saved to').first).data!;
      expect(status, isNot(contains('cannot be opened')), reason: '$label: $status');
      final path = status.substring('Saved to '.length).split('\n').first;
      // ignore: avoid_print
      print('OPDS $label saved to $path (${File(path).lengthSync()} bytes)');
      return path;
    }

    final mobi = await download('MOBI');
    final epub = await download('EPUB');
    final books = await services.db.allBooks();
    for (final p in [mobi, epub]) {
      expect(books.any((b) => b.path == p && !b.missing), isTrue, reason: '$p is not in the library');
    }
    expect(epub, endsWith('.epub'));
    expect(mobi, endsWith('.mobi'));

    // Open the EPUB from the sheet.
    final open = find.widgetWithText(FilledButton, 'Open');
    await tester.ensureVisible(open);
    await tester.tap(open);
    await until(() => shows(find.byType(ReaderFooter)), 'the book opens', seconds: 90);
    final c = tester.widget<ReaderFooter>(find.byType(ReaderFooter)).controller;
    expect(c.error, isNull);
    expect(c.path, epub);
    expect(c.pageCount, greaterThan(1));
    // ignore: avoid_print
    print('OPDS opened ${c.info?.title} by ${c.info?.authors}: ${c.pageCount} pages');

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
    services.engine.dispose();
  });
}
