// On-device engine check. It starts crengine the same way as the app, opens
// the sample books, draws a page of each, and resolves the KOReader
// XPointers in juliet.epub (lib/dev/koreader_vectors.dart).
//
// The sample books are not in the app. Pass the folder that holds them:
//   iOS simulator (it can read the host file system):
//     flutter test integration_test/engine_test.dart -d <simulator> \
//       --dart-define=FIXTURES=$PWD/test/fixtures
//   Android: first adb push the files to /sdcard/Download, then
//       --dart-define=FIXTURES=/sdcard/Download
//
// The format check needs the files of test/fixtures/formats in the same
// folder. A format without its sample file is skipped (sample.chm is not
// in the repository).
import 'dart:io';

import 'package:epub_reader/dev/koreader_vectors.dart';
import 'package:epub_reader/engine/cre_engine.dart';
import 'package:epub_reader/engine/engine_assets.dart';
import 'package:epub_reader/library/book_formats.dart';
import 'package:epub_reader/reader/advanced_settings.dart';
import 'package:epub_reader/reader/line_shift.dart';
import 'package:epub_reader/reader/style_tweaks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const String fixtures = String.fromEnvironment('FIXTURES');

const int width = 1080;
const int height = 1920;

// The app defaults (ReaderSettings) at a device pixel ratio of 2.
const EngineLayout layout = EngineLayout(
  fontFace: 'Noto Serif',
  fontSize: 40,
  interlinePercent: 100,
  marginLeft: 24,
  marginTop: 24,
  marginRight: 24,
  marginBottom: 24,
  hyphenation: true,
  embeddedStyles: true,
  embeddedFonts: true,
  backgroundRgb: 0xFFFFFF,
  textRgb: 0x000000,
);

Future<OpenResult> openBook(CreEngine engine, String name) =>
    engine.open('$fixtures/$name', width: width, height: height, dpi: 320, layout: layout);

/// The app layout with the advanced settings (as ReaderController._layout).
EngineLayout advancedLayout({
  AdvancedSettings common = const AdvancedSettings(),
  BookSettings book = const BookSettings(),
}) => EngineLayout(
  fontFace: layout.fontFace,
  fontSize: layout.fontSize,
  interlinePercent: layout.interlinePercent,
  marginLeft: layout.marginLeft,
  marginTop: layout.marginTop,
  marginRight: layout.marginRight,
  marginBottom: layout.marginBottom,
  hyphenation: layout.hyphenation,
  embeddedStyles: layout.embeddedStyles,
  embeddedFonts: layout.embeddedFonts,
  backgroundRgb: layout.backgroundRgb,
  textRgb: layout.textRgb,
  textLanguage: book.language,
  props: common.engineProps(),
  extraCss: buildTweakCss(common, book),
  gammaIndex: common.fontGamma,
);

