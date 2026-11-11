// The engine runs in its own isolate. It owns the native library and the
// open document. The UI isolate talks to it through messages only, because
// every FFI call blocks.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'cre_bindings.dart';
import 'text_language.dart';

/// Layout settings for the open book. Sizes are physical pixels.
/// A change to any field except the colors and the gamma index makes the
/// engine lay out the book again.
class EngineLayout {
  const EngineLayout({
    required this.fontFace,
    required this.fontSize,
    required this.interlinePercent,
    required this.marginLeft,
    required this.marginTop,
    required this.marginRight,
    required this.marginBottom,
    required this.hyphenation,
    required this.embeddedStyles,
    required this.embeddedFonts,
    required this.backgroundRgb,
    required this.textRgb,
    this.textLanguage,
    this.props = const {},
    this.extraCss = '',
    this.gammaIndex = 15,
  });

  final String fontFace;
  final int fontSize;
  final int interlinePercent;
  final int marginLeft;
  final int marginTop;
  final int marginRight;
  final int marginBottom;
  final bool hyphenation;
  final bool embeddedStyles;
  final bool embeddedFonts;
  final int backgroundRgb;
  final int textRgb;

  /// Language tag for hyphenation and line breaking, or null to use the
  /// language of the book.
  final String? textLanguage;

  /// More engine properties, by crengine property name.
  final Map<String, int> props;

  /// CSS that the engine applies after its base style sheet (style tweaks).
  final String extraCss;

  /// Font contrast: index into the crengine gamma table (15 is gamma 1.0).
  final int gammaIndex;

  Map<String, Object?> toMap() => {
    'fontFace': fontFace,
    'fontSize': fontSize,
    'interline': interlinePercent,
    'margins': [marginLeft, marginTop, marginRight, marginBottom],
    'hyph': hyphenation,
    'embStyles': embeddedStyles,
    'embFonts': embeddedFonts,
    'bg': backgroundRgb,
    'fg': textRgb,
    'lang': textLanguage,
    'props': props,
    'css': extraCss,
    'gamma': gammaIndex,
  };
}

class TocEntry {
  const TocEntry({required this.title, required this.xpointer, required this.page, required this.depth});

  final String title;
  final String xpointer;
  final int page;
  final int depth;
}

class BookInfo {
  const BookInfo({
    required this.title,
    required this.authors,
    required this.language,
    required this.series,
    required this.format,
  });

  final String title;
  final String authors;
  final String language;
  final String series;
  final String format;
}

/// The reading position as the engine reports it.
class EnginePosition {
  const EnginePosition({required this.page, required this.pageCount, required this.percent, required this.xpointer});

  /// 1-based page.
  final int page;
  final int pageCount;

  /// crengine position percent, 0 to 10000.
  final int percent;

  /// KOReader-compatible XPointer of the reading position. It is the top
  /// of the page after a page turn. After a jump to an XPointer, or a new
  /// layout, it is that XPointer, which can be in the middle of the page.
  final String? xpointer;

  static EnginePosition fromMap(Map m) => EnginePosition(
    page: m['page'] as int,
    pageCount: m['pages'] as int,
    percent: m['percent'] as int,
    xpointer: m['xpointer'] as String?,
  );
}

/// Result of a layout change: new page count, TOC page numbers and position.
class LayoutResult {
  const LayoutResult({required this.position, required this.toc});

  final EnginePosition position;
  final List<TocEntry> toc;
}

class OpenResult {
  const OpenResult({required this.info, required this.position, required this.toc});

  final BookInfo info;
  final EnginePosition position;
  final List<TocEntry> toc;
}

/// A text selection: XPointers of its start and end (end excluded) and the text.
class TextSelection {
  const TextSelection({required this.text, required this.pos0, required this.pos1});

  final String text;
  final String pos0;
  final String pos1;
}

/// A rectangle in page pixels of the current page.
class PageRect {
  const PageRect(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool contains(double x, double y) => x >= left && x <= right && y >= top && y <= bottom;
}

class SearchHit {
  const SearchHit({
    required this.start,
    required this.end,
    required this.page,
    required this.text,
    required this.before,
    required this.after,
  });

  final String start;
  final String end;

