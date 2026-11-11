import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/library/library_filter.dart';
import 'package:epub_reader/library/library_scanner.dart';
import 'package:epub_reader/library/library_settings.dart';
import 'package:epub_reader/opds/opds_client.dart';
import 'package:epub_reader/opds/opds_feed.dart';
import 'package:flutter_test/flutter_test.dart';

// An OPDS feed in the style of calibre-web (written for this test).
const String _feed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:opds="http://opds-spec.org/2010/catalog">
  <id>urn:uuid:catalog</id>
  <title>Calibre-Web</title>
  <link rel="search" href="/opds/osd" type="application/opensearchdescription+xml"/>
  <link rel="next" href="/opds/new?offset=30" type="application/atom+xml;profile=opds-catalog;type=feed;kind=acquisition"/>
  <entry>
    <title>Authors</title>
    <id>/opds/author</id>
    <content type="text">Books ordered by Author</content>
    <link rel="subsection" type="application/atom+xml;profile=opds-catalog" href="/opds/author"/>
  </entry>
  <entry>
    <title>The Ferry</title>
    <id>urn:uuid:book-1</id>
    <author><name>Test Sample</name></author>
    <content type="xhtml"><div>A <b>short</b> story.<br/>Second line.</div></content>
    <link type="image/jpeg" href="/opds/cover/1" rel="http://opds-spec.org/image"/>
    <link type="image/jpeg" href="/opds/cover/1" rel="http://opds-spec.org/image/thumbnail"/>
    <link rel="http://opds-spec.org/acquisition" href="/opds/download/1/epub/" type="application/epub+zip"/>
    <link rel="http://opds-spec.org/acquisition" href="/opds/download/1/fb2/" type="application/x-fictionbook+xml"/>
    <link rel="http://opds-spec.org/acquisition" href="/opds/download/1/pdf/" type="application/pdf"/>
  </entry>
</feed>''';

const String _osd = '''<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <Url type="text/html" template="/search?query={searchTerms}"/>
  <Url type="application/atom+xml" template="/opds/search/{searchTerms}"/>
