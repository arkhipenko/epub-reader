// Highlight colors and styles, with the KOReader names
// (readerhighlight.lua highlight_colors, base/ffi/blitbuffer.lua
// HIGHLIGHT_COLORS). KOReader has no hex value for gray in that table;
// #9E9E9E is this app's choice.
import 'package:flutter/painting.dart';

const Map<String, Color> kHighlightColors = {
  'red': Color(0xFFFF3300),
  'orange': Color(0xFFFF8800),
  'yellow': Color(0xFFFFFF33),
  'green': Color(0xFF00AA66),
  'olive': Color(0xFF88FF77),
  'cyan': Color(0xFF00FFEE),
  'blue': Color(0xFF0066FF),
  'purple': Color(0xFFEE00FF),
  'gray': Color(0xFF9E9E9E),
};

Color highlightColor(String name) => kHighlightColors[name] ?? kHighlightColors['yellow']!;

/// KOReader drawers.
enum HighlightDrawer {
  lighten('Highlight'),
  underscore('Underline'),
  strikeout('Strikethrough'),
  invert('Invert');

  const HighlightDrawer(this.label);

  final String label;

  static HighlightDrawer byName(String? n) =>
      HighlightDrawer.values.firstWhere((d) => d.name == n, orElse: () => HighlightDrawer.lighten);
}