  /// Page in the current layout.
  final int page;
  final String text;
  final String before;
  final String after;
}

/// A link on the current page and its line boxes.
class PageLink {
  const PageLink(this.href, this.boxes);

  final String href;
  final List<PageRect> boxes;

  bool get isInternal => href.startsWith('#');
}

class LinkTarget {
  const LinkTarget({required this.href, required this.xpointer});

  final String href;

  /// XPointer of the link element itself.
  final String xpointer;

  /// Internal links start with "#" in crengine; others go outside the book.
  bool get isInternal => href.startsWith('#');
}

/// Library metadata of a book file (KOReader BookInfoManager data).
class BookFileInfo {
  const BookFileInfo({
    required this.title,
    required this.authors,
    required this.language,
    required this.series,
    required this.seriesNumber,
    required this.description,
    required this.format,
    required this.hasCover,
  });

  final String title;
  final String authors;
  final String language;
  final String series;
  final int seriesNumber;
  final String description;
  final String format;
  final bool hasCover;
}

class EngineException implements Exception {
  EngineException(this.message);

  final String message;

  @override
  String toString() => 'EngineException: $message';
}

class CreEngine {
  CreEngine._(this._isolate, this._toWorker, this._fromWorker);

  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _fromWorker;
  final Map<int, Completer<Object?>> _pending = {};
  int _nextId = 1;

  /// Font faces that the engine registered at start.
  List<String> fontFaces = const [];

  /// Starts the engine isolate and initializes fonts, hyphenation and cache.
  /// [dataDir] holds the fonts, css and hyph folders.
  static Future<CreEngine> start({required String dataDir, required String cacheDir}) async {
    final fromWorker = ReceivePort();
    final isolate = await Isolate.spawn(_workerMain, fromWorker.sendPort, debugName: 'cre-engine');
    final ready = Completer<SendPort>();
    late final CreEngine engine;
    fromWorker.listen((msg) {
      if (msg is SendPort) {
        ready.complete(msg);
        return;
      }
      engine._onReply(msg as List<Object?>);
    });
    final toWorker = await ready.future;
    engine = CreEngine._(isolate, toWorker, fromWorker);
    final r = (await engine._call('init', {'dataDir': dataDir, 'cacheDir': cacheDir}))! as Map;
    engine.fontFaces = (jsonDecode(r['faces'] as String) as List).cast<String>();
    return engine;
  }

  void _onReply(List<Object?> msg) {
    final completer = _pending.remove(msg[0] as int);
    if (completer == null) return;
    if (msg[1] == true) {
      completer.complete(msg[2]);
    } else {
      completer.completeError(EngineException(msg[2] as String));
    }
  }

  Future<Object?> _call(String op, [Map<String, Object?> args = const {}]) {
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _toWorker.send([id, op, args]);
    return completer.future;
  }

  static List<TocEntry> _toc(Object? json) => (jsonDecode(json as String) as List)
      .cast<Map<String, dynamic>>()
      .map(
        (e) => TocEntry(
          title: e['title'] as String,
          xpointer: e['xpointer'] as String,
          page: e['page'] as int,
          depth: e['depth'] as int,
        ),
      )
      .toList();

  /// Opens a book. When [xpointer] is given and found, the book opens there.
  /// [languageHint] is the language of the book when the library knows it:
  /// the engine then has the right language before it loads the book.
  Future<OpenResult> open(
    String path, {
    required int width,
    required int height,
    required int dpi,
    required EngineLayout layout,
    String? xpointer,
    String? languageHint,
  }) async {
    final r =
        (await _call('open', {
              'path': path,
              'width': width,
              'height': height,
              'dpi': dpi,
              'isFb2': isFb2Path(path),
              'layout': layout.toMap(),
              'xpointer': xpointer,
              'langHint': languageHint,
            }))!
            as Map;
    final info = jsonDecode(r['info'] as String) as Map<String, dynamic>;
    return OpenResult(
      info: BookInfo(
        title: info['title'] as String,
        authors: info['authors'] as String,
        language: info['language'] as String,
        series: info['series'] as String,
        format: info['format'] as String,
      ),
      position: EnginePosition.fromMap(r['pos'] as Map),
      toc: _toc(r['toc']),
    );
  }

