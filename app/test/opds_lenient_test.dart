// The lenient link rule: an OPDS entry with nothing else opens a link
// without rel that says it is a web page. ManyBooks labels the link of each
// search result this way, though it leads to a catalog page. The fixture is
// a trimmed copy of the ManyBooks search "twain" of 2026-11-15.
import 'dart:io';

import 'package:epub_reader/opds/opds_client.dart';
import 'package:epub_reader/opds/opds_feed.dart';
import 'package:flutter_test/flutter_test.dart';

const String _head = '<feed xmlns="http://www.w3.org/2005/Atom"><title>T</title>';

OpdsEntry _entry(String links) =>
    parseOpdsFeed('$_head<entry><title>B</title>$links</entry></feed>', 'http://h/opds/').entries.single;

void main() {
  test('ManyBooks search results open their detail page', () {
    final feed = parseOpdsFeed(
      File('test/fixtures/opds/manybooks_search.xml').readAsStringSync(),
      'https://manybooks.net/opds/search?q=twain',
    );
    expect(feed.entries.map((e) => e.title), ["The Boys' Life of Mark Twain", 'Mark Twain, A Biography']);
    expect(feed.entries.map((e) => e.navigationHref), [
      'https://manybooks.net/opds/title_detail/126037',
      'https://manybooks.net/opds/title_detail/126044',
    ]);
    expect(feed.entries.every((e) => !e.isBook), isTrue);
  });

  group('lenient link rule', () {
    test('a web page link without rel is the fallback, with or without parameters', () {
      expect(_entry('<link type="text/html" href="/a"/>').navigationHref, 'http://h/a');
      expect(_entry('<link type="text/html; charset=utf-8" href="/b"/>').navigationHref, 'http://h/b');
      expect(_entry('<link type="TEXT/HTML" href="/c"/>').navigationHref, 'http://h/c');
    });

    test('a catalog or subsection link wins over the fallback', () {
      expect(
        _entry('<link type="text/html" href="/page"/><link type="application/atom+xml" href="/feed"/>').navigationHref,
        'http://h/feed',
      );
      expect(
        _entry('<link type="text/html" href="/page"/><link rel="subsection" href="/sub"/>').navigationHref,
        'http://h/sub',
      );
    });

    test('a book keeps no navigation link', () {
      final e = _entry(
        '<link type="text/html" href="/page"/>'
        '<link rel="http://opds-spec.org/acquisition" type="application/epub+zip" href="/b.epub"/>',
      );
      expect(e.isBook, isTrue);
      expect(e.navigationHref, isNull);
    });

    test('a link with a rel, or of another type, is never the fallback', () {
      expect(_entry('<link rel="alternate" type="text/html" href="/page"/>').navigationHref, isNull);
      expect(
        _entry('<link rel="http://opds-spec.org/thumbnail" type="image/jpeg" href="/t.jpg"/>').navigationHref,
        isNull,
      );
      expect(_entry('<link type="image/jpeg" href="/t.jpg"/>').navigationHref, isNull);
      expect(_entry('<link type="application/pdf" href="/x.pdf"/>').navigationHref, isNull);
    });
  });

  group('a web page instead of a catalog page', () {
    late HttpServer server;
    late String base;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = 'http://127.0.0.1:${server.port}';
      server.listen((r) async {
        switch (r.uri.path) {
          case '/html':
            r.response.headers.contentType = ContentType.html;
            r.response.write('<!DOCTYPE html><html><body><p>A web page<br></body></html>');
          case '/xhtml':
            r.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
            r.response.write('<html><body><p>Well-formed</p></body></html>');
          case '/broken':
            r.response.headers.contentType = ContentType('application', 'xml');
            r.response.write('<feed xmlns="http://www.w3.org/2005/Atom"><entry><title>x</entry></feed>');
          case '/feed-as-html':
            r.response.headers.contentType = ContentType.html;
            r.response.write('$_head<entry><title>Only</title></entry></feed>');
        }
        await r.response.close();
      });
    });
    tearDown(() => server.close(force: true));

    Matcher fails(String message) =>
        throwsA(isA<OpdsException>().having((e) => e.message, 'message', startsWith(message)));

    test('a web page gets its own message', () async {
      final c = OpdsClient();
      await expectLater(c.fetchFeed('$base/html'), fails('The server sent a web page, not a catalog page.'));
      await expectLater(c.fetchFeed('$base/xhtml'), fails('The server sent a web page, not a catalog page.'));
      c.close();
    });

    test('an XML page keeps the old messages, and a feed sent as a web page still opens', () async {
      final c = OpdsClient();
      await expectLater(c.fetchFeed('$base/broken'), fails('The catalog sent a page with errors.'));
      final f = await c.fetchFeed('$base/feed-as-html');
      expect(f.entries.single.title, 'Only');
      c.close();
    });
  });
}
