// Line shift: a vertical drag moves the page by whole text lines, and the
// page turns after it continue from the shifted line (an aligned run).
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
  const PageSpan(this.page, this.start, this.height, {this.forced = false});

  /// 1-based page number.
  final int page;
  final int start;
  final int height;

  /// The page starts after a forced page break (most books start each
  /// chapter this way). A shifted view does not cross this start.
  final bool forced;

  int get end => start + height;
}

/// A shifted view at rest: it shows rows [start] to [end] (end excluded).
/// Rows from [end] to the lower edge stay blank.
class ViewSpan {
  const ViewSpan(this.start, this.end);

  final int start;
  final int end;

  @override
  bool operator ==(Object other) => other is ViewSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ViewSpan($start, $end)';
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
    this.bookEnd,
    this.coverFrom,
    this.coverTo,
  });

  /// From engine rows: [page, start, height, forced] and [top, bottom].
  factory ShiftGeometry.fromRows({
    required List<List<int>> pages,
    required List<List<int>> lines,
    required int minY,
    required int maxY,
    required int areaTop,
    required int areaHeight,
    int? bookEnd,
    int? coverFrom,
    int? coverTo,
  }) => ShiftGeometry(
    pages: [for (final p in pages) PageSpan(p[0], p[1], p[2], forced: p.length > 3 && p[3] == 1)],
    lines: [for (final l in lines) LineSpan(l[0], l[1])],
    minY: minY,
    maxY: maxY,
    areaTop: areaTop,
    areaHeight: areaHeight,
    bookEnd: bookEnd,
    coverFrom: coverFrom,
    coverTo: coverTo,
  );

  final List<PageSpan> pages;
  final List<LineSpan> lines;

  /// The first row a drag can move the view to (start of the first page)
  /// and the last one (start of the last page).
  final int minY;
  final int maxY;

  /// Rows of a page image that can hold text: first row and row count.
  /// Row (areaTop + n) of the image of a page shows row (page start + n).
  final int areaTop;
  final int areaHeight;

  /// The row after the last page. Null: not known.
  final int? bookEnd;

  /// The rows that [lines] covers. Null: no limit known.
  final int? coverFrom;
  final int? coverTo;

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

  /// True when the lines of rows [from] to [to] are in this geometry. Rows
  /// outside the book count as covered.
  bool covers(int from, int to) {
    final lo = coverFrom;
    final hi = coverTo;
    final end = bookEnd;
    final okFrom = lo == null || lo <= (from < minY ? minY : from);
    final okTo = hi == null || hi >= (end != null && to > end ? end : to);
    return okFrom && okTo;
  }

  /// Limits a row to the rows a drag can move the view to.
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

  /// The start of the first page after row [y] that follows a forced page
  /// break, or null when there is none in this geometry.
  int? nextBreak(int y) {
    for (final p in pages) {
      if (p.forced && p.start > y) return p.start;
    }
    return null;
  }

  /// The start of the section that holds row [y]: the last page start at or
  /// before [y] that follows a forced page break. Null when there is none
  /// in this geometry.
  int? sectionStart(int y) {
    int? found;
    for (final p in pages) {
      if (p.forced && p.start <= y) found = p.start;
    }
    return found;
  }

  /// The first row after the last whole line of a view that starts at row
  /// [y]. Text from there on is cut by the lower edge and is not shown. The
  /// view does not cross a forced page break: it ends there. When no whole
  /// line fits (a tall picture), the view shows all its rows.
  int visibleEnd(int y) {
    var limit = y + areaHeight;
    final next = nextBreak(y);
    if (next != null && next < limit) limit = next;
    var end = y;
    for (final l in lines) {
      if (l.top >= y && l.bottom <= limit && l.bottom > end) end = l.bottom;
    }
    return end > y ? end : limit;
  }

  /// The row where the view after a view that ends at [end] starts: the
  /// top of the next line, or a page start between them. Rows without text
  /// between them (margins) are skipped. [end] itself when a line goes on
  /// below it (a tall picture). Null when there is no text after [end].
  int? nextStart(int end) {
    int? next;
    for (final l in lines) {
      if (l.top < end && l.bottom > end) return end;
      if (l.top >= end && (next == null || l.top < next)) next = l.top;
    }
    if (next == null) return null;
    for (final p in pages) {
      if (p.start >= end && p.start <= next) return p.start;
    }
    return next;
  }

  /// The start of the view that a back turn shows above a view that starts
  /// at row [top]: the top of the earliest line that fits on the screen
  /// together with all lines below it, up to [top]. The view does not start
  /// before its section or the book. Null when no line lies between the
  /// start of the section (or the book) and [top].
  int? backStart(int top) {
    var floor = top - areaHeight;
    var hard = false;
    final section = sectionStart(top);
    if (section != null && section >= floor) {
      floor = section;
      hard = true;
    }
    if (floor <= minY) {
      floor = minY;
      hard = true;
    }
    int? best;
    for (final l in lines) {
      if (l.top >= floor && l.bottom <= top && (best == null || l.top < best)) best = l.top;
    }
    // A tall picture above: the view shows the rows that fit.
    return best ?? (hard ? null : floor);
  }

  /// The top of the line that holds row [y], or [y] when no line holds it.
  int lineTopAt(int y) {
    for (final l in lines) {
      if (l.top <= y && y < l.bottom) return l.top;
    }
    return y;
  }
}

