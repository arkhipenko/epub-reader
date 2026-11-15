// Line shift: a vertical drag moves the page by whole text lines.
//
// The engine lays the book out as one tall strip. A document row is a pixel
// row of that strip, and a page is a slice of it. The rules here are free of
// Flutter and the engine, so they can be unit-tested.

/// A text line on the strip: rows [top] to [bottom] (bottom excluded).
class LineSpan {
  const LineSpan(this.top, this.bottom);

  final int top;
  final int bottom;
}

/// The slice of the strip that a page shows: [height] rows from [start].
class PageSpan {
  const PageSpan(this.page, this.start, this.height);

  /// 1-based page number.
  final int page;
  final int start;
  final int height;

  int get end => start + height;
}

/// Pages and text lines around the place where a shift happens.
class ShiftGeometry {
  const ShiftGeometry({
    required this.pages,
    required this.lines,
    required this.minY,
    required this.maxY,
    required this.areaTop,
    required this.areaHeight,
  });

  /// From engine rows: [page, start, height] and [top, bottom].
  factory ShiftGeometry.fromRows({
    required List<List<int>> pages,
    required List<List<int>> lines,
    required int minY,
    required int maxY,
    required int areaTop,
    required int areaHeight,
  }) => ShiftGeometry(
    pages: [for (final p in pages) PageSpan(p[0], p[1], p[2])],
    lines: [for (final l in lines) LineSpan(l[0], l[1])],
    minY: minY,
    maxY: maxY,
    areaTop: areaTop,
    areaHeight: areaHeight,
  );

  final List<PageSpan> pages;
  final List<LineSpan> lines;

  /// The first row a view can start at (start of the first page) and the
  /// last one (start of the last page).
  final int minY;
  final int maxY;

  /// Rows of a page image that can hold text: first row and row count.
  /// Row (areaTop + n) of the image of a page shows row (page start + n).
  final int areaTop;
  final int areaHeight;

  PageSpan? page(int number) {
    for (final p in pages) {
      if (p.page == number) return p;
    }
    return null;
  }

  /// The page that starts at row [y], or null. A view that starts there is
  /// that page, so the reader leaves the shifted state.
  PageSpan? pageStartingAt(int y) {
    for (final p in pages) {
      if (p.start == y) return p;
    }
    return null;
  }

  /// The page that holds row [y]. A row between two pages gives the page
  /// after it (the engine rule). The answer is right for the rows that this
  /// geometry covers: one screen before the place and two after it.
  int? pageAt(int y) {
    for (final p in pages) {
      if (y < p.end) return p.page;
    }
    return pages.isEmpty ? null : pages.last.page;
  }

  /// Limits a row to the rows a view can start at.
  double clamp(double y) => maxY < minY ? y : y.clamp(minY.toDouble(), maxY.toDouble());

  /// The row where the view rests when a drag ends at row [y]: the top of
  /// the nearest text line or page. [start] is the row before the drag; a
  /// drag of less than half a line returns there.
  int settle(double y, int start) {
    final target = clamp(y);
    var best = start;
    var bestDistance = (start - target).abs();
    void offer(int row) {
      if (row < minY || row > maxY) return;
      final d = (row - target).abs();
      // On a tie the row nearer to the start wins: the smaller move.
      if (d < bestDistance || (d == bestDistance && (row - start).abs() < (best - start).abs())) {
        best = row;
        bestDistance = d;
      }
    }

    for (final l in lines) {
      offer(l.top);
    }
    for (final p in pages) {
      offer(p.start);
    }
    return best;
  }

  /// The first row after the last whole line of a view that starts at row
  /// [y]. Text from there on is cut by the lower edge and is not shown.
  /// When no whole line fits (a tall picture), the view shows all its rows.
  int visibleEnd(int y) {
    final limit = y + areaHeight;
    var end = y;
    for (final l in lines) {
      if (l.top >= y && l.bottom <= limit && l.bottom > end) end = l.bottom;
    }
    return end > y ? end : limit;
  }
}

/// The row whose page a page turn shows after a shift. [top] is the first
/// row of the shifted view, [end] the first row after its last whole line.
/// Forward: the page with the first line below the view. Back: the page with
/// the last line above the view. No text is skipped; lines can show again.
int shiftTurnRow({required bool forward, required int top, required int end}) => forward ? end : top - 1;

/// The page of the fixed pages that a turn shows after a shift. [found] is
/// the page that holds the row of [shiftTurnRow], [current] the page that
/// holds the first line of the shifted view. A turn always leaves the
/// shifted view in its direction: forward never shows a page before the
/// next one, back never a page after the current one.
int shiftTurnPage({required bool forward, required int found, required int current, required int pageCount}) {
  final page = forward ? (found > current ? found : current + 1) : (found < current ? found : current);
  return page.clamp(1, pageCount < 1 ? 1 : pageCount);
}
