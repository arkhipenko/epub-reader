import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/dict/dictionary_service.dart';
import 'package:epub_reader/dict/stardict.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures: test/fixtures/make_stardict.py
StarDict _open(String name) => StarDict.open(StarDictInfo.read('test/fixtures/dict/$name.ifo')!);

void main() {
  group('StarDict', () {
    test('ifo', () {
      final info = StarDictInfo.read('test/fixtures/dict/dict_a.ifo')!;
      expect(info.name, 'Test A');
      expect(info.wordCount, 5);
      expect(info.sameTypeSequence, 'm');
      expect(StarDictInfo.read('test/fixtures/dict/missing.ifo'), isNull);
    });

    test('dictzip articles, ASCII case ignored, chunks crossed', () {
      final d = _open('dict_a');
      expect(d.length, 5);
      final apple = d.lookup('apple');
      expect(apple.single.word, 'Apple');
      expect(apple.single.plainText, 'A round fruit of a tree of the rose family.');
      // Longer than the 20-byte chunks of the fixture.
      expect(d.lookup('bookcase').single.plainText, 'A set of shelves for books.');
      expect(d.lookup('BOOK').single.plainText, 'A written or printed work of pages bound together.');
      expect(d.lookup('none'), isEmpty);
      d.close();
    });

    test('synonyms and Cyrillic', () {
      final d = _open('dict_a');
      expect(d.lookup('books').single.word, 'book');
      expect(d.lookup('дома').single.plainText, 'house, home');
      expect(d.lookup('привет').single.plainText, 'hello');
      // Not ASCII: case is not folded by the index, the service tries variants.
      expect(d.lookup('Привет'), isEmpty);
      d.close();
    });

    test('HTML article as text', () {
      final d = _open('dict_b');
      expect(d.lookup('book').single.plainText, 'book\nto reserve a seat & a room');
      d.close();
    });

    test('StarDict sort order', () {
      expect(stardictCompare('apple', 'Apple') > 0, isTrue); // same ignoring case, then exact
      expect(stardictCompare('Apple', 'book') < 0, isTrue);
      expect(asciiCaseCompare('BOOK', 'book'), 0);
    });
  });

  test('lookup variants drop punctuation and add case forms', () {
    expect(lookupVariants('«Привет,»'), ['Привет', 'привет']);
    expect(lookupVariants('  "Book."  '), ['Book', 'book']);
    expect(lookupVariants('apple'), ['apple', 'Apple']);
    expect(lookupVariants('...'), isEmpty);
  });

  test('dictionaries are found in folders', () {
    final found = findIfoFiles(['test/fixtures', 'test/missing']).map((p) => p.split(RegExp(r'[/\\]')).last).toSet();
    expect(found, {'dict_a.ifo', 'dict_b.ifo'});
    final order = DictionaryService.ordered([
      StarDictInfo.read('test/fixtures/dict/dict_a.ifo')!,
      StarDictInfo.read('test/fixtures/dict/dict_b.ifo')!,
    ], [File('test/fixtures/dict/dict_b.ifo').path]);
    expect(order.map((d) => d.name), ['Test B', 'Test A']);
  });

  test('annotations: bookmarks, highlights, join with books, cascade delete', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.upsertBook(id: 'b1', path: '/b.epub', title: 'Book', authors: '', format: 'EPUB', language: 'en');
    final now = DateTime(2026, 11, 9);
    await db.addAnnotation(AnnotationsCompanion.insert(bookId: 'b1', page: '/body/DocFragment[2]/body/p[1]/text().0',
        datetime: now));
    final h = await db.addAnnotation(AnnotationsCompanion.insert(
      bookId: 'b1',
      page: '/body/DocFragment[3]/body/p[2]/text().4',
      pos0: const Value('/body/DocFragment[3]/body/p[2]/text().4'),
      pos1: const Value('/body/DocFragment[3]/body/p[2]/text().9'),
      textContent: const Value('words'),
      color: const Value('green'),
      datetime: now,
    ));
    expect((await db.watchAnnotations('b1').first).length, 2);
    final all = await db.watchAllHighlights().first;
    expect(all.single.$1.textContent, 'words');
    expect(all.single.$2.title, 'Book');
    await db.updateAnnotation(h, const AnnotationsCompanion(note: Value('my note')));
    final updated = (await db.watchAnnotations('b1').first).firstWhere((a) => a.id == h);
    expect(updated.note, 'my note');
    expect(updated.datetimeUpdated, isNotNull);
    await db.deleteBook('b1');
    expect(await db.watchAnnotations('b1').first, isEmpty);
    await db.close();
  });
}
