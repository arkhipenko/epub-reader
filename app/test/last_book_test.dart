import 'dart:io';

import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/reader/last_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory dir;
  late String book;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('last_book');
    book = '${dir.path}/a.epub';
    await File(book).writeAsString('x');
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  test('no saved book: start in the library', () async {
    expect(await LastOpenBook(db).take(), isNull);
  });

  test('a book open when the app closed opens again', () async {
    await LastOpenBook(db).opened(book);
    // Next app start.
    final next = LastOpenBook(db);
    expect(await next.take(), book);
    // Taken once: a stop during the open does not open it again.
    expect(await db.readPref(LastOpenBook.prefKey), isNull);
  });

  test('a book the user closed does not open again', () async {
    final last = LastOpenBook(db);
    await last.opened(book);
    await last.closed(book);
    expect(await LastOpenBook(db).take(), isNull);
  });

  test('a missing file: start in the library', () async {
    await LastOpenBook(db).opened(book);
    await File(book).delete();
    expect(await LastOpenBook(db).take(), isNull);
    expect(await db.readPref(LastOpenBook.prefKey), isNull);
  });

  test('closing an older book keeps the newer one', () async {
    final last = LastOpenBook(db);
    final other = '${dir.path}/b.epub';
    await File(other).writeAsString('y');
    await last.opened(book);
    await last.opened(other);
    await last.closed(book);
    expect(await LastOpenBook(db).take(), other);
  });
}