  /// Applies new layout settings and keeps the reading position.
  Future<LayoutResult> setLayout(EngineLayout layout) async {
    final r = (await _call('setLayout', {'layout': layout.toMap()}))! as Map;
    return LayoutResult(position: EnginePosition.fromMap(r['pos'] as Map), toc: _toc(r['toc']));
  }

  /// Changes the font contrast. The page count and the position stay the
  /// same; the caller draws the pages again.
  Future<void> setGamma(int index) => _call('setGamma', {'index': index});

  /// Changes the page size and keeps the reading position.
  Future<LayoutResult> resize(int width, int height) async {
    final r = (await _call('resize', {'width': width, 'height': height}))! as Map;
    return LayoutResult(position: EnginePosition.fromMap(r['pos'] as Map), toc: _toc(r['toc']));
  }

  Future<EnginePosition> gotoPage(int page) async =>
      EnginePosition.fromMap((await _call('gotoPage', {'page': page}))! as Map);

  /// Returns null when the XPointer is not in the document.
  Future<EnginePosition?> gotoXPointer(String xpointer) async {
    final r = await _call('gotoXPointer', {'xpointer': xpointer});
    return r == null ? null : EnginePosition.fromMap(r as Map);
  }

  Future<EnginePosition> position() async => EnginePosition.fromMap((await _call('position'))! as Map);

  /// Draws [page] as RGBA8888 at the current page size. The reading
  /// position does not change. Returns null when the page does not exist.
  Future<Uint8List?> drawPage(int page, {bool invertImages = false}) async {
    final r = await _call('drawPage', {'page': page, 'invert': invertImages});
    return r == null ? null : (r as TransferableTypedData).materialize().asUint8List();
  }

  /// Text of the node at the XPointer, or null when it is not in the document.
  Future<String?> textAt(String xpointer, {int maxChars = 200}) async =>
      (await _call('textAt', {'xpointer': xpointer, 'max': maxChars})) as String?;

  Future<void> closeBook() => _call('close');

  /// Selects text between two points of the current page (page pixels).
  /// Equal points select the word at the point.
  Future<TextSelection?> select(int x0, int y0, int x1, int y1) async {
    final r = await _call('select', {
      'p': [x0, y0, x1, y1],
    });
    if (r == null) return null;
    final j = jsonDecode(r as String) as Map<String, dynamic>;
    return TextSelection(text: j['text'] as String, pos0: j['pos0'] as String, pos1: j['pos1'] as String);
  }

  Future<String?> textRange(String pos0, String pos1) async =>
      (await _call('textRange', {'a': pos0, 'b': pos1})) as String?;

  /// Boxes on the current page for each range. [ranges] maps a key to
  /// (pos0, pos1). Keys of ranges that are not on the page are left out.
  Future<Map<String, List<PageRect>>> boxes(Map<String, (String, String)> ranges) async {
    if (ranges.isEmpty) return const {};
    final r =
        (await _call('boxes', {
              'r': [
                for (final e in ranges.entries) [e.key, e.value.$1, e.value.$2],
              ],
            }))!
            as Map;
    return {
      for (final e in r.entries)
        e.key as String: [
          for (final b in (e.value as List).cast<List>()) PageRect(b[0] as int, b[1] as int, b[2] as int, b[3] as int),
        ],
    };
  }

  Future<List<SearchHit>> findAll(String pattern, {bool caseInsensitive = true, int maxHits = 1000}) async {
    final r = await _call('findAll', {'q': pattern, 'ci': caseInsensitive, 'max': maxHits});
    if (r == null) return const [];
    return [
      for (final m in (jsonDecode(r as String) as List).cast<Map<String, dynamic>>())
        SearchHit(
          start: m['start'] as String,
          end: m['end'] as String,
          page: m['page'] as int,
          text: m['text'] as String,
          before: m['before'] as String,
          after: m['after'] as String,
        ),
    ];
  }

  Future<LinkTarget?> linkAt(int x, int y) async {
    final r = await _call('linkAt', {'x': x, 'y': y});
    if (r == null) return null;
    final j = jsonDecode(r as String) as Map<String, dynamic>;
    return LinkTarget(href: j['href'] as String, xpointer: j['xpointer'] as String);
  }

