// Advanced settings. They are apart from the quick reading settings panel.
//
// - AdvancedSettings: common, for every book (library menu: Advanced).
// - BookSettings: for one book (reader menu: Advanced for this book).
//
// Each setting is in one of the two places only. Values and defaults are
// those of KOReader (creoptions.lua, defaults.lua, readertypography.lua).
import 'dart:convert';

/// Text alignment style tweak.
enum TweakAlign {
  publisher('Publisher'),
  justify('Justify'),
  left('Left');

  const TweakAlign(this.label);

  final String label;
}

/// First-line indent style tweak.
enum TweakIndent {
  publisher('Publisher'),
  indent('Indent'),
  none('None');

  const TweakIndent(this.label);

  final String label;
}

/// Space between paragraphs style tweak.
enum TweakSpacing {
  publisher('Publisher'),
  none('None'),
  half('Half'),
  full('Full');

  const TweakSpacing(this.label);

  final String label;
}

/// KOReader word spacing presets (DCREREADER_CONFIG_WORD_SPACING_*): the
/// width of a space in percent of the font's space, and how far the engine
/// can make it smaller to fit a line.
enum WordSpacing {
  small('Small', 75, 50),
  medium('Medium', 95, 75),
  large('Large', 100, 90);

  const WordSpacing(this.label, this.widthPercent, this.condensingPercent);

  final String label;
  final int widthPercent;
  final int condensingPercent;
}

/// KOReader word expansion presets (DCREREADER_CONFIG_WORD_EXPANSION_*):
/// the most letter spacing, in percent of the font size, that the engine
/// can add to justify a line.
enum WordExpansion {
  none('None', 0),
  some('Some', 5),
  more('More', 15);

  const WordExpansion(this.label, this.percent);

  final String label;
  final int percent;
}

/// KOReader font weight steps: a change from the regular weight 400 in
/// units of 100.
const List<double> kFontWeightSteps = [-1, -0.5, 0, 0.5, 1, 1.5, 3];

/// KOReader contrast steps: indexes into the crengine gamma table.
const List<int> kFontGammaSteps = [10, 15, 25, 30, 36, 43, 49, 56];

/// The gamma values of [kFontGammaSteps] (KOReader creoptions.lua labels).
const List<double> kFontGammaLabels = [0.8, 1.0, 1.45, 1.90, 2.50, 4.0, 8.0, 15.0];

/// Gamma index for gamma 1.0: no contrast change.
const int kDefaultFontGamma = 15;

T _byName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Common advanced settings. They apply to every book.
class AdvancedSettings {
  const AdvancedSettings({
    this.fontWeight = 0,
    this.fontGamma = kDefaultFontGamma,
    this.wordSpacing = WordSpacing.medium,
    this.wordExpansion = WordExpansion.none,
    this.hangingPunctuation = false,
    this.trustSoftHyphens = false,
    this.alignment = TweakAlign.publisher,
    this.indent = TweakIndent.publisher,
    this.paragraphSpacing = TweakSpacing.publisher,
    this.avoidWidowsOrphans = false,
    this.avoidBlankPages = false,
    this.inPageFootnotes = false,
  });

  /// One of [kFontWeightSteps].
  final double fontWeight;

  /// One of [kFontGammaSteps].
  final int fontGamma;
  final WordSpacing wordSpacing;
  final WordExpansion wordExpansion;
  final bool hangingPunctuation;
  final bool trustSoftHyphens;
  final TweakAlign alignment;
  final TweakIndent indent;
  final TweakSpacing paragraphSpacing;
  final bool avoidWidowsOrphans;

  /// No new page at a chapter start and at a file end in the book.
  final bool avoidBlankPages;

  /// Footnote text at the bottom of the page that has the link to it.
  final bool inPageFootnotes;

