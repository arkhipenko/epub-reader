import 'package:epub_reader/engine/text_language.dart';
import 'package:epub_reader/reader/advanced_settings.dart';
import 'package:epub_reader/reader/style_tweaks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdvancedSettings', () {
    test('defaults are the KOReader defaults', () {
      expect(const AdvancedSettings().engineProps(), {
        'font.face.base.weight': 400,
        'crengine.style.space.width.scale.percent': 95,
        'crengine.style.space.condensing.percent': 75,
        'crengine.style.max.added.letter.spacing.percent': 0,
        'crengine.style.floating.punctuation.enabled': 0,
        'crengine.hyphenation.trust.soft.hyphens': 0,
      });
      expect(const AdvancedSettings().fontGamma, 15);
    });

    test('font weight follows KOReader setFontBaseWeight', () {
      int weight(double w) => AdvancedSettings(fontWeight: w).engineProps()['font.face.base.weight']!;
      expect([for (final w in kFontWeightSteps) weight(w)], [300, 350, 400, 450, 500, 550, 700]);
    });

    test('word spacing and expansion presets', () {
      final p = const AdvancedSettings(wordSpacing: WordSpacing.small, wordExpansion: WordExpansion.more).engineProps();
      expect(p['crengine.style.space.width.scale.percent'], 75);
      expect(p['crengine.style.space.condensing.percent'], 50);
      expect(p['crengine.style.max.added.letter.spacing.percent'], 15);
    });

    test('JSON round trip keeps all values', () {
      const s = AdvancedSettings(
        fontWeight: 1.5,
        fontGamma: 30,
        wordSpacing: WordSpacing.large,
        wordExpansion: WordExpansion.some,
        hangingPunctuation: true,
        trustSoftHyphens: true,
        alignment: TweakAlign.justify,
        indent: TweakIndent.none,
        paragraphSpacing: TweakSpacing.half,
        avoidWidowsOrphans: true,
        avoidBlankPages: true,
        inPageFootnotes: true,
      );
      expect(AdvancedSettings.decode(s.encode()), s);
    });

    test('bad or missing values fall back to the defaults', () {
      expect(AdvancedSettings.decode(null), const AdvancedSettings());
      expect(AdvancedSettings.decode('not json'), const AdvancedSettings());
      expect(AdvancedSettings.decode('[1]'), const AdvancedSettings());
      final s = AdvancedSettings.decode('{"fontWeight":0.7,"fontGamma":16,"wordSpacing":"huge","alignment":3}');
      expect(s, const AdvancedSettings());
    });

    test('a contrast change alone needs no new layout', () {
      const a = AdvancedSettings();
      expect(a.layoutDiffers(a.copyWith(fontGamma: 30)), isFalse);
      expect(a.layoutDiffers(a.copyWith(fontWeight: 1)), isTrue);
      expect(a.layoutDiffers(a.copyWith(inPageFootnotes: true)), isTrue);
      expect(a.layoutDiffers(a.copyWith(fontGamma: 30, alignment: TweakAlign.left)), isTrue);
    });
  });

  group('BookSettings', () {
    test('defaults are stored as null', () {
      expect(const BookSettings().encode(), isNull);
      expect(BookSettings.decode(null).isDefault, isTrue);
      expect(BookSettings.decode('').isDefault, isTrue);
      expect(BookSettings.decode('{').isDefault, isTrue);
    });

    test('JSON round trip keeps all values', () {
      const s = BookSettings(
        language: 'ru',
        ignoreMargins: true,
        ignoreFontSizes: true,
        ignoreFontFamilies: true,
        ignoreLineHeights: true,
        customCss: 'p { color: red; }',
      );
      expect(BookSettings.decode(s.encode()), s);
    });

    test('the language can be cleared', () {
      const s = BookSettings(language: 'ru', ignoreMargins: true);
      final cleared = s.copyWith(language: () => null);
      expect(cleared.language, isNull);
      expect(cleared.ignoreMargins, isTrue);
      expect(s.copyWith(ignoreMargins: false).language, 'ru');
    });
  });

  group('style tweaks', () {
    List<String> ids(AdvancedSettings a, [BookSettings b = const BookSettings()]) => [
      for (final t in activeStyleTweaks(a, b)) t.id,
    ];

    test('no tweak and no CSS with the defaults', () {
      expect(ids(const AdvancedSettings()), isEmpty);
      expect(buildTweakCss(const AdvancedSettings(), const BookSettings()), '');
    });

    test('each choice gives its KOReader tweak', () {
      expect(ids(const AdvancedSettings(alignment: TweakAlign.justify)), ['text_align_most_justify']);
      expect(ids(const AdvancedSettings(alignment: TweakAlign.left)), ['text_align_most_left']);
      expect(ids(const AdvancedSettings(indent: TweakIndent.indent)), ['paragraph_indent']);
      expect(ids(const AdvancedSettings(indent: TweakIndent.none)), ['paragraph_no_indent']);
      expect(ids(const AdvancedSettings(paragraphSpacing: TweakSpacing.none)), ['paragraph_no_whitespace']);
      expect(ids(const AdvancedSettings(paragraphSpacing: TweakSpacing.half)), ['paragraph_whitespace_half']);
      expect(ids(const AdvancedSettings(paragraphSpacing: TweakSpacing.full)), ['paragraph_whitespace']);
      expect(ids(const AdvancedSettings(avoidWidowsOrphans: true)), ['widows_orphans_avoid']);
      expect(ids(const AdvancedSettings(avoidBlankPages: true)), [
        'docfragment_page-break-before_avoid ',
        'titles_page-break-before_avoid ',
      ]);
      // The three tweaks that a new KOReader install has on.
      expect(ids(const AdvancedSettings(inPageFootnotes: true)), [
        'footnote-inpage_epub',
        'footnote-inpage_fb2',
        'inpage_footnote_font-size_smaller',
      ]);
    });

    test('order: lower priority first, then by id; the CSS of the book is last', () {
      const a = AdvancedSettings(
        alignment: TweakAlign.left,
        indent: TweakIndent.indent,
        paragraphSpacing: TweakSpacing.full,
        inPageFootnotes: true,
      );
      const b = BookSettings(ignoreFontSizes: true, ignoreMargins: true, customCss: '  h1 { color: red; }\n');
      expect(ids(a, b), [
        'font_size_all_inherit', // priority -1
        'footnote-inpage_epub',
        'footnote-inpage_fb2',
        'inpage_footnote_font-size_smaller',
        'margin_body_0',
        'paragraph_indent',
        'text_align_most_left', // priority 2
        'paragraph_whitespace', // priority 5
      ]);
      final css = buildTweakCss(a, b);
      expect(css, startsWith('* { font-size: inherit !important; }\n'));
      expect(css, endsWith('p + p { margin-top: 1em !important; }\nh1 { color: red; }'));
      // The text is the same each time: the engine cache depends on it.
      expect(buildTweakCss(a, b), css);
    });

    test('book switches give their KOReader tweaks', () {
      const b = BookSettings(
        ignoreMargins: true,
        ignoreFontSizes: true,
        ignoreFontFamilies: true,
        ignoreLineHeights: true,
      );
      expect(ids(const AdvancedSettings(), b), [
        'font_size_all_inherit',
        'font_family_all_inherit',
        'lineheight_all_inherit',
        'margin_body_0',
      ]);
      expect(buildTweakCss(const AdvancedSettings(), b), contains('body { margin: 0 !important; }'));
    });
  });

  group('text language', () {
    test('no tag gives null', () {
      expect(fixLanguageTag(null), isNull);
      expect(fixLanguageTag(''), isNull);
      expect(fixLanguageTag('  '), isNull);
    });

    test('an alias changes to its tag', () {
      expect(fixLanguageTag('en'), 'en-US');
      expect(fixLanguageTag('eng'), 'en-US');
      expect(fixLanguageTag('rus'), 'ru');
      expect(fixLanguageTag('zh'), 'zh-CN');
      expect(fixLanguageTag(' fra '), 'fr');
    });

    test('other tags are kept', () {
      expect(fixLanguageTag('ru'), 'ru');
      expect(fixLanguageTag('en-GB'), 'en-GB');
      expect(fixLanguageTag('ru-RU'), 'ru-RU');
      expect(fixLanguageTag('xx'), 'xx');
    });

    test('labels', () {
      expect(languageLabel('ru'), 'Russian (ru)');
      expect(languageLabel('en-US'), 'English (US) (en-US)');
      expect(languageLabel('xx'), 'xx');
    });

    test('tags and aliases are unique', () {
      final tags = [for (final l in kTextLanguages) l.tag];
      expect(tags.toSet().length, tags.length);
      final aliases = [for (final l in kTextLanguages) ...l.aliases];
      expect(aliases.toSet().length, aliases.length);
      expect(aliases.toSet().intersection(tags.toSet()), isEmpty);
    });
  });
}