/// FNV-1a hash of a page image.
int pageHash(List<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h = ((h ^ b) * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// The page count and the images of the first pages of the open book. Two
/// layouts with the same signature show the same pages.
Future<String> signature(CreEngine engine) async {
  final count = (await engine.position()).pageCount;
  final hashes = <int>[];
  for (var page = 1; page <= count && page <= 6; page++) {
    hashes.add(pageHash((await engine.drawPage(page))!));
  }
  return '$count $hashes';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late CreEngine engine;

  setUpAll(() async {
    if (fixtures.isEmpty) fail('Pass --dart-define=FIXTURES=<folder with the sample books>');
    final paths = await prepareEngineData();
    engine = await CreEngine.start(dataDir: paths.dataDir, cacheDir: paths.cacheDir);
  });

  tearDownAll(() => engine.dispose());

  test('engine starts and registers the fonts', () {
    expect(engine.fontFaces, contains('Noto Serif'));
  });

  for (final name in ['juliet.epub', 'leaves.epub', 'sample.fb2']) {
    test('opens and draws $name', () async {
      expect(File('$fixtures/$name').existsSync(), isTrue, reason: 'missing $fixtures/$name');
      final r = await openBook(engine, name);
      expect(r.position.pageCount, greaterThan(1));
      expect(r.position.xpointer, isNotNull);
      final pixels = await engine.drawPage(2);
      expect(pixels, isNotNull);
      expect(pixels!.length, width * height * 4);
      // The page has text: not every pixel is the white background.
      expect(pixels.any((b) => b != 0xFF), isTrue);
      await engine.closeBook();
    });
  }

  // sample.fb2: language "ru" in the metadata, Russian and English text, and
  // one footnote in body[name="notes"].
  group('advanced settings (sample.fb2)', () {
    Future<OpenResult> open(EngineLayout l, {String? languageHint}) => engine.open(
      '$fixtures/sample.fb2',
      width: width,
      height: height,
      dpi: 320,
      layout: l,
      languageHint: languageHint,
    );

    Future<String> pages(EngineLayout l, {String? languageHint}) async {
      await open(l, languageHint: languageHint);
      final s = await signature(engine);
      await engine.closeBook();
      return s;
    }

    test('the book language sets the hyphenation rules', () async {
      // English rules first: the engine keeps the language of the book
      // before, and this shows that the book language replaces it.
      final english = await pages(advancedLayout(book: const BookSettings(language: 'en-US')));
      // No language from the library: the engine takes it from the book.
      final fromBook = await pages(advancedLayout());
      final hinted = await pages(advancedLayout(), languageHint: 'ru');
      final russian = await pages(advancedLayout(book: const BookSettings(language: 'ru')));
      expect(fromBook, russian, reason: 'the language of the book is not applied');
      expect(hinted, russian, reason: 'the language from the library is not applied');
      expect(english, isNot(russian), reason: 'the language does not change the pages');
    });

    test('each advanced setting changes the pages, and the defaults come back', () async {
      final base = await pages(advancedLayout());
      final changes = <String, EngineLayout>{
        'font weight': advancedLayout(common: const AdvancedSettings(fontWeight: 3)),
        'word spacing': advancedLayout(common: const AdvancedSettings(wordSpacing: WordSpacing.small)),
        'word expansion': advancedLayout(common: const AdvancedSettings(wordExpansion: WordExpansion.more)),
        'hanging punctuation': advancedLayout(common: const AdvancedSettings(hangingPunctuation: true)),
        'alignment': advancedLayout(common: const AdvancedSettings(alignment: TweakAlign.left)),
        'indent': advancedLayout(common: const AdvancedSettings(indent: TweakIndent.none)),
        'paragraph spacing': advancedLayout(common: const AdvancedSettings(paragraphSpacing: TweakSpacing.full)),
        'in-page footnotes': advancedLayout(common: const AdvancedSettings(inPageFootnotes: true)),
        'book CSS': advancedLayout(book: const BookSettings(customCss: 'p { margin-left: 3em !important; }')),
      };
      for (final e in changes.entries) {
        expect(await pages(e.value), isNot(base), reason: '${e.key} does not change the pages');
      }
      // The engine keeps some of these values for all books. The defaults
      // set them back.
      expect(await pages(advancedLayout()), base, reason: 'the defaults do not come back');
    });

    test('a change in an open book keeps the position, and contrast needs no new layout', () async {
      final r = await open(advancedLayout());
      final before = await signature(engine);
      for (final l in [
        advancedLayout(common: const AdvancedSettings(inPageFootnotes: true)),
        advancedLayout(common: const AdvancedSettings(fontWeight: 3)),
        advancedLayout(book: const BookSettings(language: 'en-US')),
      ]) {
        final changed = await engine.setLayout(l);
        expect(changed.position.xpointer, r.position.xpointer);
        expect(await signature(engine), isNot(before));
      }
      final back = await engine.setLayout(advancedLayout());
      expect(back.position.xpointer, r.position.xpointer);
      expect(await signature(engine), before);

      await engine.setGamma(kFontGammaSteps.last);
      final contrast = await signature(engine);
      expect(contrast, isNot(before), reason: 'contrast does not change the pages');
      expect(contrast.split(' ').first, before.split(' ').first, reason: 'contrast changed the page count');
      await engine.setGamma(kDefaultFontGamma);
      expect(await signature(engine), before);
      await engine.closeBook();
    });
  });

  // One sample per file format of the format table (test/fixtures/formats).
  // The result lines start with "FORMAT" in the test output.
  group('file formats', () {
    final extensions = [
      for (final f in kBookFormats)
        if (f.extension != '.epub' && f.extension != '.fb2') f.extension,
    ];
    for (final ext in extensions) {
      final name = 'sample$ext';
      test('opens $name', () async {
        final path = '$fixtures/$name';
        if (!File(path).existsSync()) {
          // ignore: avoid_print
          print('FORMAT $ext: no sample file, not checked');
          markTestSkipped('no $name in $fixtures');
          return;
        }
        // Library data, as the scan reads it.
        final cover = '${Directory.systemTemp.path}/cover$ext';
        final info = await engine.bookInfo(path, cover);
        expect(info, isNotNull, reason: 'the engine cannot read the library data');
        // The reader: layout, a page image, the contents list.
        final r = await engine.open(path, width: width, height: height, dpi: 320, layout: layout);
        final pages = r.position.pageCount;
        expect(pages, greaterThan(1), reason: 'the sample has text for more than one page');
        final first = await engine.drawPage(1);
        expect(first!.any((b) => b != 0xFF), isTrue, reason: 'page 1 is empty');
        // Position save and restore: the place of page 2 opens again on page 2.
        final there = await engine.gotoPage(2);
        expect(there.xpointer, isNotNull);
        final text = await engine.textAt(there.xpointer!, maxChars: 40);
        await engine.closeBook();
        final again = await engine.open(
          path,
          width: width,
          height: height,
          dpi: 320,
          layout: layout,
          xpointer: there.xpointer,
        );
        expect(again.position.page, 2, reason: 'the saved position does not open on its page');
        // ignore: avoid_print
        print(
          'FORMAT $ext: opens, engine format "${r.info.format}", $pages pages, ${r.toc.length} contents entries, '
          'title "${info!.title}", author "${info.authors}", cover ${info.hasCover}, '
          'text at page 2 "${(text ?? '').replaceAll('\n', ' ').trim()}"',
        );
        await engine.closeBook();
      });
    }
  });

  // Line shift: the engine gives the page slices and the text lines of the
  // book laid out as one strip (sample.fb2).
  group('line shift (sample.fb2)', () {
    /// Rows of a page image that have a pixel that is not white.
    Set<int> inkRows(List<int> rgba) {
      final rows = <int>{};
      for (var y = 0; y < height; y++) {
        final from = y * width * 4;
        for (var i = from; i < from + width * 4; i++) {
          if (rgba[i] != 0xFF) {
            rows.add(y);
            break;
          }
        }
      }
      return rows;
    }

    test('pages are slices of the strip and lines match the page image', () async {
      await openBook(engine, 'sample.fb2');
      final count = (await engine.position()).pageCount;
      final info = await engine.shiftInfo(page: 2);
      final g = ShiftGeometry.fromRows(
        pages: info.pages,
        lines: info.lines,
        minY: info.minY,
        maxY: info.maxY,
        areaTop: info.areaTop,
        areaHeight: info.areaHeight,
      );
      expect(g.areaTop, layout.marginTop);
      expect(g.areaHeight, height - layout.marginTop - layout.marginBottom);
      final page2 = g.page(2)!;
      expect(info.top, page2.start);
      expect(g.minY, g.page(1)!.start);
      expect(g.lines, isNotEmpty);
      // Pages follow each other on the strip and do not overlap.
      for (var i = 1; i < g.pages.length; i++) {
        expect(g.pages[i].page, g.pages[i - 1].page + 1);
        expect(g.pages[i].start, greaterThanOrEqualTo(g.pages[i - 1].end));
        expect(g.pages[i].height, lessThanOrEqualTo(g.areaHeight));
      }
      final gaps = [for (var i = 1; i < g.pages.length; i++) g.pages[i].start - g.pages[i - 1].end];
      // ignore: avoid_print
      print('SHIFT pages ${[for (final p in g.pages) '${p.page}:${p.start}+${p.height}']} gaps $gaps of $count pages');

      // The lines of page 2, and the rows of its image that hold them.
      final ink = inkRows((await engine.drawPage(2))!);
      final lines = [
        for (final l in g.lines)
          if (l.top >= page2.start && l.bottom <= page2.end) l,
      ];
      expect(lines.length, greaterThan(5));
      var withInk = 0;
      for (final l in lines) {
        final from = g.areaTop + l.top - page2.start;
        final to = g.areaTop + l.bottom - page2.start;
        if (ink.any((row) => row >= from && row < to)) withInk++;
      }
      // ignore: avoid_print
      print(
        'SHIFT page 2: ${lines.length} lines, $withInk with ink, first ${lines.first.top}, last ${lines.last.bottom}',
      );
      expect(
        withInk,
        greaterThanOrEqualTo(lines.length * 9 ~/ 10),
        reason: 'the lines are not where the image has text',
      );
      // No text above the first line or below the slice of the page.
      expect(ink.where((row) => row < g.areaTop - 4), isEmpty);
      expect(ink.where((row) => row > g.areaTop + page2.height + 4), isEmpty);
      await engine.closeBook();
    });

    test('a shift sets the reading position to the first line of the view', () async {
      await openBook(engine, 'sample.fb2');
      final info = await engine.shiftInfo(page: 2);
      final g = ShiftGeometry.fromRows(
        pages: info.pages,
        lines: info.lines,
        minY: info.minY,
        maxY: info.maxY,
        areaTop: info.areaTop,
        areaHeight: info.areaHeight,
      );
      final page2 = g.page(2)!;
      final inside = [
        for (final l in g.lines)
          if (l.top > page2.start && l.bottom <= page2.end) l,
      ];
      // Three lines down from the top of page 2.
      final row = g.settle(inside[2].top + 3.0, page2.start);
      expect(row, inside[2].top);
      final p = await engine.shiftTo(row);
      expect(p, isNotNull);
      expect(p!.page, 2);
      final top = await engine.gotoPage(2);
      expect(p.xpointer, isNot(top.xpointer), reason: 'the position is still the top of the page');
      expect(await engine.compare(top.xpointer!, p.xpointer!), lessThan(0));
      // The position survives a close and opens on the fixed page.
      await engine.closeBook();
      final again = await engine.open(
        '$fixtures/sample.fb2',
        width: width,
        height: height,
        dpi: 320,
        layout: layout,
        xpointer: p.xpointer,
      );
      expect(again.position.page, 2);
      expect(again.position.xpointer, p.xpointer);
      // The geometry around a row is the same rows.
      final around = await engine.shiftInfo(y: row);
      expect(around.top, row);
      expect(around.lines.any((l) => l[0] == row), isTrue);
      // The page turn rule: forward shows the page with the first line below.
      final end = g.visibleEnd(row);
      expect(end, greaterThan(page2.end - 1));
      expect(g.pageAt(shiftTurnRow(forward: true, top: row, end: end)), 3);
      expect(g.pageAt(shiftTurnRow(forward: false, top: row, end: end)), 2);
      await engine.closeBook();
    });
  });

  test('KOReader XPointers resolve to the same text (juliet.epub)', () async {
    await openBook(engine, 'juliet.epub');
    final results = await runJulietVectors(engine);
    for (final r in results) {
      expect(r.actual, r.vector.expected, reason: r.vector.source);
    }
    await engine.closeBook();
  });
}
