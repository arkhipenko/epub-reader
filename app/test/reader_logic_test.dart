import 'dart:ui';

import 'package:epub_reader/engine/cre_engine.dart';
import 'package:epub_reader/reader/chapters.dart';
import 'package:epub_reader/reader/reader_settings.dart';
import 'package:epub_reader/reader/reader_theme.dart';
import 'package:epub_reader/reader/tap_zones.dart';
import 'package:epub_reader/reader/widgets/goto_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tap zones', () {
    const size = Size(1000, 2000);
    TapAction at(TapLayout l, double x, double y) => tapActionFor(l, Offset(x, y), size);

    test('KOReader layout follows defaults.lua', () {
      expect(at(TapLayout.koreader, 100, 1000), TapAction.previous); // x < 1/4
      expect(at(TapLayout.koreader, 300, 1000), TapAction.next);
      expect(at(TapLayout.koreader, 900, 1000), TapAction.next);
      expect(at(TapLayout.koreader, 500, 100), TapAction.menu); // top 1/8
      expect(at(TapLayout.koreader, 500, 1900), TapAction.menu); // bottom 1/8
    });

    test('mirrored layout turns back on the right', () {
      expect(at(TapLayout.koreaderMirrored, 900, 1000), TapAction.previous);
      expect(at(TapLayout.koreaderMirrored, 100, 1000), TapAction.next);
    });

    test('thirds layout', () {
      expect(at(TapLayout.thirds, 100, 1000), TapAction.previous);
      expect(at(TapLayout.thirds, 500, 1000), TapAction.menu);
      expect(at(TapLayout.thirds, 900, 1000), TapAction.next);
    });
  });

  group('settings', () {
    test('JSON round trip', () {
      const s = ReaderSettings(
        fontFace: 'FreeSerif',
        fontSize: 18,
        lineSpacing: 120,
        themeId: 'sepia',
        tapLayout: TapLayout.thirds,
        footerItems: {FooterItem.battery, FooterItem.percent},
      );
      final r = ReaderSettings.decode(s.encode());
      expect(r.toJson(), s.toJson());
    });

    test('bad input falls back to defaults and clamps ranges', () {
      expect(ReaderSettings.decode('not json').toJson(), const ReaderSettings().toJson());
      final r = ReaderSettings.decode('{"fontSize": 500, "lineSpacing": 10, "tapLayout": "nope"}');
      expect(r.fontSize, ReaderSettings.maxFontSize);
      expect(r.lineSpacing, ReaderSettings.minLineSpacing);
      expect(r.tapLayout, TapLayout.koreader);
    });

    test('layoutDiffers ignores theme and footer', () {
      const s = ReaderSettings();
      expect(s.layoutDiffers(s.copyWith(themeId: 'dark', showFooter: false)), isFalse);
      expect(s.layoutDiffers(s.copyWith(fontSize: 21)), isTrue);
      expect(s.layoutDiffers(s.copyWith(hyphenation: false)), isTrue);
    });
  });

  group('chapters', () {
    const toc = [
      TocEntry(title: 'One', xpointer: '/a', page: 3, depth: 1),
      TocEntry(title: 'One.1', xpointer: '/b', page: 5, depth: 2),
      TocEntry(title: 'Two', xpointer: '/c', page: 10, depth: 1),
    ];

    test('chapter at page', () {
      expect(chapterIndexAt(toc, 1), -1);
      expect(chapterIndexAt(toc, 3), 0);
      expect(chapterIndexAt(toc, 7), 1);
      expect(chapterIndexAt(toc, 50), 2);
    });

    test('pages left in chapter', () {
      expect(pagesLeftInChapter(toc, 5, 20), 4); // pages 6..9
      expect(pagesLeftInChapter(toc, 9, 20), 0);
      expect(pagesLeftInChapter(toc, 18, 20), 2); // last chapter: 19, 20
    });

    test('next and previous chapter', () {
      expect(nextChapterPage(toc, 4), 5);
      expect(nextChapterPage(toc, 10), isNull);
      expect(previousChapterPage(toc, 7), 5);
      expect(previousChapterPage(toc, 5), 3);
      expect(previousChapterPage(toc, 2), isNull);
    });

    test('reading speed needs three samples and skips breaks', () {
      final s = ReadingSpeed();
      var t = DateTime(2026);
      s.pageTurned(t);
      for (var i = 0; i < 3; i++) {
        t = t.add(const Duration(seconds: 30));
        s.pageTurned(t);
      }
      t = t.add(const Duration(hours: 1)); // a break, ignored
      s.pageTurned(t);
      expect(s.perPage, const Duration(seconds: 30));
      expect(s.timeFor(4), const Duration(minutes: 2));
    });
  });

  group('go to input', () {
    test('page and percent', () {
      expect(parseGotoInput('12', 100)?.page, 12);
      expect(parseGotoInput(' 50% ', 100)?.fraction, 0.5);
      expect(parseGotoInput('0', 100), isNull);
      expect(parseGotoInput('101', 100), isNull);
      expect(parseGotoInput('150%', 100), isNull);
      expect(parseGotoInput('abc', 100), isNull);
    });
  });

  test('dark theme matrix maps white to background and black to text', () {
    final t = readerThemeById('dark');
    final m = t.darkMatrix;
    double apply(int row, double v) => m[row * 5] * v + m[row * 5 + 1] * v + m[row * 5 + 2] * v + m[row * 5 + 4];
    expect(apply(0, 255).round(), 0x2C); // background red
    expect(apply(1, 255).round(), 0x2F);
    expect(apply(2, 255).round(), 0x31);
    expect(apply(0, 0).round(), 255); // text white
  });
}