/// Where a page turn goes from a shifted view.
sealed class ShiftTurn {
  const ShiftTurn();
}

/// To another shifted view.
class TurnToView extends ShiftTurn {
  const TurnToView(this.view);

  final ViewSpan view;

  @override
  bool operator ==(Object other) => other is TurnToView && other.view == view;

  @override
  int get hashCode => view.hashCode;

  @override
  String toString() => 'TurnToView($view)';
}

/// To a fixed page. The aligned run ends.
class TurnToPage extends ShiftTurn {
  const TurnToPage(this.page);

  final int page;

  @override
  bool operator ==(Object other) => other is TurnToPage && other.page == page;

  @override
  int get hashCode => page.hashCode;

  @override
  String toString() => 'TurnToPage($page)';
}

/// Nowhere: the view is at the end or the start of the book.
class TurnNone extends ShiftTurn {
  const TurnNone();

  @override
  bool operator ==(Object other) => other is TurnNone;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'TurnNone()';
}

/// A page turn from the shifted view [current].
///
/// Forward: the next view starts at the end of [current], so no line shows
/// again and no line is skipped (see [ShiftGeometry.nextStart]). When it
/// would start where a fixed page starts, the turn shows that page.
///
/// Back: [history] holds the views that forward turns of this run left, and
/// back returns to the last of them. Without one, the new view ends where
/// [current] starts (see [ShiftGeometry.backStart]). A view that starts
/// where a fixed page starts turns back to the fixed page before it.
///
/// A forward turn adds [current] to [history]; a back turn takes from it.
ShiftTurn alignedTurn(ShiftGeometry g, ViewSpan current, {required bool forward, required List<ViewSpan> history}) {
  if (forward) {
    final next = g.nextStart(current.end);
    if (next == null) return const TurnNone();
    history.add(current);
    final page = g.pageStartingAt(next);
    if (page != null) return TurnToPage(page.page);
    return TurnToView(ViewSpan(next, g.visibleEnd(next)));
  }
  if (history.isNotEmpty) return TurnToView(history.removeLast());
  final page = g.pageStartingAt(current.start);
  if (page != null) return page.page > 1 ? TurnToPage(page.page - 1) : const TurnNone();
  final start = g.backStart(current.start);
  if (start != null) return TurnToView(ViewSpan(start, current.start));
  // Only rows without text up to the section start: the fixed page before
  // the section, as for a view at the section start.
  final section = g.sectionStart(current.start);
  final first = section == null ? null : g.pageStartingAt(section);
  return first != null && first.page > 1 ? TurnToPage(first.page - 1) : const TurnNone();
}
