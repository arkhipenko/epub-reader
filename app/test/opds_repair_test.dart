// OPDS pages with errors in a book description. The fixtures are two book
// pages that Project Gutenberg sent on 2026-11-15 (books 174 and 4078). The
// catalog record carried an injected advertising link, and the server wrote
// it as <a href="..."">, which is not well-formed XML. The address of the
// advertiser is replaced by ads.example in the fixtures.
import 'dart:io';

import 'package:epub_reader/opds/opds_feed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

String _fixture(String name) => File('test/fixtures/opds/$name').readAsStringSync();

const String _head = '<feed xmlns="http://www.w3.org/2005/Atom"><title>T</title>';

void main() {
  group('Project Gutenberg book pages', () {
    for (final name in ['gutenberg_174.xml', 'gutenberg_4078.xml']) {
      test('$name is not well-formed and still opens', () {
        final xml = _fixture(name);
        expect(() => XmlDocument.parse(xml), throwsA(isA<XmlException>()), reason: 'the fixture lost its defect');

        final feed = parseOpdsFeed(xml, 'https://www.gutenberg.org/ebooks/174.opds');
        expect(feed.entries, isNotEmpty);
        final book = feed.entries.first;
        expect(book.title, 'The Picture of Dorian Gray');
        expect(book.isBook, isTrue);
        expect(book.authors, ['Wilde, Oscar']);
        expect(book.acquisitions.map((a) => a.label).toSet(), containsAll(['EPUB', 'MOBI']));
        expect(book.acquisitions.first.href, startsWith('https://www.gutenberg.org/ebooks/'));

        final summary = stripHtml(book.summary);
        expect(summary, contains('Oscar Wilde'));
        expect(summary, contains('Gothic horror novel'));
        // No script source and no tags in the text.
        for (final bad in ['<', '>', 'function', 'window.open', 'addEventListener', 'script']) {
          expect(summary, isNot(contains(bad)), reason: bad);
        }
      });
    }
  });

  group('descriptions as text', () {
    OpdsEntry entry(String inner) =>
        parseOpdsFeed('$_head<entry><title>B</title>$inner</entry></feed>', 'http://h/').entries.single;

    test('the three Atom text types give the same plain text', () {
      const want = 'A short story.\nTom & Jerry';
      expect(
        stripHtml(
          entry('<content type="xhtml"><div>A <b>short</b> story.<br/>Tom &amp; Jerry</div></content>').summary,
        ),
        want,
      );
      expect(
        stripHtml(
          entry('<content type="html">A &lt;b&gt;short&lt;/b&gt; story.&lt;br&gt;Tom &amp;amp; Jerry</content>')
              .summary,
        ),
        want,
      );
      expect(stripHtml(entry('<content type="text">A short story.\nTom &amp; Jerry</content>').summary), want);
    });

    test('bad markup in a description does not stop the page', () {
      final e = entry(
        '<content type="xhtml"><div><p>One<br>two <a href="//x.example/a"">link</a> & more</div></content>'
        '<link rel="http://opds-spec.org/acquisition" href="/b.epub" type="application/epub+zip"/>',
      );
      expect(stripHtml(e.summary), 'One\ntwo link & more');
      expect(e.acquisitions.single.href, 'http://h/b.epub');
    });

    test('an empty content element does not swallow the next entry', () {
      final feed = parseOpdsFeed(
        '$_head<entry><title>A</title><content type="text"/><link rel="subsection" href="/a" type="application/atom+xml"/></entry>'
            '<entry><title>B</title><content type="text">second</content></entry></feed>',
        'http://h/',
      );
      expect(feed.entries.map((e) => e.title), ['A', 'B']);
      expect(feed.entries[0].summary, '');
      expect(feed.entries[0].navigationHref, 'http://h/a');
      expect(feed.entries[1].summary, 'second');
    });

    test('CDATA, a name prefix and the summary element', () {
      expect(
        stripHtml(entry('<content type="html"><![CDATA[<p>In <i>CDATA</i> & more</p>]]></content>').summary),
        'In CDATA & more',
      );
      final prefixed = parseOpdsFeed(
        '<atom:feed xmlns:atom="http://www.w3.org/2005/Atom"><atom:title>T</atom:title><atom:entry><atom:title>B</atom:title>'
            '<atom:content type="xhtml"><p>bad <br> tag</p></atom:content></atom:entry></atom:feed>',
        'http://h/',
      );
      expect(stripHtml(prefixed.entries.single.summary), 'bad\n tag');
      expect(
        stripHtml(entry('<summary type="html">&lt;p&gt;Only a summary&lt;/p&gt;</summary>').summary),
        'Only a summary',
      );
    });

    test('a description without an end tag leaves the page as it is', () {
      const xml = '<feed><entry><content type="text">open';
      expect(descriptionsAsText(xml), xml);
    });
  });

  group('stripHtml', () {
    test('a script and a style sheet go with their bodies', () {
      expect(
        stripHtml(
          '<style>p { color: red }</style><p>Text</p><SCRIPT type="text/javascript">alert("x < y")</SCRIPT> end',
        ),
        'Text\n\n end',
      );
    });

    test('markup that is escaped a second time is removed too', () {
      expect(
        stripHtml('&lt;script&gt;(function(){run()})()&lt;/script&gt;&lt;img src="x"&gt;The summary.'),
        'The summary.',
      );
      expect(stripHtml('&lt;p&gt;Twice&lt;/p&gt;'), 'Twice');
    });

    test('text with comparison signs stays', () {
      expect(stripHtml('1 &lt; 2 and 3 &gt; 2'), '1 < 2 and 3 > 2');
      expect(stripHtml('Tom &amp;amp; Jerry'), 'Tom &amp; Jerry');
    });
  });

  test('a page that cannot be parsed gives a clear message', () {
    expect(
      () => parseOpdsFeed('<feed><entry><title>broken</entry></feed>', 'http://h/'),
      throwsA(
        isA<OpdsParseException>().having(
          (e) => e.message,
          'message',
          startsWith('The catalog sent a page with errors.'),
        ),
      ),
    );
    expect(
      () => parseOpdsFeed('<html><body>Login</body></html>', 'http://h/'),
      throwsA(isA<OpdsParseException>().having((e) => e.message, 'message', contains('not an OPDS catalog'))),
    );
  });
}
