// Reading settings. They are global (Koodo style) and apply to every book.
// Sizes are logical pixels; the reader scales them to physical pixels.
import 'dart:convert';

import 'tap_zones.dart';

/// Items of the status line under the page (KOReader footer).
enum FooterItem {
  pageNumber('Page number'),
  percent('Progress percent'),
  chapterPagesLeft('Pages left in chapter'),
  chapterTimeLeft('Time left in chapter'),
  chapterTitle('Chapter title'),
  clock('Clock'),
  battery('Battery');

  const FooterItem(this.label);

  final String label;
}

class ReaderSettings {
  const ReaderSettings({
    this.fontFace = 'Noto Serif',
    this.fontSize = 20,
    this.lineSpacing = 100,
    this.marginHorizontal = 12,
    this.marginVertical = 12,
    this.hyphenation = true,
    this.embeddedStyles = true,
    this.embeddedFonts = true,
    this.themeId = 'white',
    this.accentId = 'blue',
    this.tapLayout = TapLayout.koreader,
    this.showFooter = true,
    this.footerItems = const {FooterItem.clock, FooterItem.pageNumber, FooterItem.chapterPagesLeft},
    this.brightness,
    this.screenTimeoutMinutes = 0,
  });

  final String fontFace;
  final double fontSize;

  /// crengine interline space, percent (KOReader line spacing).
  final int lineSpacing;
  final double marginHorizontal;
  final double marginVertical;
  final bool hyphenation;
  final bool embeddedStyles;
  final bool embeddedFonts;
  final String themeId;
  final String accentId;
  final TapLayout tapLayout;
  final bool showFooter;
  final Set<FooterItem> footerItems;

  /// Reader screen brightness 0 to 1, or null for the system brightness.
  final double? brightness;

  /// Keep the screen on for this many minutes after the last page turn.
  /// 0 leaves the screen timeout to the system (no wake lock).
  final int screenTimeoutMinutes;

  static const double minFontSize = 10;
  static const double maxFontSize = 48;
  static const int minLineSpacing = 70;
  static const int maxLineSpacing = 200;
  static const double maxMargin = 60;

  ReaderSettings copyWith({
    String? fontFace,
    double? fontSize,
    int? lineSpacing,
    double? marginHorizontal,
    double? marginVertical,
    bool? hyphenation,
    bool? embeddedStyles,
    bool? embeddedFonts,
    String? themeId,
    String? accentId,
    TapLayout? tapLayout,
    bool? showFooter,
    Set<FooterItem>? footerItems,
    double? Function()? brightness,
    int? screenTimeoutMinutes,
  }) => ReaderSettings(
    fontFace: fontFace ?? this.fontFace,
    fontSize: fontSize ?? this.fontSize,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    marginHorizontal: marginHorizontal ?? this.marginHorizontal,
    marginVertical: marginVertical ?? this.marginVertical,
    hyphenation: hyphenation ?? this.hyphenation,
    embeddedStyles: embeddedStyles ?? this.embeddedStyles,
    embeddedFonts: embeddedFonts ?? this.embeddedFonts,
    themeId: themeId ?? this.themeId,
    accentId: accentId ?? this.accentId,
    tapLayout: tapLayout ?? this.tapLayout,
    showFooter: showFooter ?? this.showFooter,
    footerItems: footerItems ?? this.footerItems,
    brightness: brightness != null ? brightness() : this.brightness,
    screenTimeoutMinutes: screenTimeoutMinutes ?? this.screenTimeoutMinutes,
  );

  /// True when [other] needs a new engine layout (not only a redraw).
  bool layoutDiffers(ReaderSettings other) =>
      fontFace != other.fontFace ||
      fontSize != other.fontSize ||
      lineSpacing != other.lineSpacing ||
      marginHorizontal != other.marginHorizontal ||
      marginVertical != other.marginVertical ||
      hyphenation != other.hyphenation ||
      embeddedStyles != other.embeddedStyles ||
      embeddedFonts != other.embeddedFonts;

  Map<String, Object?> toJson() => {
    'fontFace': fontFace,
    'fontSize': fontSize,
    'lineSpacing': lineSpacing,
    'marginHorizontal': marginHorizontal,
    'marginVertical': marginVertical,
    'hyphenation': hyphenation,
    'embeddedStyles': embeddedStyles,
    'embeddedFonts': embeddedFonts,
    'themeId': themeId,
    'accentId': accentId,
    'tapLayout': tapLayout.name,
    'showFooter': showFooter,
    'footerItems': [
      for (final i in FooterItem.values)
        if (footerItems.contains(i)) i.name,
    ],
    'brightness': brightness,
    'screenTimeoutMinutes': screenTimeoutMinutes,
  };

  /// Reads settings. Missing or bad values fall back to the defaults.
  factory ReaderSettings.fromJson(Map<String, Object?> j) {
    const d = ReaderSettings();
    T pick<T>(String key, T fallback) {
      final v = j[key];
      return v is T ? v : fallback;
    }

    double dbl(String key, double fallback) {
      final v = j[key];
      return v is num ? v.toDouble() : fallback;
    }

    final items = j['footerItems'];
    return ReaderSettings(
      fontFace: pick('fontFace', d.fontFace),
      fontSize: dbl('fontSize', d.fontSize).clamp(minFontSize, maxFontSize),
      lineSpacing: pick<int>('lineSpacing', d.lineSpacing).clamp(minLineSpacing, maxLineSpacing),
      marginHorizontal: dbl('marginHorizontal', d.marginHorizontal).clamp(0, maxMargin),
      marginVertical: dbl('marginVertical', d.marginVertical).clamp(0, maxMargin),
      hyphenation: pick('hyphenation', d.hyphenation),
      embeddedStyles: pick('embeddedStyles', d.embeddedStyles),
      embeddedFonts: pick('embeddedFonts', d.embeddedFonts),
      themeId: pick('themeId', d.themeId),
      accentId: pick('accentId', d.accentId),
      tapLayout: TapLayout.byName(j['tapLayout'] as String?),
      showFooter: pick('showFooter', d.showFooter),
      footerItems: items is List
          ? {
              for (final n in items.whereType<String>())
                for (final i in FooterItem.values)
                  if (i.name == n) i,
            }
          : d.footerItems,
      brightness: j['brightness'] is num ? (j['brightness'] as num).toDouble().clamp(0.0, 1.0) : null,
      screenTimeoutMinutes: pick<int>('screenTimeoutMinutes', 0).clamp(0, 24 * 60),
    );
  }

  String encode() => jsonEncode(toJson());

  static ReaderSettings decode(String? text) {
    if (text == null) return const ReaderSettings();
    try {
      final j = jsonDecode(text);
      return j is Map<String, Object?> ? ReaderSettings.fromJson(j) : const ReaderSettings();
    } on FormatException {
      return const ReaderSettings();
    }
  }
}
