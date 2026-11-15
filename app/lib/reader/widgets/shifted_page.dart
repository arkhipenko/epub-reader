// The page area while a vertical drag has moved the text off the fixed
// pages. It draws slices of the page images, placed by document row, so
// the engine does not draw while the text moves.
import 'package:flutter/material.dart';

import '../reader_controller.dart';

class ShiftedPage extends StatelessWidget {
  const ShiftedPage({super.key, required this.view, required this.background});

  final ShiftView view;

  /// Color of the page margins and of rows without text.
  final Color background;

  @override
  Widget build(BuildContext context) {
    // In a drag the text follows the finger at once. On release it moves
    // to its resting row in a short step.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: view.y),
      duration: view.dragging ? Duration.zero : const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      builder: (context, y, _) => CustomPaint(
        size: Size.infinite,
        painter: _ShiftPainter(view: view, y: y, background: background),
      ),
    );
  }
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
    final end = view.end;
    final rows = end == null ? view.areaHeight.toDouble() : (end - y).clamp(0.0, view.areaHeight.toDouble());
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
