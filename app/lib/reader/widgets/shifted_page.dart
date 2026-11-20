// The page area while a vertical drag has moved the text off the fixed
// pages. It draws slices of the page images, placed by document row, so
// the engine does not draw while the text moves.
import 'package:flutter/material.dart';

import '../reader_controller.dart';

/// Builds a layer over the text for the document row [y] at the top text
/// edge (it moves with the text). [rows] is the count of text rows that
/// show from there.
typedef ShiftOverlayBuilder = Widget Function(double y, double rows);

class ShiftedPage extends StatelessWidget {
  const ShiftedPage({super.key, required this.view, required this.background, this.filter, this.overlay});

  final ShiftView view;

  /// Color of the page margins and of rows without text.
  final Color background;

  /// Applied to the page images, not to [overlay] (a dark theme).
  final ColorFilter? filter;

  /// Highlights and other marks over the text.
  final ShiftOverlayBuilder? overlay;

  @override
  Widget build(BuildContext context) {
    // In a drag the text follows the finger at once, and a page turn shows
    // the new view at once. On release after a drag it moves to its
    // resting row in a short step.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: view.y),
      duration: view.settle ? const Duration(milliseconds: 120) : Duration.zero,
      curve: Curves.easeOut,
      builder: (context, y, _) {
        Widget text = CustomPaint(
          size: Size.infinite,
          painter: _ShiftPainter(view: view, y: y, background: background),
        );
        final f = filter;
        if (f != null) text = ColorFiltered(colorFilter: f, child: text);
        final o = overlay;
        if (o == null) return text;
        return Stack(fit: StackFit.expand, children: [text, o(y, _visibleRows(view, y))]);
      },
    );
  }
}

/// Rows of text that a view at row [y] shows: down to its end at rest,
/// down to the lower edge in a drag.
double _visibleRows(ShiftView view, double y) {
  final end = view.end;
  return end == null ? view.areaHeight.toDouble() : (end - y).clamp(0.0, view.areaHeight.toDouble());
}

class _ShiftPainter extends CustomPainter {
  _ShiftPainter({required this.view, required this.y, required this.background});

  final ShiftView view;

  /// Document row at the top text edge (animated).
  final double y;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (view.slices.isEmpty) return;
    final image = view.slices.first.image;
    // Widget pixels per page pixel, as the page image itself is scaled.
    final kx = size.width / image.width;
    final ky = size.height / image.height;
    final top = view.areaTop * ky;
    final rows = _visibleRows(view, y);
    final area = Rect.fromLTWH(0, top, size.width, rows * ky);
    canvas.save();
    canvas.clipRect(area, doAntiAlias: false);
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = false;
    for (final s in view.slices) {
      final dst = Rect.fromLTWH(0, top + (s.start - y) * ky, s.image.width * kx, s.height * ky);
      if (!dst.overlaps(area)) continue;
      final src = Rect.fromLTWH(0, view.areaTop.toDouble(), s.image.width.toDouble(), s.height.toDouble());
      canvas.drawImageRect(s.image, src, dst, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShiftPainter old) => old.view != view || old.y != y || old.background != background;
}
