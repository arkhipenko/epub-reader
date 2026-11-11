// Text languages for typography (hyphenation and line breaking rules).
//
// The table and the tag clean-up follow KOReader readertypography.lua
// (LANGUAGES and fixLangTag). The engine selects the hyphenation patterns
// from the language tag (crengine.textlang.main.lang).

/// A language the user can select: crengine language tag and display name.
class TextLanguage {
  const TextLanguage(this.tag, this.name, [this.aliases = const []]);

  final String tag;
  final String name;

  /// Tags that book metadata can hold for this language.
  final List<String> aliases;
}

/// The engine default (KOReader ReaderTypography.DEFAULT_LANG_TAG).
const String kDefaultTextLanguage = 'en-US';

/// KOReader LANGUAGES, in the same order.
const List<TextLanguage> kTextLanguages = [
  TextLanguage('hy', 'Armenian', ['arm', 'hye', 'hyw']),
  TextLanguage('as', 'Assamese', ['asm']),
  TextLanguage('eu', 'Basque'),
  TextLanguage('bn', 'Bengali', ['ben']),
  TextLanguage('bg', 'Bulgarian', ['bul']),
  TextLanguage('ca', 'Catalan', ['cat']),
  TextLanguage('zh-CN', 'Chinese (Simplified)', ['zh', 'zh-Hans']),
  TextLanguage('zh-TW', 'Chinese (Traditional)', ['zh-Hant']),
  TextLanguage('hr', 'Croatian'),
  TextLanguage('cs', 'Czech', ['ces']),
  TextLanguage('da', 'Danish', ['dan']),
  TextLanguage('nl', 'Dutch', ['nld']),
  TextLanguage('en-GB', 'English (UK)'),
  TextLanguage('en-US', 'English (US)', ['en', 'eng']),
  TextLanguage('eo', 'Esperanto', ['epo']),
  TextLanguage('et', 'Estonian', ['est']),
  TextLanguage('fi', 'Finnish', ['fin']),
  TextLanguage('fr', 'French', ['fra', 'fre']),
  TextLanguage('fur', 'Friulian'),
  TextLanguage('gl', 'Galician', ['glg']),
  TextLanguage('ka', 'Georgian'),
  TextLanguage('de', 'German', ['deu']),
  TextLanguage('el', 'Greek', ['ell']),
  TextLanguage('gu', 'Gujarati', ['guj']),
  TextLanguage('hi', 'Hindi', ['hin']),
  TextLanguage('hu', 'Hungarian', ['hun']),
  TextLanguage('is', 'Icelandic', ['isl']),
  TextLanguage('ga', 'Irish', ['gle']),
  TextLanguage('it', 'Italian', ['ita']),
  TextLanguage('ja', 'Japanese'),
  TextLanguage('kn', 'Kannada', ['kan']),
  TextLanguage('ko', 'Korean'),
  TextLanguage('la', 'Latin', ['lat']),
  TextLanguage('la-lit', 'Latin (liturgical)', ['lat-lit']),
  TextLanguage('lv', 'Latvian', ['lav']),
  TextLanguage('lt', 'Lithuanian', ['lit']),
  TextLanguage('mk', 'Macedonian'),
  TextLanguage('ml', 'Malayalam', ['mal']),
  TextLanguage('mr', 'Marathi', ['mar']),
  TextLanguage('ne', 'Nepali', ['nep']),
  TextLanguage('no', 'Norwegian', ['nor']),
  TextLanguage('oc', 'Occitan', ['oci']),
  TextLanguage('or', 'Odia', ['ori']),
  TextLanguage('pa-Guru', 'Punjabi (Gurmukhi)', ['pa', 'pan']),
  TextLanguage('pa-Arab', 'Punjabi (Shahmukhi)', ['pnb']),
  TextLanguage('pms', 'Piedmontese'),
  TextLanguage('pl', 'Polish', ['pol']),
  TextLanguage('pt', 'Portuguese', ['por']),
  TextLanguage('pt-BR', 'Portuguese (BR)'),
  TextLanguage('rm', 'Romansh', ['roh']),
  TextLanguage('ro', 'Romanian', ['ron']),
  TextLanguage('ru', 'Russian', ['rus']),
  TextLanguage('ru-GB', 'Russian + English (UK)'),
  TextLanguage('ru-US', 'Russian + English (US)'),
  TextLanguage('sa', 'Sanskrit', ['san']),
  TextLanguage('sr', 'Serbian', ['srp']),
  TextLanguage('sk', 'Slovak', ['slk']),
  TextLanguage('sl', 'Slovenian', ['slv']),
  TextLanguage('es', 'Spanish', ['spa']),
  TextLanguage('sv', 'Swedish', ['swe']),
  TextLanguage('ta', 'Tamil', ['tam']),
  TextLanguage('te', 'Telugu', ['tel']),
  TextLanguage('tr', 'Turkish', ['tur']),
  TextLanguage('uk', 'Ukrainian', ['ukr']),
  TextLanguage('cy', 'Welsh', ['cym']),
  TextLanguage('zu', 'Zulu', ['zul']),
];

final Map<String, String> _aliasToTag = {
  for (final l in kTextLanguages)
    for (final a in l.aliases) a: l.tag,
};

final Map<String, String> _tagToName = {for (final l in kTextLanguages) l.tag: l.name};

/// The language tag of a book as the engine wants it, or null when the book
/// gives none (KOReader fixLangTag).
///
/// A tag that is not in the table is kept: the engine and the fonts can know
/// more languages than the table. An alias changes to its tag ("en" to
/// "en-US", "rus" to "ru").
String? fixLanguageTag(String? tag) {
  final t = tag?.trim() ?? '';
  if (t.isEmpty) return null;
  return _aliasToTag[t] ?? t;
}

/// Display text for a language tag: "Russian (ru)", or the tag alone when
/// the table does not have it.
String languageLabel(String tag) {
  final name = _tagToName[tag];
  return name == null ? tag : '$name ($tag)';
}
