import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('upsert keeps position and updates path', () async {
    await db.upsertBook(id: 'abc', path: '/a.epub', title: 'T', authors: 'A', format: 'EPUB', language: 'en');
    await db.savePosition('abc', '/body/DocFragment[2]/body/p[3]/text().0', 0.25);
    await db.upsertBook(id: 'abc', path: '/moved/a.epub', title: 'T', authors: 'A', format: 'EPUB', language: 'en');
    final b = (await db.bookById('abc'))!;
    expect(b.path, '/moved/a.epub');
    expect(b.lastXPointer, '/body/DocFragment[2]/body/p[3]/text().0');
    expect(b.progress, 0.25);
  });

  test('book settings are stored with the book and can be cleared', () async {
    await db.upsertBook(id: 'abc', path: '/a.epub', title: 'T', authors: 'A', format: 'EPUB', language: 'ru');
    expect((await db.bookById('abc'))!.settings, isNull);
    await db.saveBookSettings('abc', '{"language":"ru"}');
    // Opening the book again keeps the settings.
    await db.upsertBook(id: 'abc', path: '/a.epub', title: 'T', authors: 'A', format: 'EPUB', language: 'ru');
    expect((await db.bookById('abc'))!.settings, '{"language":"ru"}');
    await db.saveBookSettings('abc', null);
    expect((await db.bookById('abc'))!.settings, isNull);
  });

  test('prefs store and replace values', () async {
    expect(await db.readPref('k'), isNull);
    await db.writePref('k', '1');
    await db.writePref('k', '2');
    expect(await db.readPref('k'), '2');
  });

  test('recent books are ordered by last opened', () async {
    await db.upsertBook(id: '1', path: '/1', title: 'One', authors: '', format: '', language: '');
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await db.upsertBook(id: '2', path: '/2', title: 'Two', authors: '', format: '', language: '');
    final books = await db.watchRecentBooks().first;
    expect(books.map((b) => b.id), ['2', '1']);
  });
}