  AdvancedSettings copyWith({
    double? fontWeight,
    int? fontGamma,
    WordSpacing? wordSpacing,
    WordExpansion? wordExpansion,
    bool? hangingPunctuation,
    bool? trustSoftHyphens,
    TweakAlign? alignment,
    TweakIndent? indent,
    TweakSpacing? paragraphSpacing,
    bool? avoidWidowsOrphans,
    bool? avoidBlankPages,
    bool? inPageFootnotes,
  }) => AdvancedSettings(
    fontWeight: fontWeight ?? this.fontWeight,
    fontGamma: fontGamma ?? this.fontGamma,
    wordSpacing: wordSpacing ?? this.wordSpacing,
    wordExpansion: wordExpansion ?? this.wordExpansion,
    hangingPunctuation: hangingPunctuation ?? this.hangingPunctuation,
    trustSoftHyphens: trustSoftHyphens ?? this.trustSoftHyphens,
    alignment: alignment ?? this.alignment,
    indent: indent ?? this.indent,
    paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
    avoidWidowsOrphans: avoidWidowsOrphans ?? this.avoidWidowsOrphans,
    avoidBlankPages: avoidBlankPages ?? this.avoidBlankPages,
    inPageFootnotes: inPageFootnotes ?? this.inPageFootnotes,
  );

  /// Engine properties for these settings, with the names that KOReader
  /// credocument.lua uses. All are set at each layout, so the defaults here
  /// (the KOReader defaults) replace the crengine defaults.
  Map<String, int> engineProps() => {
    // KOReader setFontBaseWeight(): 0, 1, -0.5 give 400, 500, 350.
    'font.face.base.weight': (400 + fontWeight * 100).floor(),
    'crengine.style.space.width.scale.percent': wordSpacing.widthPercent,
    'crengine.style.space.condensing.percent': wordSpacing.condensingPercent,
    'crengine.style.max.added.letter.spacing.percent': wordExpansion.percent,
    'crengine.style.floating.punctuation.enabled': hangingPunctuation ? 1 : 0,
    'crengine.hyphenation.trust.soft.hyphens': trustSoftHyphens ? 1 : 0,
  };

  /// True when [other] needs a new engine layout. A contrast change alone
  /// needs only a redraw.
  bool layoutDiffers(AdvancedSettings other) => copyWith(fontGamma: other.fontGamma) != other;

  Map<String, Object?> toJson() => {
    'fontWeight': fontWeight,
    'fontGamma': fontGamma,
    'wordSpacing': wordSpacing.name,
    'wordExpansion': wordExpansion.name,
    'hangingPunctuation': hangingPunctuation,
    'trustSoftHyphens': trustSoftHyphens,
    'alignment': alignment.name,
    'indent': indent.name,
    'paragraphSpacing': paragraphSpacing.name,
    'avoidWidowsOrphans': avoidWidowsOrphans,
    'avoidBlankPages': avoidBlankPages,
    'inPageFootnotes': inPageFootnotes,
  };

  /// Reads settings. Missing or bad values fall back to the defaults.
  factory AdvancedSettings.fromJson(Map<String, Object?> j) {
    const d = AdvancedSettings();
    bool flag(String key, bool fallback) => j[key] is bool ? j[key]! as bool : fallback;
    final weight = j['fontWeight'];
    final gamma = j['fontGamma'];
    return AdvancedSettings(
      fontWeight: weight is num && kFontWeightSteps.contains(weight.toDouble()) ? weight.toDouble() : d.fontWeight,
      fontGamma: gamma is int && kFontGammaSteps.contains(gamma) ? gamma : d.fontGamma,
      wordSpacing: _byName(WordSpacing.values, j['wordSpacing'], d.wordSpacing),
      wordExpansion: _byName(WordExpansion.values, j['wordExpansion'], d.wordExpansion),
      hangingPunctuation: flag('hangingPunctuation', d.hangingPunctuation),
      trustSoftHyphens: flag('trustSoftHyphens', d.trustSoftHyphens),
      alignment: _byName(TweakAlign.values, j['alignment'], d.alignment),
      indent: _byName(TweakIndent.values, j['indent'], d.indent),
      paragraphSpacing: _byName(TweakSpacing.values, j['paragraphSpacing'], d.paragraphSpacing),
      avoidWidowsOrphans: flag('avoidWidowsOrphans', d.avoidWidowsOrphans),
      avoidBlankPages: flag('avoidBlankPages', d.avoidBlankPages),
      inPageFootnotes: flag('inPageFootnotes', d.inPageFootnotes),
    );
  }

  String encode() => jsonEncode(toJson());

