// OPDS 1.x (Atom) feed model and parser. Link handling follows
// koreader/plugins/opds.koplugin/opdsbrowser.lua:
//   catalog_type     application/atom+xml
//   search_type      application/opensearchdescription+xml
//   acquisition_rel  ^http://opds-spec.org/acquisition
//   thumbnail_rel    http://opds-spec.org/image/thumbnail (and .../thumbnail)
//   image_rel        http://opds-spec.org/image (and .../cover)
import 'package:xml/xml.dart';

class OpdsLink {
  const OpdsLink({required this.href, this.rel = '', this.type = '', this.title = ''});

  final String href;
  final String rel;
  final String type;
  final String title;

  bool get isAcquisition => rel.startsWith('http://opds-spec.org/acquisition');
  bool get isCatalog => type.contains('application/atom+xml') || type.contains('opds-catalog');
  bool get isThumbnail => rel == 'http://opds-spec.org/image/thumbnail' || rel == 'http://opds-spec.org/thumbnail';
  bool get isImage => rel == 'http://opds-spec.org/image' || rel == 'http://opds-spec.org/cover';
}

/// One downloadable format of a book.
class OpdsAcquisition {
  const OpdsAcquisition({required this.href, required this.type, this.title = ''});

  final String href;
  final String type;
  final String title;

  /// Short label for the format, for example EPUB or FB2.
  String get label {
    final t = type.toLowerCase();
    if (t.contains('epub')) return 'EPUB';
    if (t.contains('fb2') || t.contains('fictionbook')) return t.contains('zip') ? 'FB2 (zip)' : 'FB2';
    if (t.contains('pdf')) return 'PDF';
    if (t.contains('mobi')) return 'MOBI';
    if (t.contains('azw')) return 'AZW3';
    if (t.contains('djvu')) return 'DJVU';
    if (t.contains('cbz') || t.contains('comic')) return 'CBZ';
    if (t.contains('text/plain')) return 'TXT';
    final slash = t.lastIndexOf('/');
    return slash >= 0 ? t.substring(slash + 1).toUpperCase() : t.toUpperCase();
  }

  /// This app reads EPUB and FB2.
  bool get isSupported => label == 'EPUB' || label.startsWith('FB2');

  /// File extension for the download.
  String get extension {
    switch (label) {
      case 'EPUB':
        return '.epub';
      case 'FB2':
        return '.fb2';
      case 'FB2 (zip)':
        return '.fb2.zip';
      default:
        return '';
    }
  }
}

class OpdsEntry {
  const OpdsEntry({
    required this.id,
    required this.title,
    this.authors = const [],
    this.summary = '',
    this.navigationHref,
    this.acquisitions = const [],
    this.thumbnailHref,
    this.imageHref,
    this.updated,
  });

  final String id;
  final String title;
  final List<String> authors;
  final String summary;

  /// Link to a sub-catalog, for navigation entries.
  final String? navigationHref;
  final List<OpdsAcquisition> acquisitions;
  final String? thumbnailHref;
  final String? imageHref;
  final String? updated;

  bool get isBook => acquisitions.isNotEmpty;
}

class OpdsFeed {
  const OpdsFeed({
    required this.title,
    required this.entries,
    this.nextHref,
    this.searchDescriptionHref,
    this.searchTemplate,
  });

  final String title;
  final List<OpdsEntry> entries;
  final String? nextHref;

  /// OpenSearch description document (to fetch for the template).
  final String? searchDescriptionHref;

  /// Search URL with {searchTerms}, when the feed gives one directly.
  final String? searchTemplate;

  bool get hasSearch => searchDescriptionHref != null || searchTemplate != null;
}

class OpdsParseException implements Exception {
  OpdsParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _resolve(Uri base, String href) {
  // Keep {searchTerms} placeholders as they are.
  final protected = href.replaceAll('{', '%7B').replaceAll('}', '%7D');
  return base.resolve(protected).toString().replaceAll('%7B', '{').replaceAll('%7D', '}');
}

Iterable<XmlElement> _children(XmlElement e, String local) => e.childElements.where((c) => c.name.local == local);

String _text(XmlElement e, String local) {
  final c = _children(e, local).firstOrNull;
  return c?.innerText.trim() ?? '';
}

List<OpdsLink> _links(XmlElement e, Uri base) => [
  for (final l in _children(e, 'link'))
    if ((l.getAttribute('href') ?? '').isNotEmpty)
      OpdsLink(
        href: _resolve(base, l.getAttribute('href')!),
        rel: l.getAttribute('rel') ?? '',
        type: l.getAttribute('type') ?? '',
        title: l.getAttribute('title') ?? '',
      ),
];

/// Parses an Atom OPDS feed. [url] is the feed address, for relative links.
OpdsFeed parseOpdsFeed(String xml, String url) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw OpdsParseException('This is not an OPDS catalog (${e.message}).');
  }
  final feed = doc.rootElement;
  if (feed.name.local != 'feed') {
    throw OpdsParseException('This is not an OPDS catalog (no Atom feed).');
  }
  final base = Uri.parse(url);
  final feedLinks = _links(feed, base);
  String? next;
  String? osd;
  String? template;
  for (final l in feedLinks) {
    if (l.rel == 'next') next ??= l.href;
    if (l.rel == 'search') {
      if (l.type.contains('opensearchdescription')) {
        osd ??= l.href;
      } else if (l.href.contains('{searchTerms}')) {
        template ??= l.href;
      }
    }
  }

  final entries = <OpdsEntry>[];
  for (final e in _children(feed, 'entry')) {
    final links = _links(e, base);
    final acquisitions = [
      for (final l in links)
        if (l.isAcquisition && !l.rel.endsWith('/borrow')) OpdsAcquisition(href: l.href, type: l.type, title: l.title),
    ];
    String? nav;
    if (acquisitions.isEmpty) {
      for (final l in links) {
        if (l.isCatalog || l.rel == 'subsection' || l.rel == 'http://opds-spec.org/subsection') {
          nav = l.href;
          break;
        }
      }
    }
    final content = _text(e, 'content');
    entries.add(
      OpdsEntry(
        id: _text(e, 'id'),
        title: _text(e, 'title'),
        authors: [for (final a in _children(e, 'author')) _text(a, 'name')].where((n) => n.isNotEmpty).toList(),
        summary: content.isNotEmpty ? content : _text(e, 'summary'),
        navigationHref: nav,
        acquisitions: acquisitions,
        thumbnailHref: links.where((l) => l.isThumbnail).firstOrNull?.href,
        imageHref: links.where((l) => l.isImage).firstOrNull?.href,
        updated: _text(e, 'updated'),
      ),
    );
  }
  return OpdsFeed(
    title: _text(feed, 'title'),
    entries: entries,
    nextHref: next,
    searchDescriptionHref: osd,
    searchTemplate: template,
  );
}

/// Reads the Atom search template from an OpenSearch description document.
String? parseOpenSearchTemplate(String xml, String url) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    return null;
  }
  final base = Uri.parse(url);
  String? any;
  for (final u in doc.rootElement.childElements.where((c) => c.name.local == 'Url')) {
    final t = u.getAttribute('template');
    if (t == null) continue;
    final type = u.getAttribute('type') ?? '';
    final resolved = _resolve(base, t);
    if (type.contains('atom')) return resolved;
    any ??= resolved;
  }
  return any;
}

/// Plain text from an HTML summary (calibre-web sends HTML).
String stripHtml(String s) => s
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();
