// App database (drift / SQLite).
//
// Books are keyed by the KOReader partial MD5, so a book keeps its data when
// the file moves or is renamed.
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

@DriftDatabase(tables: [Books, Prefs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'epub_reader'));

  @override
  int get schemaVersion => 1;

  Future<Book?> bookById(String id) => (select(books)..where((b) => b.id.equals(id))).getSingleOrNull();

  /// Books by last opened time, newest first.
  Stream<List<Book>> watchRecentBooks() => (select(books)
        ..where((b) => b.lastOpenedAt.isNotNull())
        ..orderBy([(b) => OrderingTerm.desc(b.lastOpenedAt)]))
      .watch();

  /// Creates the book row, or updates its path and metadata.
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
      await into(books).insert(BooksCompanion.insert(
        id: id,
        path: path,
        title: Value(title),
        authors: Value(authors),
        format: Value(format),
        language: Value(language),
        addedAt: now,
        lastOpenedAt: Value(now),
      ));
    } else {
      await (update(books)..where((b) => b.id.equals(id))).write(BooksCompanion(
        path: Value(path),
        title: Value(title),
        authors: Value(authors),
        format: Value(format),
        language: Value(language),
        lastOpenedAt: Value(now),
      ));
    }
  }

  Future<void> savePosition(String id, String xpointer, double progress) =>
      (update(books)..where((b) => b.id.equals(id)))
          .write(BooksCompanion(lastXPointer: Value(xpointer), progress: Value(progress)));

  Future<void> deleteBook(String id) => (delete(books)..where((b) => b.id.equals(id))).go();

  Future<String?> readPref(String key) async =>
      (await (select(prefs)..where((p) => p.key.equals(key))).getSingleOrNull())?.value;

  Future<void> writePref(String key, String value) =>
      into(prefs).insertOnConflictUpdate(PrefsCompanion.insert(key: key, value: value));
}
