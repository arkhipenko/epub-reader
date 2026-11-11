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
import 'dart:io';

import 'package:epub_reader/dev/koreader_vectors.dart';
import 'package:epub_reader/engine/cre_engine.dart';
import 'package:epub_reader/engine/engine_assets.dart';
import 'package:epub_reader/reader/advanced_settings.dart';
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

  test('KOReader XPointers resolve to the same text (juliet.epub)', () async {
    await openBook(engine, 'juliet.epub');
    final results = await runJulietVectors(engine);
    for (final r in results) {
      expect(r.actual, r.vector.expected, reason: r.vector.source);
    }
    await engine.closeBook();
  });
}
