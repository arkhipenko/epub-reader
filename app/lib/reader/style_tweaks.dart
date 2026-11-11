// Style tweaks: CSS that the engine applies after the base style sheet
// (epub.css or fb2.css) and that can override the styles of the book.
//
// The rules, ids and priorities are those of KOReader css_tweaks.lua. The
// order of the result is that of KOReader readerstyletweak.lua: a lower
// priority comes first, then the id order. The CSS of the book comes last.
// A steady order matters: the engine compares the style sheet text to
// decide whether its cache of the book is still valid.
import 'advanced_settings.dart';

class StyleTweak {
  const StyleTweak(this.id, this.css, {this.priority = 0});

  final String id;
  final String css;

  /// A higher number comes later in the CSS, so it wins.
  final int priority;
}

const _alignJustify = StyleTweak('text_align_most_justify', '''
body, p, li { text-align: justify !important; }
pre {
    -cr-only-if: txt-document;
        text-align: justify !important;
        white-space: normal;
}''');

const _alignLeft = StyleTweak('text_align_most_left', 'body, p, li { text-align: left !important; }', priority: 2);

const _indent = StyleTweak('paragraph_indent', '''
p { text-indent: 1.2em !important; }
body, h1, h2, h3, h4, h5, h6, div, li, td, th { text-indent: 0 !important; }''');

const _noIndent = StyleTweak('paragraph_no_indent', 'p { text-indent: 0 !important; }');

const _spacingNone = StyleTweak(
  'paragraph_no_whitespace',
  'p { margin-top: 0 !important; margin-bottom: 0 !important; }',
  priority: 5,
);

const _spacingHalf = StyleTweak('paragraph_whitespace_half', 'p + p { margin-top: .5em !important; }', priority: 5);

const _spacingFull = StyleTweak('paragraph_whitespace', 'p + p { margin-top: 1em !important; }', priority: 5);

const _widowsOrphans = StyleTweak('widows_orphans_avoid', '''
body { orphans: 2; widows: 2; }
DocFragment {
    orphans: 2 !important;
    widows:  2 !important;
}''', priority: 2);

// The two KOReader ids end with a space.
const _noBreakAtTitles = StyleTweak(
  'titles_page-break-before_avoid ',
  'h1, h2, h3 { page-break-before: auto !important; }',
  priority: 2,
);

const _noBreakAtFragments = StyleTweak(
  'docfragment_page-break-before_avoid ',
  'DocFragment { page-break-before: auto !important; }',
  priority: 2,
);

// The three tweaks that a new KOReader install has on
// (DEFAULT_GLOBAL_STYLE_TWEAKS).
const _footnotesFb2 = StyleTweak('footnote-inpage_fb2', '''
body[name="notes"] section {
    -cr-only-if: fb2-document;
        -cr-hint: footnote-inpage;
        margin: 0 !important;
}
body[name="notes"] > section {
    -cr-only-if: fb2-document;
        font-size: 0.75urem;
}
body[name="notes"] > title {
    -cr-only-if: fb2-document;
        margin-bottom: 0;
        padding-bottom: 0.5em;
}''');

const _footnotesEpub = StyleTweak('footnote-inpage_epub', '''
*[type~="note"],
*[type~="endnote"],
*[type~="footnote"],
*[type~="rearnote"],
*[role~="doc-note"],
*[role~="doc-endnote"],
*[role~="doc-footnote"],
*[role~="doc-rearnote"]
{
    -cr-only-if: -fb2-document;
        -cr-hint: footnote-inpage;
        margin: 0 !important;
}''');

const _footnotesSmaller = StyleTweak('inpage_footnote_font-size_smaller', '''
*, autoBoxing {
    -cr-hint: late;
    -cr-only-if: -fb2-document inpage-footnote;
        font-size: 0.8urem !important;
}''');

const _ignoreMargins = StyleTweak('margin_body_0', 'body { margin: 0 !important; }');

const _ignoreFontSizes = StyleTweak('font_size_all_inherit', '* { font-size: inherit !important; }', priority: -1);

const _ignoreFontFamilies = StyleTweak('font_family_all_inherit', '''
* { font-family: inherit !important; }
listing, plaintext, xmp, samp, tt, kbd, pre, code { font-family: monospace !important; }''');

const _ignoreLineHeights = StyleTweak('lineheight_all_inherit', '* { line-height: inherit !important; }');

/// The tweaks that the settings turn on, in the order of the CSS text.
List<StyleTweak> activeStyleTweaks(AdvancedSettings common, BookSettings book) {
  final tweaks = <StyleTweak?>[
    switch (common.alignment) {
      TweakAlign.justify => _alignJustify,
      TweakAlign.left => _alignLeft,
      TweakAlign.publisher => null,
    },
    switch (common.indent) {
      TweakIndent.indent => _indent,
      TweakIndent.none => _noIndent,
      TweakIndent.publisher => null,
    },
    switch (common.paragraphSpacing) {
      TweakSpacing.none => _spacingNone,
      TweakSpacing.half => _spacingHalf,
      TweakSpacing.full => _spacingFull,
      TweakSpacing.publisher => null,
    },
    if (common.avoidWidowsOrphans) _widowsOrphans,
    if (common.avoidBlankPages) ...[_noBreakAtTitles, _noBreakAtFragments],
    if (common.inPageFootnotes) ...[_footnotesFb2, _footnotesEpub, _footnotesSmaller],
    if (book.ignoreMargins) _ignoreMargins,
    if (book.ignoreFontSizes) _ignoreFontSizes,
    if (book.ignoreFontFamilies) _ignoreFontFamilies,
    if (book.ignoreLineHeights) _ignoreLineHeights,
  ].nonNulls.toList();
  tweaks.sort((l, r) => l.priority != r.priority ? l.priority.compareTo(r.priority) : l.id.compareTo(r.id));
  return tweaks;
}

/// The CSS text for the engine: the active tweaks, then the CSS of the book.
/// Empty when no tweak is on.
String buildTweakCss(AdvancedSettings common, BookSettings book) {
  final custom = book.customCss.trim();
  return [for (final t in activeStyleTweaks(common, book)) t.css.trim(), if (custom.isNotEmpty) custom].join('\n');
}
