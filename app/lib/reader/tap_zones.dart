// Tap zones for page turns and menus.
//
// The KOReader layout follows koreader/defaults.lua:
//   DTAP_ZONE_MENU     = {x = 0, y = 0,   w = 1,   h = 1/8}
//   DTAP_ZONE_CONFIG   = {x = 0, y = 7/8, w = 1,   h = 1/8}
//   DTAP_ZONE_FORWARD  = {x = 1/4, y = 0, w = 3/4, h = 1}
//   DTAP_ZONE_BACKWARD = {x = 0, y = 0,   w = 1/4, h = 1}
// KOReader opens the main menu from the top zone and the settings from the
// bottom zone. This app shows its menu bars from both.
import 'dart:ui';

enum TapAction { previous, next, menu }

enum TapLayout {
  /// KOReader default: left quarter back, the rest forward, top and bottom menu.
  koreader('KOReader'),

  /// KOReader default, mirrored for the left hand: right quarter back.
  koreaderMirrored('KOReader, left hand'),

  /// Koodo style: left third back, right third forward, middle menu.
  thirds('Left, middle, right');

  const TapLayout(this.label);

  final String label;

  static TapLayout byName(String? name) =>
      TapLayout.values.firstWhere((l) => l.name == name, orElse: () => TapLayout.koreader);
}

TapAction tapActionFor(TapLayout layout, Offset position, Size size) {
  final x = position.dx / size.width;
  final y = position.dy / size.height;
  switch (layout) {
    case TapLayout.koreader:
    case TapLayout.koreaderMirrored:
      if (y < 1 / 8 || y >= 7 / 8) return TapAction.menu;
      final backward = layout == TapLayout.koreader ? x < 1 / 4 : x >= 3 / 4;
      return backward ? TapAction.previous : TapAction.next;
    case TapLayout.thirds:
      if (x < 1 / 3) return TapAction.previous;
      if (x >= 2 / 3) return TapAction.next;
      return TapAction.menu;
  }
}
