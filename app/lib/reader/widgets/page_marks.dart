// Draws highlights, the selection and the search hit over the page image.
import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../engine/cre_engine.dart';
import '../annotation_style.dart';

class PageMarksPainter extends CustomPainter {
  PageMarksPainter({
    required this.marks,
    required this.annotations,
    required this.scale,
    required this.selectionColor,
    this.dark = false,
  });

  /// Boxes in page pixels by key (annotation id, 'sel', 'hit').
  final Map<String, List<PageRect>> marks;
  final Map<int, Annotation> annotations;

  /// Page pixels to widget pixels.
  final double scale;
  final Color selectionColor;

  /// On a dark page, multiply would hide the color; blend normally.
  final bool dark;

  Rect _rect(PageRect r) => Rect.fromLTRB(r.left * scale, r.top * scale, r.right * scale, r.bottom * scale);

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in marks.entries) {
      final id = int.tryParse(e.key);
      if (id == null) continue;
      final a = annotations[id];
      if (a == null) continue;
      final color = highlightColor(a.color);
      final drawer = HighlightDrawer.byName(a.drawer);
      for (final b in e.value) {
        final r = _rect(b);
        switch (drawer) {
          case HighlightDrawer.lighten:
            // Multiply keeps black text black on the color.
            canvas.drawRect(r, Paint()
              ..color = color.withValues(alpha: dark ? 0.35 : 0.55)
              ..blendMode = dark ? BlendMode.srcOver : BlendMode.multiply);
          case HighlightDrawer.underscore:
            canvas.drawRect(Rect.fromLTRB(r.left, r.bottom - 2.5, r.right, r.bottom), Paint()..color = color);
          case HighlightDrawer.strikeout:
            final y = r.center.dy;
            canvas.drawRect(Rect.fromLTRB(r.left, y - 1, r.right, y + 1), Paint()..color = color);
          case HighlightDrawer.invert:
            canvas.drawRect(r, Paint()
              ..color = Colors.white
              ..blendMode = BlendMode.difference);
        }
        if (a.note != null && a.note!.isNotEmpty && b == e.value.last) {
          // A small mark at the end of a highlight with a note.
          canvas.drawCircle(Offset(r.right + 3, r.top + 3), 3, Paint()..color = color.withValues(alpha: 0.9));
        }
      }
    }
    final sel = marks['sel'];
    if (sel != null) {
      for (final b in sel) {
        canvas.drawRect(_rect(b), Paint()..color = selectionColor.withValues(alpha: 0.28));
      }
    }
    final hit = marks['hit'];
    if (hit != null) {
      for (final b in hit) {
        final r = _rect(b).inflate(1.5);
        canvas.drawRect(r, Paint()..color = const Color(0x55FF8800));
        canvas.drawRect(r, Paint()
          ..color = const Color(0xFFFF8800)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
      }
    }
  }

  @override
  bool shouldRepaint(PageMarksPainter old) =>
      old.marks != marks ||
      old.annotations != annotations ||
      old.scale != scale ||
      old.selectionColor != selectionColor ||
      old.dark != dark;
}