  /// Links on the current page.
  Future<List<PageLink>> pageLinks() async {
    final r = await _call('pageLinks');
    if (r == null) return const [];
    return [
      for (final l in (jsonDecode(r as String) as List).cast<Map<String, dynamic>>())
        PageLink(l['href'] as String, [
          for (final b in (l['boxes'] as List).cast<List>())
            PageRect(b[0] as int, b[1] as int, b[2] as int, b[3] as int),
        ]),
    ];
  }

  /// Follows an internal link. Returns the new position, or null.
  Future<EnginePosition?> gotoLink(String href) async {
    final r = await _call('gotoLink', {'href': href});
    return r == null ? null : EnginePosition.fromMap(r as Map);
  }

  /// Page of each XPointer in the current layout (0: not in the document).
  Future<Map<String, int>> pagesOf(Iterable<String> xpointers) async {
    final list = xpointers.toSet().toList();
    if (list.isEmpty) return const {};
    final r = (await _call('pagesOf', {'x': list}))! as List;
    return {for (var i = 0; i < list.length; i++) list[i]: r[i] as int};
  }

  /// <0 when [a] is before [b], 0 when equal or unknown, >0 when after.
  Future<int> compare(String a, String b) async => (await _call('compare', {'a': a, 'b': b}))! as int;

  /// Reads library metadata without opening the book for reading. Writes
  /// the cover image to [coverOut] when there is one. Returns null when the
  /// engine cannot read the file.
  Future<BookFileInfo?> bookInfo(String path, String coverOut) async {
    final r = await _call('bookInfo', {'path': path, 'cover': coverOut});
    if (r == null) return null;
    final j = jsonDecode(r as String) as Map<String, dynamic>;
    return BookFileInfo(
      title: j['title'] as String,
      authors: j['authors'] as String,
      language: j['language'] as String,
      series: j['series'] as String,
      seriesNumber: j['seriesNumber'] as int,
      description: j['description'] as String,
      format: j['format'] as String,
      hasCover: j['cover'] as bool,
    );
  }

  void dispose() {
    _fromWorker.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  static bool isFb2Path(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.fb2') || p.endsWith('.fb2.zip') || p.endsWith('.fbz');
  }
}

// ---------------------------------------------------------------------------
// Engine isolate.

void _workerMain(SendPort toMain) {
  final requests = ReceivePort();
  toMain.send(requests.sendPort);
  final worker = _Worker();
  requests.listen((msg) {
    final m = msg as List<Object?>;
    final id = m[0] as int;
    try {
      final result = worker.handle(m[1] as String, (m[2] as Map).cast<String, Object?>());
      toMain.send([id, true, result]);
    } catch (e, st) {
      toMain.send([id, false, '$e\n$st']);
    }
  });
}

class _Worker {
  late final CreBindings _b;
  String _dataDir = '';
  Pointer<CreDoc> _doc = nullptr;
  int _width = 0;
  int _height = 0;

  /// The reading position (KOReader ReaderRolling.xpointer). A page turn
  /// sets it to the top of the new page. A jump to an XPointer sets it to
  /// that XPointer. A new layout returns to it and does not change it: the
  /// top of the page it falls on can be earlier text, and a position taken
  /// from there moves one page back with each further layout.
  String? _anchor;

