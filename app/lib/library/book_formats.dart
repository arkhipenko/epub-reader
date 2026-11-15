// The file formats that the reader opens. One table for the library scan,
// the "open file" entry, the OPDS downloads and the style sheet choice.
//
// The list follows the file types that KOReader gives to the same engine
// (frontend/document/credocument.lua). KOReader also registers log, xml,
// svg, sh and py files and plain zip archives; those are not books and are
// not offered here. PDF, DjVu and comics need another engine. The newer
// Kindle format (azw3, KF8) and files with copy protection do not open.

/// Shown when the engine cannot open a file (copy protection, the newer
/// Kindle format, a damaged file).
const String kCannotOpenMessage =
    'This file cannot be opened. It may be copy-protected or in a format that the reader does not support.';

/// How a format enters the library.
enum FormatGroup {
  /// Book formats. The library scan always takes them.
  book,

  /// Text and office documents. A scanned folder can hold many of them
  /// that are not books, so the scan takes them only when the owner turns
  /// that on. A file that the owner opens or downloads is always taken.
  document,
}

class BookFormat {
  const BookFormat(this.extension, this.label, this.group, {this.fb2Styles = false, this.mimeTypes = const []});

  /// File extension in lower case, with the dot. It can have two parts.
  final String extension;

  /// Short name for buttons and the book information.
  final String label;
  final FormatGroup group;

  /// The engine base style sheet: fb2.css for FB2, FB3 and TXT, epub.css
  /// for the rest (the KOReader rule).
  final bool fb2Styles;

  /// Media types of this format in OPDS catalogs.
  final List<String> mimeTypes;
}

const List<BookFormat> kBookFormats = [
  // Book formats.
  BookFormat('.epub', 'EPUB', FormatGroup.book, mimeTypes: ['application/epub+zip', 'application/epub']),
  BookFormat('.epub3', 'EPUB', FormatGroup.book),
  BookFormat(
    '.fb2',
    'FB2',
    FormatGroup.book,
    fb2Styles: true,
    mimeTypes: ['application/fb2', 'application/x-fictionbook+xml', 'text/fb2+xml'],
  ),
  BookFormat('.fb2.zip', 'FB2 (zip)', FormatGroup.book, fb2Styles: true, mimeTypes: ['application/fb2+zip']),
  BookFormat('.fbz', 'FB2 (zip)', FormatGroup.book, fb2Styles: true),
  BookFormat('.fb3', 'FB3', FormatGroup.book, fb2Styles: true, mimeTypes: ['application/fb3']),
  BookFormat('.mobi', 'MOBI', FormatGroup.book, mimeTypes: ['application/x-mobipocket-ebook']),
  BookFormat('.azw', 'AZW', FormatGroup.book, mimeTypes: ['application/vnd.amazon.ebook']),
  BookFormat('.prc', 'PRC', FormatGroup.book),
  BookFormat('.pdb', 'PDB', FormatGroup.book, mimeTypes: ['application/vnd.palm']),
  BookFormat('.tcr', 'TCR', FormatGroup.book, mimeTypes: ['application/tcr']),
  BookFormat('.chm', 'CHM', FormatGroup.book, mimeTypes: ['application/vnd.ms-htmlhelp']),
  // Text and office documents.
  BookFormat('.txt', 'TXT', FormatGroup.document, fb2Styles: true, mimeTypes: ['text/plain']),
  BookFormat('.txt.zip', 'TXT (zip)', FormatGroup.document, fb2Styles: true, mimeTypes: ['application/txt+zip']),
  BookFormat('.rtf', 'RTF', FormatGroup.document, mimeTypes: ['application/rtf', 'text/rtf']),
  BookFormat('.rtf.zip', 'RTF (zip)', FormatGroup.document, mimeTypes: ['application/rtf+zip']),
  BookFormat('.doc', 'DOC', FormatGroup.document, mimeTypes: ['application/msword']),
  BookFormat(
    '.docx',
    'DOCX',
    FormatGroup.document,
    mimeTypes: ['application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'application/docx'],
  ),
  BookFormat('.docm', 'DOCX', FormatGroup.document, mimeTypes: ['application/vnd.ms-word.document.macroenabled.12']),
  BookFormat('.odt', 'ODT', FormatGroup.document, mimeTypes: ['application/vnd.oasis.opendocument.text']),
  BookFormat('.html', 'HTML', FormatGroup.document, mimeTypes: ['text/html']),
  BookFormat('.htm', 'HTML', FormatGroup.document),
  BookFormat('.xhtml', 'HTML', FormatGroup.document, mimeTypes: ['application/xhtml+xml']),
  BookFormat('.html.zip', 'HTML (zip)', FormatGroup.document),
  BookFormat('.htm.zip', 'HTML (zip)', FormatGroup.document),
  BookFormat('.htmlz', 'HTML (zip)', FormatGroup.document, mimeTypes: ['application/html+zip']),
  // Zipped Markdown (.md.zip) is not here: the engine does not read it.
  BookFormat('.md', 'Markdown', FormatGroup.document, mimeTypes: ['text/markdown']),
];

/// The format of a file by its name, or null when the reader does not open
/// it. The longest extension wins: "a.fb2.zip" is zipped FB2.
BookFormat? formatOfPath(String path) {
  final p = path.toLowerCase();
  BookFormat? best;
  for (final f in kBookFormats) {
    if (p.endsWith(f.extension) && (best == null || f.extension.length > best.extension.length)) best = f;
  }
  return best;
}

/// The format of an OPDS media type ("text/plain; charset=utf-8"), or null.
BookFormat? formatOfMimeType(String type) {
  final t = type.split(';').first.trim().toLowerCase();
  if (t.isEmpty) return null;
  for (final f in kBookFormats) {
    if (f.mimeTypes.contains(t)) return f;
  }
  // Catalogs use more names for EPUB and FB2 than the table holds.
  if (t.contains('epub')) return formatOfPath('.epub');
  if (t.contains('fb2') || t.contains('fictionbook')) return formatOfPath(t.contains('zip') ? '.fb2.zip' : '.fb2');
  return null;
}

/// True for a file that the library takes. [documents] also takes text and
/// office documents.
bool isBookFile(String path, {bool documents = false}) {
  final f = formatOfPath(path);
  return f != null && (documents || f.group == FormatGroup.book);
}

/// Formats for a short text, for example "EPUB, FB2, MOBI".
String formatLabels(FormatGroup group) {
  final labels = <String>[];
  for (final f in kBookFormats) {
    final l = f.label.replaceAll(' (zip)', '');
    if (f.group == group && !labels.contains(l)) labels.add(l);
  }
  return labels.join(', ');
}
