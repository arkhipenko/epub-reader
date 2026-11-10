// Reading themes and accent colors from Koodo Reader
// (src/constants/themeList.tsx: backgroundList, textList, themeList).
import 'package:flutter/painting.dart';

class ReaderTheme {
  const ReaderTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.text,
    required this.isDark,
  });

  final String id;
  final String name;
  final Color background;
  final Color text;

  /// Dark themes render a light page and invert it on screen, as KOReader
  /// night mode does. Images are pre-inverted by the engine, so they show
  /// with their real colors.
  final bool isDark;

  int get backgroundRgb => background.toARGB32() & 0xFFFFFF;
  int get textRgb => text.toARGB32() & 0xFFFFFF;

  /// Color matrix that maps a white page with black text to this theme:
  /// out = text - (text - background) * in, per channel.
  List<double> get darkMatrix {
    double ch(Color c, int shift) => ((c.toARGB32() >> shift) & 0xFF).toDouble();
    List<double> row(int shift, int index) {
      final fg = ch(text, shift);
      final bg = ch(background, shift);
      final r = List<double>.filled(5, 0);
      r[index] = -(fg - bg) / 255.0;
      r[4] = fg;
      return r;
    }

    return [...row(16, 0), ...row(8, 1), ...row(0, 2), 0, 0, 0, 1, 0];
  }
}

const List<ReaderTheme> kReaderThemes = [
  ReaderTheme(id: 'white', name: 'White', background: Color(0xFFFFFFFF), text: Color(0xFF000000), isDark: false),
  ReaderTheme(id: 'dark', name: 'Dark', background: Color(0xFF2C2F31), text: Color(0xFFFFFFFF), isDark: true),
  ReaderTheme(id: 'sepia', name: 'Sepia', background: Color(0xFFE9D8BC), text: Color(0xFF594429), isDark: false),
  ReaderTheme(id: 'green', name: 'Green', background: Color(0xFFC5E7CF), text: Color(0xFF36503E), isDark: false),
  // Not in Koodo: pure black, so OLED screens switch the background pixels
  // off. Light grey text is less harsh than white on black.
  ReaderTheme(id: 'black', name: 'Black (OLED)', background: Color(0xFF000000), text: Color(0xFFD0D0D0), isDark: true),
];

ReaderTheme readerThemeById(String id) =>
    kReaderThemes.firstWhere((t) => t.id == id, orElse: () => kReaderThemes.first);

class AccentColor {
  const AccentColor(this.id, this.name, this.color);

  final String id;
  final String name;
  final Color color;
}

/// Koodo accent colors. Koodo "Default" has no color; Blue stands in for it.
const List<AccentColor> kAccentColors = [
  AccentColor('blue', 'Blue', Color(0xFF0179CA)),
  AccentColor('green', 'Green', Color(0xFF008F91)),
  AccentColor('red', 'Red', Color(0xFFF16464)),
  AccentColor('purple', 'Purple', Color(0xFF6867D1)),
  AccentColor('orange', 'Orange', Color(0xFFF97316)),
  AccentColor('pink', 'Pink', Color(0xFFEC4899)),
  AccentColor('yellow', 'Yellow', Color(0xFFEAB308)),
  AccentColor('violet', 'Violet', Color(0xFF8B5CF6)),
  AccentColor('sky', 'Sky', Color(0xFF0EA5E9)),
  AccentColor('slate', 'Slate', Color(0xFF64748B)),
];

AccentColor accentById(String id) => kAccentColors.firstWhere((a) => a.id == id, orElse: () => kAccentColors.first);
