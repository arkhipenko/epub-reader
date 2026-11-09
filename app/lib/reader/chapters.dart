// Chapter position and reading-time helpers for the footer and navigation.
import '../engine/cre_engine.dart';

/// The chapter that holds [page]: the last TOC entry that starts on or
/// before the page. Returns -1 before the first entry.
int chapterIndexAt(List<TocEntry> toc, int page) {
  var index = -1;
  for (var i = 0; i < toc.length; i++) {
    if (toc[i].page <= page) {
      index = i;
    } else {
      break;
    }
  }
  return index;
}

/// First page of the next chapter that starts after [page], or null.
int? nextChapterPage(List<TocEntry> toc, int page) {
  for (final e in toc) {
    if (e.page > page) return e.page;
  }
  return null;
}

/// First page of the chapter before the one that holds [page]. When [page]
/// is not the first page of its chapter, this is the start of the current
/// chapter (as a "previous chapter" button behaves in most readers).
int? previousChapterPage(List<TocEntry> toc, int page) {
  int? best;
  for (final e in toc) {
    if (e.page < page) best = e.page;
  }
  return best;
}

/// Pages after [page] that are still in the same chapter
/// (KOReader footer "pages left in chapter").
int pagesLeftInChapter(List<TocEntry> toc, int page, int pageCount) {
  final next = nextChapterPage(toc, page) ?? pageCount + 1;
  final left = next - page - 1;
  return left < 0 ? 0 : left;
}

/// Average time per page from page-turn intervals. Intervals shorter than
/// [minimum] (skimming) or longer than [maximum] (a break) are ignored.
class ReadingSpeed {
  ReadingSpeed({this.minimum = const Duration(seconds: 2), this.maximum = const Duration(minutes: 10)});

  final Duration minimum;
  final Duration maximum;
  DateTime? _last;
  int _samples = 0;
  int _totalMs = 0;

  void pageTurned(DateTime now) {
    final last = _last;
    _last = now;
    if (last == null) return;
    final d = now.difference(last);
    if (d < minimum || d > maximum) return;
    _samples++;
    _totalMs += d.inMilliseconds;
  }

  /// Null until there are enough samples to give an estimate.
  Duration? get perPage => _samples < 3 ? null : Duration(milliseconds: _totalMs ~/ _samples);

  Duration? timeFor(int pages) {
    final p = perPage;
    return p == null ? null : p * pages;
  }
}
