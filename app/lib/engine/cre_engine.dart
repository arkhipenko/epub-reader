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

/// Layout settings for the open book. Sizes are physical pixels.
/// A change to any field except the colors makes the engine lay out the
/// book again.
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
  const EnginePosition({
    required this.page,
    required this.pageCount,
    required this.percent,
    required this.xpointer,
  });

  /// 1-based page.
  final int page;
  final int pageCount;

  /// crengine position percent, 0 to 10000.
  final int percent;

  /// KOReader-compatible XPointer of the top of the page.
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
      .map((e) => TocEntry(
            title: e['title'] as String,
            xpointer: e['xpointer'] as String,
            page: e['page'] as int,
            depth: e['depth'] as int,
          ))
      .toList();

  /// Opens a book. When [xpointer] is given and found, the book opens there.
  Future<OpenResult> open(
    String path, {
    required int width,
    required int height,
    required int dpi,
    required EngineLayout layout,
    String? xpointer,
  }) async {
    final r = (await _call('open', {
      'path': path,
      'width': width,
      'height': height,
      'dpi': dpi,
      'isFb2': isFb2Path(path),
      'layout': layout.toMap(),
      'xpointer': xpointer,
    }))! as Map;
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

  Object? handle(String op, Map<String, Object?> a) {
    switch (op) {
      case 'init':
        return _init(a['dataDir'] as String, a['cacheDir'] as String);
      case 'open':
        return _open(a);
      case 'setLayout':
        _requireDoc();
        return _relayout(() => _applyLayout(_doc, (a['layout'] as Map).cast<String, Object?>()));
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
        return _position();
      case 'gotoXPointer':
        _requireDoc();
        if (!_b.docGotoXPointer(_doc, a['xpointer'] as String)) return null;
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

  void _applyLayout(Pointer<CreDoc> d, Map<String, Object?> l) {
    final m = (l['margins'] as List).cast<int>();
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
    _b.docSetStylesheet(d, '$_dataDir/css/$css', '');
    _applyLayout(d, (a['layout'] as Map).cast<String, Object?>());
    if (!_b.docLoad(d, a['path'] as String)) {
      _b.docFree(d);
      throw EngineException('cannot open ${a['path']}');
    }
    _doc = d;
    _b.docRender(_doc);
    final xp = a['xpointer'] as String?;
    if (xp != null && xp.isNotEmpty) _b.docGotoXPointer(_doc, xp);
    return {
      'info': _b.docInfoJson(_doc) ?? '{}',
      'toc': _b.docTocJson(_doc) ?? '[]',
      'pos': _position(),
    };
  }

  /// Runs [change], lays the book out again, and returns to the same text.
  Object? _relayout(void Function() change) {
    final xp = _b.docGetXPointer(_doc);
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
        'xpointer': _b.docGetXPointer(_doc),
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
  }

  void _requireDoc() {
    if (_doc == nullptr) throw EngineException('no open document');
  }
}
