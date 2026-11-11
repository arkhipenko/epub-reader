// App database (drift / SQLite).
//
// Books are keyed by the KOReader partial MD5, so a book keeps its data when
// the file moves or is renamed.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../opds/default_catalogs.dart';

part 'database.g.dart';

class Books extends Table {
  /// KOReader partial MD5 of the file.
  TextColumn get id => text()();
  TextColumn get path => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get authors => text().withDefault(const Constant(''))();
  TextColumn get format => text().withDefault(const Constant(''))();
  TextColumn get language => text().withDefault(const Constant(''))();

  /// KOReader-compatible XPointer of the last reading position.
  TextColumn get lastXPointer => text().nullable()();

  /// Reading progress, 0 to 1 (KOReader percent_finished).
  RealColumn get progress => real().withDefault(const Constant(0))();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  // Schema 2: library.
  TextColumn get series => text().withDefault(const Constant(''))();
  IntColumn get seriesNumber => integer().withDefault(const Constant(0))();
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Cover image file in app storage, or null when the book has none.
  TextColumn get coverPath => text().nullable()();

  /// File size and modification time at the last scan. Null: never scanned.
  IntColumn get fileSize => integer().nullable()();
  DateTimeColumn get fileModified => dateTime().nullable()();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();

  /// Set when the book is in "Deleted" (Koodo trash).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// The file was not found at the last scan.
  BoolColumn get missing => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Small key-value store for settings. Values are JSON text.
class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DataClassName('Shelf')
class Shelves extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class ShelfBooks extends Table {
  IntColumn get shelfId => integer().references(Shelves, #id, onDelete: KeyAction.cascade)();
  TextColumn get bookId => text().references(Books, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {shelfId, bookId};
}

/// Bookmarks, highlights and notes, with the KOReader annotation fields
/// (readerannotation.lua): page, pos0, pos1, text, note, color, drawer,
/// chapter, pageno, datetime, datetime_updated.
/// A bookmark has no pos0 / pos1; a note is a highlight with note text.
class Annotations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get bookId => text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// XPointer: the page top for a bookmark, pos0 for a highlight.
  TextColumn get page => text()();
  TextColumn get pos0 => text().nullable()();
  TextColumn get pos1 => text().nullable()();
  TextColumn get textContent => text().named('text').withDefault(const Constant(''))();
  TextColumn get note => text().nullable()();

  /// KOReader color name: red, orange, yellow, green, olive, cyan, blue, purple, gray.
  TextColumn get color => text().withDefault(const Constant('yellow'))();

  /// KOReader drawer: lighten, underscore, strikeout, invert.
  TextColumn get drawer => text().withDefault(const Constant('lighten'))();
  TextColumn get chapter => text().withDefault(const Constant(''))();

  /// Page number when the annotation was made (layout dependent, for display).
  IntColumn get pageno => integer().withDefault(const Constant(0))();
  DateTimeColumn get datetime => dateTime()();
  DateTimeColumn get datetimeUpdated => dateTime().nullable()();
}

class OpdsCatalogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get url => text()();
  TextColumn get username => text().nullable()();

