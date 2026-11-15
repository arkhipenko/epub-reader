// The format table: which files the library takes, the style sheet rule,
// OPDS media types, and the scan rule for text and office documents.
import 'dart:io';

import 'package:epub_reader/library/book_formats.dart';
import 'package:epub_reader/library/library_scanner.dart';
import 'package:epub_reader/library/library_settings.dart';
import 'package:epub_reader/opds/opds_feed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('format table', () {
    test('extensions are lower case, start with a dot and are not repeated', () {
      final seen = <String>{};
      for (final f in kBookFormats) {
        expect(f.extension, startsWith('.'));
        expect(f.extension, f.extension.toLowerCase());
        expect(seen.add(f.extension), isTrue, reason: f.extension);
        for (final m in f.mimeTypes) {
          expect(m, m.toLowerCase());
        }
      }
    });

    test('a media type names one format', () {
      final seen = <String>{};
      for (final f in kBookFormats) {
        for (final m in f.mimeTypes) {
          expect(seen.add(m), isTrue, reason: m);
        }
      }
    });

    test('formatOfPath ignores case and takes the longest extension', () {
      expect(formatOfPath('/a/Book.EPUB')?.label, 'EPUB');
      expect(formatOfPath('a.fb2.zip')?.extension, '.fb2.zip');
      expect(formatOfPath('a.txt.zip')?.extension, '.txt.zip');
      expect(formatOfPath('a.html.zip')?.extension, '.html.zip');
      expect(formatOfPath('a.mobi')?.group, FormatGroup.book);
      expect(formatOfPath('a.docx')?.group, FormatGroup.document);
    });

    test('files that the reader does not open have no format', () {
      for (final name in ['a.pdf', 'a.djvu', 'a.cbz', 'a.azw3', 'a.zip', 'a.log', 'a.xml', 'a.svg', 'a.sh', 'a']) {
        expect(formatOfPath(name), isNull, reason: name);
      }
    });

    test('the FB2 style sheet is for FB2, FB3 and TXT', () {
      final fb2 = {
        for (final f in kBookFormats)
          if (f.fb2Styles) f.extension,
      };
      expect(fb2, {'.fb2', '.fb2.zip', '.fbz', '.fb3', '.txt', '.txt.zip'});
    });

    test('isBookFile takes documents only on request', () {
      for (final name in ['a.epub', 'a.fb2', 'a.fbz', 'a.fb3', 'a.mobi', 'a.azw', 'a.prc', 'a.pdb', 'a.tcr', 'a.chm']) {
        expect(isBookFile(name), isTrue, reason: name);
      }
      for (final name in [
        'a.txt',
        'a.rtf',
        'a.doc',
        'a.docx',
        'a.docm',
        'a.odt',
        'a.htm',
        'a.html',
        'a.xhtml',
        'a.md',
      ]) {
        expect(isBookFile(name), isFalse, reason: name);
        expect(isBookFile(name, documents: true), isTrue, reason: name);
      }
      expect(isBookFile('a.pdf', documents: true), isFalse);
    });
  });

  group('OPDS media types', () {
    OpdsAcquisition acq(String type) => OpdsAcquisition(href: 'http://h/x', type: type);

    test('formats that the reader opens', () {
      expect(acq('application/epub+zip').label, 'EPUB');
      expect(acq('application/x-mobipocket-ebook').label, 'MOBI');
      expect(acq('application/x-mobipocket-ebook').extension, '.mobi');
      expect(acq('text/plain; charset=utf-8').extension, '.txt');
      expect(acq('text/html').extension, '.html');
      expect(acq('application/rtf').extension, '.rtf');
      expect(acq('application/fb2+zip').extension, '.fb2.zip');
      expect(acq('application/x-fictionbook+xml').extension, '.fb2');
      expect(acq('application/msword').isSupported, isTrue);
      expect(acq('application/vnd.openxmlformats-officedocument.wordprocessingml.document').extension, '.docx');
    });

    test('other names of EPUB and FB2 still work', () {
      expect(acq('application/x-epub+zip').extension, '.epub');
      expect(acq('application/x-zip-compressed-fb2').extension, '.fb2.zip');
    });

    test('formats that the reader does not open', () {
      for (final t in ['application/pdf', 'application/x-mobi8-ebook', 'image/vnd.djvu', 'application/x-cbz']) {
        expect(acq(t).isSupported, isFalse, reason: t);
        expect(acq(t).extension, '', reason: t);
      }
      expect(acq('application/pdf').label, 'PDF');
      expect(acq('application/x-mobi8-ebook').label, 'AZW3');
    });
  });

  group('scan rule', () {
    late Directory root;

    Future<void> put(String rel) async {
      final f = File([root.path, ...rel.split('/')].join(Platform.pathSeparator));
      await f.parent.create(recursive: true);
      await f.writeAsBytes(List<int>.filled(8, 7));
    }

    Set<String> names(List<FoundFile> found) => {for (final f in found) f.path.split(RegExp(r'[/\\]')).last};

    setUp(() async {
      root = await Directory.systemTemp.createTemp('formats');
      await put('folder/novel.mobi');
      await put('folder/help.chm');
      await put('folder/notes.txt');
      await put('folder/page.html');
      await put('folder/scan.pdf');
      await put('own/letter.docx');
      await put('own/story.fb3');
    });

    tearDown(() => root.delete(recursive: true));

    test('book formats everywhere, documents only in the own folder', () {
      final folder = '${root.path}${Platform.pathSeparator}folder';
      final own = '${root.path}${Platform.pathSeparator}own';
      final found = walkLibrary([folder, own], const {}, ownFolder: own);
      expect(names(found), {'novel.mobi', 'help.chm', 'letter.docx', 'story.fb3'});
    });

    test('with the switch on, documents in the folders too', () {
      final folder = '${root.path}${Platform.pathSeparator}folder';
      final own = '${root.path}${Platform.pathSeparator}own';
      final found = walkLibrary([folder, own], const {}, documents: true, ownFolder: own);
      expect(names(found), {'novel.mobi', 'help.chm', 'notes.txt', 'page.html', 'letter.docx', 'story.fb3'});
    });
  });

  test('the documents switch is saved and is off at first', () {
    expect(const LibrarySettings().scanDocuments, isFalse);
    expect(LibrarySettings.decode('{"folders":["/a"]}').scanDocuments, isFalse);
    final saved = const LibrarySettings(folders: ['/a']).copyWith(scanDocuments: true).encode();
    expect(LibrarySettings.decode(saved).scanDocuments, isTrue);
    expect(LibrarySettings.decode(saved).folders, ['/a']);
  });
}
