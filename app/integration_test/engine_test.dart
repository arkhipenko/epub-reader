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

  test('KOReader XPointers resolve to the same text (juliet.epub)', () async {
    await openBook(engine, 'juliet.epub');
    final results = await runJulietVectors(engine);
    for (final r in results) {
      expect(r.actual, r.vector.expected, reason: r.vector.source);
    }
    await engine.closeBook();
  });
}