  /// Stored in the app database (personal use, private app storage).
  TextColumn get password => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Books, Prefs, Shelves, ShelfBooks, OpdsCatalogs, Annotations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'epub_reader'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _addDefaultCatalogs();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(books, books.series);
        await m.addColumn(books, books.seriesNumber);
        await m.addColumn(books, books.description);
        await m.addColumn(books, books.coverPath);
        await m.addColumn(books, books.fileSize);
        await m.addColumn(books, books.fileModified);
        await m.addColumn(books, books.favorite);
        await m.addColumn(books, books.deletedAt);
        await m.addColumn(books, books.missing);
        await m.createTable(shelves);
        await m.createTable(shelfBooks);
        await m.createTable(opdsCatalogs);
      }
      if (from < 3) {
        await m.createTable(annotations);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// A new install starts with the public catalogs in [kDefaultCatalogs].
  /// An upgrade of an existing database adds none.
  Future<void> _addDefaultCatalogs() async {
    final now = DateTime.now();
    await batch(
      (b) => b.insertAll(opdsCatalogs, [
        for (final c in kDefaultCatalogs) OpdsCatalogsCompanion.insert(title: c.title, url: c.url, createdAt: now),
      ]),
    );
  }

  // ---- Books ----

  Future<Book?> bookById(String id) => (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<List<Book>> allBooks() => select(books).get();

  /// Books by last opened time, newest first.
  Stream<List<Book>> watchRecentBooks() =>
      (select(books)
            ..where((b) => b.lastOpenedAt.isNotNull() & b.deletedAt.isNull())
            ..orderBy([(b) => OrderingTerm.desc(b.lastOpenedAt)]))
          .watch();

  /// All books that are not missing. The library filters and sorts them.
  Stream<List<Book>> watchLibrary() => (select(books)..where((b) => b.missing.equals(false))).watch();

  /// Creates the book row when a book is opened, or updates its path and
  /// metadata.
  Future<void> upsertBook({
    required String id,
    required String path,
    required String title,
    required String authors,
    required String format,
    required String language,
  }) async {
    final existing = await bookById(id);
    final now = DateTime.now();
    if (existing == null) {
      await into(books).insert(
        BooksCompanion.insert(
          id: id,
          path: path,
          title: Value(title),
          authors: Value(authors),
          format: Value(format),
          language: Value(language),
          addedAt: now,
          lastOpenedAt: Value(now),
        ),
      );
    } else {
      await (update(books)..where((b) => b.id.equals(id))).write(
        BooksCompanion(
          path: Value(path),
          title: Value(title),
          authors: Value(authors),
          format: Value(format),
          language: Value(language),
          lastOpenedAt: Value(now),
          missing: const Value(false),
        ),
      );
    }
  }

  /// Writes the data of a scanned file. A new book is added without
  /// lastOpenedAt, so it does not show in the history.
  Future<void> saveScannedBook(BooksCompanion data) async {
    final id = data.id.value;
    final existing = await bookById(id);
    if (existing == null) {
      await into(books).insert(data.copyWith(addedAt: Value(DateTime.now())));
    } else {
      await (update(books)..where((b) => b.id.equals(id))).write(data);
    }
  }

  Future<void> savePosition(String id, String xpointer, double progress) => (update(
    books,
  )..where((b) => b.id.equals(id))).write(BooksCompanion(lastXPointer: Value(xpointer), progress: Value(progress)));

  Future<void> setFavorite(String id, bool value) =>
      (update(books)..where((b) => b.id.equals(id))).write(BooksCompanion(favorite: Value(value)));

  /// Moves the book to "Deleted" (null restores it).
  Future<void> setDeleted(String id, DateTime? at) =>
      (update(books)..where((b) => b.id.equals(id))).write(BooksCompanion(deletedAt: Value(at)));

  Future<void> setMissing(Iterable<String> ids, bool value) =>
      (update(books)..where((b) => b.id.isIn(ids))).write(BooksCompanion(missing: Value(value)));

  Future<void> deleteBook(String id) => (delete(books)..where((b) => b.id.equals(id))).go();

  // ---- Shelves ----

  Stream<List<Shelf>> watchShelves() => (select(shelves)..orderBy([(s) => OrderingTerm.asc(s.name)])).watch();

  Future<int> addShelf(String name) =>
      into(shelves).insert(ShelvesCompanion.insert(name: name, createdAt: DateTime.now()));

  Future<void> renameShelf(int id, String name) =>
      (update(shelves)..where((s) => s.id.equals(id))).write(ShelvesCompanion(name: Value(name)));

  Future<void> deleteShelf(int id) => (delete(shelves)..where((s) => s.id.equals(id))).go();

  /// Book ids per shelf id.
  Stream<Map<int, Set<String>>> watchShelfBooks() => select(shelfBooks).watch().map((rows) {
    final m = <int, Set<String>>{};
    for (final r in rows) {
      m.putIfAbsent(r.shelfId, () => {}).add(r.bookId);
    }
    return m;
  });

  Future<void> setOnShelf(int shelfId, String bookId, bool on) async {
    if (on) {
      await into(shelfBooks).insertOnConflictUpdate(ShelfBooksCompanion.insert(shelfId: shelfId, bookId: bookId));
    } else {
      await (delete(shelfBooks)..where((r) => r.shelfId.equals(shelfId) & r.bookId.equals(bookId))).go();
    }
  }

  // ---- OPDS catalogs ----

  Stream<List<OpdsCatalog>> watchCatalogs() =>
      (select(opdsCatalogs)..orderBy([(c) => OrderingTerm.asc(c.title)])).watch();

  Future<void> saveCatalog(OpdsCatalogsCompanion c) async {
    if (c.id.present) {
      await (update(opdsCatalogs)..where((x) => x.id.equals(c.id.value))).write(c);
    } else {
      await into(opdsCatalogs).insert(c.copyWith(createdAt: Value(DateTime.now())));
    }
  }

  Future<void> deleteCatalog(int id) => (delete(opdsCatalogs)..where((c) => c.id.equals(id))).go();

  // ---- Annotations ----

  Stream<List<Annotation>> watchAnnotations(String bookId) =>
      (select(annotations)..where((a) => a.bookId.equals(bookId))).watch();

  /// All highlights and notes with their books, newest first (library
  /// Notes and Highlights sections).
  Stream<List<(Annotation, Book)>> watchAllHighlights() {
    final q = select(annotations).join([innerJoin(books, books.id.equalsExp(annotations.bookId))])
      ..where(annotations.pos0.isNotNull())
      ..orderBy([OrderingTerm.desc(annotations.datetime)]);
    return q.watch().map((rows) => [for (final r in rows) (r.readTable(annotations), r.readTable(books))]);
  }

  Future<int> addAnnotation(AnnotationsCompanion a) => into(annotations).insert(a);

  Future<void> updateAnnotation(int id, AnnotationsCompanion a) =>
      (update(annotations)..where((x) => x.id.equals(id))).write(a.copyWith(datetimeUpdated: Value(DateTime.now())));

  Future<void> deleteAnnotation(int id) => (delete(annotations)..where((x) => x.id.equals(id))).go();

  // ---- Prefs ----

  Future<String?> readPref(String key) async =>
      (await (select(prefs)..where((p) => p.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writePref(String key, String value) =>
      into(prefs).insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: value));

  Future<void> deletePref(String key) => (delete(prefs)..where((p) => p.key.equals(key))).go();
}