</OpenSearchDescription>''';

void main() {
  group('OPDS parser', () {
    test('navigation, acquisition, covers, next and search links', () {
      final f = parseOpdsFeed(_feed, 'http://catalog.example:8083/opds');
      expect(f.title, 'Calibre-Web');
      expect(f.nextHref, 'http://catalog.example:8083/opds/new?offset=30');
      expect(f.searchDescriptionHref, 'http://catalog.example:8083/opds/osd');
      expect(f.entries, hasLength(2));

      final nav = f.entries[0];
      expect(nav.isBook, isFalse);
      expect(nav.navigationHref, 'http://catalog.example:8083/opds/author');

      final book = f.entries[1];
      expect(book.isBook, isTrue);
      expect(book.authors, ['Test Sample']);
      expect(book.thumbnailHref, 'http://catalog.example:8083/opds/cover/1');
      expect(book.acquisitions.map((a) => a.label), ['EPUB', 'FB2', 'PDF']);
      expect(book.acquisitions.map((a) => a.isSupported), [true, true, false]);
      expect(book.acquisitions.first.extension, '.epub');
      expect(stripHtml(book.summary), contains('short'));
    });

    test('OpenSearch prefers the Atom template and keeps {searchTerms}', () {
      expect(parseOpenSearchTemplate(_osd, 'http://h:8083/opds/osd'), 'http://h:8083/opds/search/{searchTerms}');
    });

    test('a non-feed document is an error', () {
      expect(() => parseOpdsFeed('<html></html>', 'http://h/'), throwsA(isA<OpdsParseException>()));
    });
  });

  group('OPDS client', () {
    late HttpServer server;
    late String base;
    final auths = <String?>[];

    setUp(() async {
      auths.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = 'http://127.0.0.1:${server.port}';
      server.listen((r) async {
        auths.add(r.headers.value('authorization'));
        if (r.headers.value('authorization') == null && r.uri.path != '/open') {
          r.response.statusCode = 401;
          r.response.headers.set('www-authenticate', 'Basic realm="x"');
        } else if (r.uri.path == '/opds') {
          r.response.headers.contentType = ContentType('application', 'atom+xml', charset: 'utf-8');
          r.response.write(_feed);
        } else if (r.uri.path == '/dl') {
          r.response.headers.set('content-disposition', "attachment; filename*=UTF-8''%D0%9F%D0%B0%D1%80%D0%BE%D0%BC.fb2");
          r.response.add(List<int>.filled(1000, 65));
        } else if (r.uri.path == '/open') {
          r.response.add(List<int>.filled(10, 66));
        }
        await r.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    test('401 without login, feed with Basic login', () async {
      final anon = OpdsClient();
      await expectLater(anon.fetchFeed('$base/opds'),
          throwsA(isA<OpdsException>().having((e) => e.needsLogin, 'needsLogin', isTrue)));
      anon.close();
      final c = OpdsClient(username: 'anna', password: 'pw');
      final f = await c.fetchFeed('$base/opds');
      expect(f.entries, hasLength(2));
      expect(auths.last, 'Basic YW5uYTpwdw==');
      c.close();
    });

    test('download uses the Content-Disposition name and avoids overwriting', () async {
      final dir = await Directory.systemTemp.createTemp('opds');
      final c = OpdsClient(username: 'anna', password: 'pw');
      const acq = OpdsAcquisition(href: '', type: 'application/x-fictionbook+xml');
      final a = await c.download(OpdsAcquisition(href: '$base/dl', type: acq.type), dir.path, 'x');
      final b = await c.download(OpdsAcquisition(href: '$base/dl', type: acq.type), dir.path, 'x');
      expect(a.split('/').last, 'Паром.fb2');
      expect(b.split('/').last, 'Паром (2).fb2');
      expect(await File(a).length(), 1000);
      final o = await c.download(OpdsAcquisition(href: '$base/open', type: 'application/epub+zip'), dir.path,
          'Author - Title');
      expect(o.split('/').last, 'Author - Title.epub');
      c.close();
      await dir.delete(recursive: true);
    });
  });

  group('library view', () {
    Book book(String id,
            {String title = 't',
            String authors = '',
            DateTime? opened,
            bool fav = false,
            DateTime? deleted,
            double progress = 0,
            int addedDay = 1}) =>
        Book(
          id: id,
          path: '/$id.epub',
          title: title,
          authors: authors,
          format: 'EPUB',
          language: 'en',
          progress: progress,
          addedAt: DateTime(2026, 1, addedDay),
          lastOpenedAt: opened,
          series: '',
          seriesNumber: 0,
          description: '',
          favorite: fav,
          deletedAt: deleted,
          missing: false,
        );

    final books = [
      book('a', title: 'Bravo', authors: 'Zed', opened: DateTime(2026, 3), addedDay: 3),
      book('b', title: 'alpha', authors: 'Amy', fav: true, progress: 0.5, addedDay: 2),
      book('c', title: 'Charlie', authors: 'Bob', opened: DateTime(2026, 5), deleted: DateTime(2026, 6)),
      book('d', title: 'Delta', authors: 'Amy', opened: DateTime(2026, 4), progress: 0.9, addedDay: 4),
    ];
    List<String> ids(LibrarySection s, {String q = '', LibrarySort sort = LibrarySort.title, Map<int, Set<String>>? sh}) =>
        libraryView(books, section: s, query: q, sort: sort, shelves: sh ?? const {}).map((b) => b.id).toList();

    test('sections', () {
      expect(ids(LibrarySection.books), ['b', 'a', 'd']); // title, case-insensitive; no deleted
      expect(ids(LibrarySection.recent), ['d', 'a']);
      expect(ids(LibrarySection.favorites), ['b']);
      expect(ids(LibrarySection.deleted), ['c']);
      expect(ids(const LibrarySection(SectionKind.shelf, shelfId: 7), sh: {7: {'a', 'c'}}), ['a']);
    });

    test('sort orders and search', () {
      expect(ids(LibrarySection.books, sort: LibrarySort.recent), ['d', 'a', 'b']);
      expect(ids(LibrarySection.books, sort: LibrarySort.author), ['b', 'd', 'a']);
      expect(ids(LibrarySection.books, sort: LibrarySort.added), ['d', 'a', 'b']);
      expect(ids(LibrarySection.books, sort: LibrarySort.progress), ['d', 'b', 'a']);
      expect(ids(LibrarySection.books, q: 'AMY'), ['b', 'd']);
    });
  });

  test('folder walk finds books, skips hidden and .sdr folders, hashes only changed files', () async {
    final root = await Directory.systemTemp.createTemp('lib');
    Future<File> put(String rel, int size) async {
      final f = File([root.path, ...rel.split('/')].join(Platform.pathSeparator));
      await f.parent.create(recursive: true);
      return f.writeAsBytes(List<int>.filled(size, 7));
    }

    final known = await put('known.epub', 10);
    await put('sub/book.FB2', 20);
    await put('sub/zipped.fb2.zip', 30);
    await put('.hidden/x.epub', 5);
    await put('a.sdr/y.epub', 5);
    await put('notes.txt', 5);
    final st = await known.stat();
    final found = walkLibrary([root.path, '${root.path}/missing'], {
      known.path: [st.size, st.modified.millisecondsSinceEpoch],
    });
    final names = {for (final f in found) f.path.split(RegExp(r'[/\\]')).last: f};
    expect(names.keys.toSet(), {'known.epub', 'book.FB2', 'zipped.fb2.zip'});
    expect(names['known.epub']!.md5, isNull);
    expect(names['book.FB2']!.md5, hasLength(32));
    await root.delete(recursive: true);
  });

  test('migration from schema 1 keeps books and positions', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''CREATE TABLE books (id TEXT NOT NULL, path TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '', authors TEXT NOT NULL DEFAULT '', format TEXT NOT NULL DEFAULT '',
        language TEXT NOT NULL DEFAULT '', last_x_pointer TEXT NULL, progress REAL NOT NULL DEFAULT 0,
        added_at INTEGER NOT NULL, last_opened_at INTEGER NULL, PRIMARY KEY (id))''');
      raw.execute('CREATE TABLE prefs (key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (key))');
      raw.execute("INSERT INTO books (id, path, title, last_x_pointer, progress, added_at) "
          "VALUES ('m1', '/b.epub', 'Old', '/body/DocFragment[3]/body/p[1]/text().0', 0.3, 1700000000)");
      raw.execute('PRAGMA user_version = 1');
    }));
    final b = (await db.bookById('m1'))!;
    expect(b.title, 'Old');
    expect(b.lastXPointer, '/body/DocFragment[3]/body/p[1]/text().0');
    expect(b.favorite, isFalse);
    expect(b.missing, isFalse);
    expect(b.fileSize, isNull);
    // Schema 4: the book settings column.
    expect(b.settings, isNull);
    await db.saveBookSettings('m1', '{"language":"ru"}');
    expect((await db.bookById('m1'))!.settings, '{"language":"ru"}');
    // The upgrade of an existing database adds no catalog (new installs only).
    expect(await db.watchCatalogs().first, isEmpty);
    final shelf = await db.addShelf('Fiction');
    await db.setOnShelf(shelf, 'm1', true);
    expect((await db.watchShelfBooks().first)[shelf], {'m1'});
    await db.saveScannedBook(const BooksCompanion(id: Value('m1'), coverPath: Value('/c/m1')));
    expect((await db.bookById('m1'))!.coverPath, '/c/m1');
    await db.close();
  });

  test('migration from schema 3 adds the book settings and keeps the data', () async {
    final dir = await Directory.systemTemp.createTemp('epub_reader_db');
    final file = File('${dir.path}/app.sqlite');
    // Make a schema 3 database: the current tables without the new column.
    var db = AppDatabase(NativeDatabase(file));
    await db.upsertBook(id: 'b3', path: '/b.epub', title: 'Three', authors: 'A', format: 'EPUB', language: 'ru');
    await db.savePosition('b3', '/body/DocFragment[2]/body/p[1]/text().0', 0.4);
    await db.customStatement('ALTER TABLE books DROP COLUMN settings');
    await db.customStatement('PRAGMA user_version = 3');
    await db.close();

    db = AppDatabase(NativeDatabase(file));
    final b = (await db.bookById('b3'))!;
    expect(b.title, 'Three');
    expect(b.lastXPointer, '/body/DocFragment[2]/body/p[1]/text().0');
    expect(b.progress, 0.4);
    expect(b.settings, isNull);
    await db.saveBookSettings('b3', '{"ignoreMargins":true}');
    expect((await db.bookById('b3'))!.settings, '{"ignoreMargins":true}');
    await db.close();
    await dir.delete(recursive: true);
  });
}