  Object? handle(String op, Map<String, Object?> a) {
    switch (op) {
      case 'init':
        return _init(a['dataDir'] as String, a['cacheDir'] as String);
      case 'open':
        return _open(a);
      case 'setLayout':
        _requireDoc();
        return _relayout(() => _applyLayout(_doc, (a['layout'] as Map).cast<String, Object?>()));
      case 'setGamma':
        _b.setGammaIndex(a['index'] as int);
        return null;
      case 'resize':
        _requireDoc();
        return _relayout(() {
          _width = a['width'] as int;
          _height = a['height'] as int;
          _b.docResize(_doc, _width, _height);
        });
      case 'gotoPage':
        _requireDoc();
        _b.docGotoPage(_doc, a['page'] as int);
        _anchor = _b.docGetXPointer(_doc);
        return _position();
      case 'gotoXPointer':
        _requireDoc();
        final xp = a['xpointer'] as String;
        if (!_b.docGotoXPointer(_doc, xp)) return null;
        _anchor = xp;
        return _position();
      case 'position':
        _requireDoc();
        return _position();
      case 'drawPage':
        _requireDoc();
        return _drawPage(a['page'] as int, a['invert'] as bool);
      case 'textAt':
        _requireDoc();
        return _b.docTextAtXPointer(_doc, a['xpointer'] as String, a['max'] as int);
      case 'close':
        _close();
        return null;
      case 'bookInfo':
        return _b.bookInfo(a['path'] as String, a['cover'] as String);
      case 'select':
        _requireDoc();
        final p = (a['p'] as List).cast<int>();
        return _b.docSelect(_doc, p[0], p[1], p[2], p[3]);
      case 'textRange':
        _requireDoc();
        return _b.docTextRange(_doc, a['a'] as String, a['b'] as String);
      case 'boxes':
        _requireDoc();
        final out = <String, Object?>{};
        for (final r in (a['r'] as List).cast<List>()) {
          final json = _b.docRangeBoxes(_doc, r[1] as String, r[2] as String);
          if (json == null) continue;
          final list = jsonDecode(json) as List;
          if (list.isNotEmpty) out[r[0] as String] = list;
        }
        return out;
      case 'findAll':
        _requireDoc();
        return _b.docFindAll(_doc, a['q'] as String, a['ci'] as bool, a['max'] as int);
      case 'linkAt':
        _requireDoc();
        return _b.docLinkAt(_doc, a['x'] as int, a['y'] as int);
      case 'pageLinks':
        _requireDoc();
        return _b.docPageLinks(_doc);
      case 'gotoLink':
        _requireDoc();
        if (!_b.docGotoLink(_doc, a['href'] as String)) return null;
        _anchor = _b.docGetXPointer(_doc);
        return _position();
      case 'pagesOf':
        _requireDoc();
        return [for (final x in (a['x'] as List).cast<String>()) _b.docPageOfXPointer(_doc, x)];
      case 'compare':
        _requireDoc();
        return _b.docCompare(_doc, a['a'] as String, a['b'] as String);
    }
    throw EngineException('unknown operation $op');
  }

  Object? _init(String dataDir, String cacheDir) {
    _b = CreBindings.load();
    final v = _b.ffiVersion();
    if (v != kCreFfiVersion) {
      throw EngineException('libcre_ffi version $v, expected $kCreFfiVersion');
    }
    _dataDir = dataDir;
    Directory(cacheDir).createSync(recursive: true);
    _b.init(cacheDir, 256, '$dataDir/hyph/');
    final fontDir = Directory('$dataDir/fonts');
    if (fontDir.existsSync()) {
      final files = fontDir.listSync().whereType<File>().map((f) => f.path).toList()..sort();
      for (final f in files) {
        final lower = f.toLowerCase();
        if (lower.endsWith('.ttf') || lower.endsWith('.otf')) _b.registerFont(f);
      }
    }
    _b.fontsDone('Noto Serif');
    return {'faces': _b.fontFacesJson() ?? '[]', 'dom': _b.latestDomVersion()};
  }

  /// Base style sheet of the open book (epub.css or fb2.css).
  String _cssFile = '';

  /// The style tweak CSS that the engine has now. Null: none set yet.
  String? _appliedCss;

  /// The language of the open book, from the library at first and from the
  /// book after the load. Null: not known.
  String? _bookLanguage;

  /// Sets the language for hyphenation and line breaking rules (KOReader
  /// CreDocument:setTextMainLang). The language is global to the engine, so
  /// it stays from the book before. The engine does nothing when the tag is
  /// the one it has.
  void _setLanguage(Pointer<CreDoc> d, String tag) => _b.docSetString(d, 'crengine.textlang.main.lang', tag);

