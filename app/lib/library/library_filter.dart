// Which books a library section shows, and in which order.
import '../data/database.dart';
import 'library_settings.dart';

enum SectionKind { books, recent, favorites, deleted, shelf }

class LibrarySection {
  const LibrarySection(this.kind, {this.shelfId, this.shelfName});

  static const books = LibrarySection(SectionKind.books);
  static const recent = LibrarySection(SectionKind.recent);
  static const favorites = LibrarySection(SectionKind.favorites);
  static const deleted = LibrarySection(SectionKind.deleted);

  final SectionKind kind;
  final int? shelfId;
  final String? shelfName;

  String get title => switch (kind) {
        SectionKind.books => 'Books',
        SectionKind.recent => 'Recent',
        SectionKind.favorites => 'Favorites',
        SectionKind.deleted => 'Deleted',
        SectionKind.shelf => shelfName ?? 'Shelf',
      };

  @override
  bool operator ==(Object other) => other is LibrarySection && other.kind == kind && other.shelfId == shelfId;

  @override
  int get hashCode => Object.hash(kind, shelfId);
}

bool _matches(Book b, String query) {
  if (query.isEmpty) return true;
  final q = query.toLowerCase();
  return b.title.toLowerCase().contains(q) ||
      b.authors.toLowerCase().contains(q) ||
      b.series.toLowerCase().contains(q);
}

int _compareText(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

/// The books of [section] that match [query], sorted. "Recent" is always by
/// last read time; "Deleted" by deletion time.
List<Book> libraryView(
  List<Book> all, {
  required LibrarySection section,
  required String query,
  required LibrarySort sort,
  Map<int, Set<String>> shelves = const {},
}) {
  final shelf = section.kind == SectionKind.shelf ? (shelves[section.shelfId] ?? const <String>{}) : null;
  final list = all.where((b) {
    if (!_matches(b, query)) return false;
    final deleted = b.deletedAt != null;
    return switch (section.kind) {
      SectionKind.books => !deleted,
      SectionKind.recent => !deleted && b.lastOpenedAt != null,
      SectionKind.favorites => !deleted && b.favorite,
      SectionKind.deleted => deleted,
      SectionKind.shelf => !deleted && shelf!.contains(b.id),
    };
  }).toList();

  int byRecent(Book a, Book b) {
    final x = a.lastOpenedAt;
    final y = b.lastOpenedAt;
    if (x == null && y == null) return b.addedAt.compareTo(a.addedAt);
    if (x == null) return 1;
    if (y == null) return -1;
    return y.compareTo(x);
  }

  if (section.kind == SectionKind.recent) {
    list.sort(byRecent);
  } else if (section.kind == SectionKind.deleted) {
    list.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  } else {
    switch (sort) {
      case LibrarySort.recent:
        list.sort(byRecent);
      case LibrarySort.title:
        list.sort((a, b) => _compareText(a.title, b.title));
      case LibrarySort.author:
        list.sort((a, b) {
          final c = _compareText(a.authors, b.authors);
          if (c != 0) return c;
          final s = _compareText(a.series, b.series);
          if (s != 0) return s;
          final n = a.seriesNumber.compareTo(b.seriesNumber);
          return n != 0 ? n : _compareText(a.title, b.title);
        });
      case LibrarySort.added:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case LibrarySort.progress:
        list.sort((a, b) => b.progress.compareTo(a.progress));
    }
  }
  return list;
}