  static AdvancedSettings decode(String? text) {
    if (text == null) return const AdvancedSettings();
    try {
      final j = jsonDecode(text);
      return j is Map<String, Object?> ? AdvancedSettings.fromJson(j) : const AdvancedSettings();
    } on FormatException {
      return const AdvancedSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AdvancedSettings &&
      fontWeight == other.fontWeight &&
      fontGamma == other.fontGamma &&
      wordSpacing == other.wordSpacing &&
      wordExpansion == other.wordExpansion &&
      hangingPunctuation == other.hangingPunctuation &&
      trustSoftHyphens == other.trustSoftHyphens &&
      alignment == other.alignment &&
      indent == other.indent &&
      paragraphSpacing == other.paragraphSpacing &&
      avoidWidowsOrphans == other.avoidWidowsOrphans &&
      avoidBlankPages == other.avoidBlankPages &&
      inPageFootnotes == other.inPageFootnotes;

  @override
  int get hashCode => Object.hash(
    fontWeight,
    fontGamma,
    wordSpacing,
    wordExpansion,
    hangingPunctuation,
    trustSoftHyphens,
    alignment,
    indent,
    paragraphSpacing,
    avoidWidowsOrphans,
    avoidBlankPages,
    inPageFootnotes,
  );
}

/// Advanced settings of one book. They are stored with the book.
class BookSettings {
  const BookSettings({
    this.language,
    this.ignoreMargins = false,
    this.ignoreFontSizes = false,
    this.ignoreFontFamilies = false,
    this.ignoreLineHeights = false,
    this.customCss = '',
  });

  /// Language tag for hyphenation, or null to use the language of the book.
  final String? language;
  final bool ignoreMargins;
  final bool ignoreFontSizes;
  final bool ignoreFontFamilies;
  final bool ignoreLineHeights;

  /// CSS that the engine applies after all other styles.
  final String customCss;

  bool get isDefault => this == const BookSettings();

  BookSettings copyWith({
    String? Function()? language,
    bool? ignoreMargins,
    bool? ignoreFontSizes,
    bool? ignoreFontFamilies,
    bool? ignoreLineHeights,
    String? customCss,
  }) => BookSettings(
    language: language != null ? language() : this.language,
    ignoreMargins: ignoreMargins ?? this.ignoreMargins,
    ignoreFontSizes: ignoreFontSizes ?? this.ignoreFontSizes,
    ignoreFontFamilies: ignoreFontFamilies ?? this.ignoreFontFamilies,
    ignoreLineHeights: ignoreLineHeights ?? this.ignoreLineHeights,
    customCss: customCss ?? this.customCss,
  );

  Map<String, Object?> toJson() => {
    'language': language,
    'ignoreMargins': ignoreMargins,
    'ignoreFontSizes': ignoreFontSizes,
    'ignoreFontFamilies': ignoreFontFamilies,
    'ignoreLineHeights': ignoreLineHeights,
    'customCss': customCss,
  };

  factory BookSettings.fromJson(Map<String, Object?> j) {
    bool flag(String key) => j[key] == true;
    final language = j['language'];
    final css = j['customCss'];
    return BookSettings(
      language: language is String && language.trim().isNotEmpty ? language.trim() : null,
      ignoreMargins: flag('ignoreMargins'),
      ignoreFontSizes: flag('ignoreFontSizes'),
      ignoreFontFamilies: flag('ignoreFontFamilies'),
      ignoreLineHeights: flag('ignoreLineHeights'),
      customCss: css is String ? css : '',
    );
  }

  /// JSON text for the database, or null when all values are the defaults.
  String? encode() => isDefault ? null : jsonEncode(toJson());

  static BookSettings decode(String? text) {
    if (text == null || text.isEmpty) return const BookSettings();
    try {
      final j = jsonDecode(text);
      return j is Map<String, Object?> ? BookSettings.fromJson(j) : const BookSettings();
    } on FormatException {
      return const BookSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BookSettings &&
      language == other.language &&
      ignoreMargins == other.ignoreMargins &&
      ignoreFontSizes == other.ignoreFontSizes &&
      ignoreFontFamilies == other.ignoreFontFamilies &&
      ignoreLineHeights == other.ignoreLineHeights &&
      customCss == other.customCss;

  @override
  int get hashCode =>
      Object.hash(language, ignoreMargins, ignoreFontSizes, ignoreFontFamilies, ignoreLineHeights, customCss);
}