  void _applyLayout(Pointer<CreDoc> d, Map<String, Object?> l) {
    final m = (l['margins'] as List).cast<int>();
    // KOReader CreDocument:setStyleSheet(): the base file, then the tweaks.
    final css = l['css'] as String? ?? '';
    if (css != _appliedCss) {
      _b.docSetStylesheet(d, _cssFile, css);
      _appliedCss = css;
    }
    _b.setGammaIndex(l['gamma'] as int? ?? 15);
    for (final e in ((l['props'] as Map?) ?? const {}).entries) {
      _b.docSetInt(d, e.key as String, e.value as int);
    }
    // The language set for this book, else the language of the book, else
    // the engine default (KOReader ReaderTypography).
    _setLanguage(d, fixLanguageTag(l['lang'] as String?) ?? _bookLanguage ?? kDefaultTextLanguage);
    _b.docSetFontFace(d, l['fontFace'] as String);
    _b.docSetFontSize(d, l['fontSize'] as int);
    _b.docSetInterline(d, l['interline'] as int);
    _b.docSetMargins(d, m[0], m[1], m[2], m[3]);
    _b.docSetColors(d, l['bg'] as int, l['fg'] as int);
    _b.docSetString(d, 'crengine.textlang.embedded.langs.enabled', '1');
    _b.docSetString(d, 'crengine.textlang.hyphenation.enabled', (l['hyph'] as bool) ? '1' : '0');
    _b.docSetInt(d, 'crengine.doc.embedded.styles.enabled', (l['embStyles'] as bool) ? 1 : 0);
    _b.docSetInt(d, 'crengine.doc.embedded.fonts.enabled', (l['embFonts'] as bool) ? 1 : 0);
  }

  Object? _open(Map<String, Object?> a) {
    _close();
    _width = a['width'] as int;
    _height = a['height'] as int;
    final d = _b.docNew(_width, _height);
    _b.docApplyDefaults(d, a['dpi'] as int);
    // KOReader CreDocument:init(): fb2.css for FB2 and TXT, epub.css for the rest.
    final css = (a['isFb2'] as bool) ? 'fb2.css' : 'epub.css';
    _cssFile = '$_dataDir/css/$css';
    _appliedCss = null;
    _bookLanguage = fixLanguageTag(a['langHint'] as String?);
    final layout = (a['layout'] as Map).cast<String, Object?>();
    // The language is set before the load when it is known. A change after
    // the load makes the engine prepare all styles again (KOReader
    // ReaderTypography:onReadSettings).
    _applyLayout(d, layout);
    if (!_b.docLoad(d, a['path'] as String)) {
      _b.docFree(d);
      throw EngineException('cannot open ${a['path']}');
    }
    _doc = d;
    // The book is loaded, so its language is known for sure (KOReader
    // ReaderTypography:onPreRenderDocument). A language set for this book
    // stays.
    final loaded = fixLanguageTag((jsonDecode(_b.docInfoJson(d) ?? '{}') as Map)['language'] as String?);
    if (loaded != null) _bookLanguage = loaded;
    if (fixLanguageTag(layout['lang'] as String?) == null && _bookLanguage != null) {
      _setLanguage(d, _bookLanguage!);
    }
    _b.docRender(_doc);
    final xp = a['xpointer'] as String?;
    final found = xp != null && xp.isNotEmpty && _b.docGotoXPointer(_doc, xp);
    _anchor = found ? xp : _b.docGetXPointer(_doc);
    return {'info': _b.docInfoJson(_doc) ?? '{}', 'toc': _b.docTocJson(_doc) ?? '[]', 'pos': _position()};
  }

  /// Runs [change], lays the book out again, and returns to the reading
  /// position.
  Object? _relayout(void Function() change) {
    final xp = _anchor ??= _b.docGetXPointer(_doc);
    change();
    _b.docRequestRender(_doc);
    _b.docRender(_doc);
    if (xp != null) _b.docGotoXPointer(_doc, xp);
    return {'toc': _b.docTocJson(_doc) ?? '[]', 'pos': _position()};
  }

  Map<String, Object?> _position() => {
    'page': _b.docCurrentPage(_doc),
    'pages': _b.docPageCount(_doc),
    'percent': _b.docPercent(_doc),
    'xpointer': _anchor ?? _b.docGetXPointer(_doc),
  };

  Object? _drawPage(int page, bool invertImages) {
    final size = _width * _height * 4;
    final buf = calloc<Uint8>(size);
    try {
      final flags = invertImages ? kDrawInvertImages : 0;
      if (_b.docDrawPage(_doc, page, buf, _width, _height, flags) != 1) return null;
      return TransferableTypedData.fromList([buf.asTypedList(size)]);
    } finally {
      calloc.free(buf);
    }
  }

  void _close() {
    if (_doc != nullptr) {
      _b.docFree(_doc);
      _doc = nullptr;
    }
    _anchor = null;
  }

  void _requireDoc() {
    if (_doc == nullptr) throw EngineException('no open document');
  }
}
