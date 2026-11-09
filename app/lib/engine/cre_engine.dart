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

/// Layout settings for one open book. Sizes are physical pixels.
class ReaderLayout {
  const ReaderLayout({
    required this.fontSize,
    required this.marginLeft,
    required this.marginTop,
    required this.marginRight,
    required this.marginBottom,
    this.interlinePercent = 100,
    this.fontFace = 'Noto Serif',
    this.backgroundRgb = 0xFFFFFF,
    this.textRgb = 0x000000,
  });

  final int fontSize;
  final int marginLeft;
  final int marginTop;
  final int marginRight;
  final int marginBottom;
  final int interlinePercent;
  final String fontFace;
  final int backgroundRgb;
  final int textRgb;

  Map<String, Object?> toMap() => {
        'fontSize': fontSize,
        'margins': [marginLeft, marginTop, marginRight, marginBottom],
        'interline': interlinePercent,
        'fontFace': fontFace,
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
    required this.format,
    required this.pageCount,
    required this.toc,
  });

  final String title;
  final String authors;
  final String language;
  final String format;
  final int pageCount;
  final List<TocEntry> toc;
}

/// One rendered page and the reading position it shows.
class PageState {
  const PageState({
    required this.page,
    required this.pageCount,
    required this.percent,
    required this.xpointer,
    required this.width,
    required this.height,
    required this.rgba,
  });

  final int page;
  final int pageCount;

  /// crengine position percent, 0 to 10000.
  final int percent;
  final String? xpointer;
  final int width;
  final int height;
  final Uint8List rgba;
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
    await engine._call('init', {'dataDir': dataDir, 'cacheDir': cacheDir});
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

  Future<BookInfo> open(String path, {required int width, required int height, required int dpi,
      required ReaderLayout layout}) async {
    final r = (await _call('open', {
      'path': path,
      'width': width,
      'height': height,
      'dpi': dpi,
      'isFb2': _isFb2(path),
      'layout': layout.toMap(),
    }))! as Map;
    final info = jsonDecode(r['info'] as String) as Map<String, dynamic>;
    final toc = (jsonDecode(r['toc'] as String) as List)
        .cast<Map<String, dynamic>>()
        .map((e) => TocEntry(
              title: e['title'] as String,
              xpointer: e['xpointer'] as String,
              page: e['page'] as int,
              depth: e['depth'] as int,
            ))
        .toList();
    return BookInfo(
      title: info['title'] as String,
      authors: info['authors'] as String,
      language: info['language'] as String,
      format: info['format'] as String,
      pageCount: r['pages'] as int,
      toc: toc,
    );
  }

  /// Draws the current page.
  Future<PageState> render() async {
    final r = (await _call('render'))! as Map;
    return PageState(
      page: r['page'] as int,
      pageCount: r['pages'] as int,
      percent: r['percent'] as int,
      xpointer: r['xpointer'] as String?,
      width: r['w'] as int,
      height: r['h'] as int,
      rgba: (r['rgba'] as TransferableTypedData).materialize().asUint8List(),
    );
  }

  Future<void> gotoPage(int page) => _call('gotoPage', {'page': page});

  /// Returns false when the XPointer is not in the document.
  Future<bool> gotoXPointer(String xpointer) async =>
      (await _call('gotoXPointer', {'xpointer': xpointer})) as bool;

  /// Text of the node at the XPointer, or null when it is not in the document.
  Future<String?> textAt(String xpointer, {int maxChars = 200}) async =>
      (await _call('textAt', {'xpointer': xpointer, 'max': maxChars})) as String?;

  Future<void> closeBook() => _call('close');

  void dispose() {
    _fromWorker.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  static bool _isFb2(String path) {
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
      case 'render':
        return _render();
      case 'gotoPage':
        _requireDoc();
        _b.docGotoPage(_doc, a['page'] as int);
        return null;
      case 'gotoXPointer':
        _requireDoc();
        return _b.docGotoXPointer(_doc, a['xpointer'] as String);
      case 'textAt':
        _requireDoc();
        return _b.docTextAtXPointer(_doc, a['xpointer'] as String, a['max'] as int);
      case 'close':
        _close();
        return null;
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
    var fonts = 0;
    final fontDir = Directory('$dataDir/fonts');
    if (fontDir.existsSync()) {
      final files = fontDir.listSync().whereType<File>().map((f) => f.path).toList()..sort();
      for (final f in files) {
        final lower = f.toLowerCase();
        if ((lower.endsWith('.ttf') || lower.endsWith('.otf')) && _b.registerFont(f)) fonts++;
      }
    }
    _b.fontsDone('Noto Serif');
    return {'fonts': fonts, 'dom': _b.latestDomVersion()};
  }

  Object? _open(Map<String, Object?> a) {
    _close();
    _width = a['width'] as int;
    _height = a['height'] as int;
    final layout = (a['layout'] as Map).cast<String, Object?>();
    final margins = (layout['margins'] as List).cast<int>();
    final d = _b.docNew(_width, _height);
    _b.docApplyDefaults(d, a['dpi'] as int);
    // KOReader CreDocument:init(): fb2.css for FB2 and TXT, epub.css for the rest.
    final css = (a['isFb2'] as bool) ? 'fb2.css' : 'epub.css';
    _b.docSetStylesheet(d, '$_dataDir/css/$css', '');
    _b.docSetFontFace(d, layout['fontFace'] as String);
    _b.docSetFontSize(d, layout['fontSize'] as int);
    _b.docSetInterline(d, layout['interline'] as int);
    _b.docSetMargins(d, margins[0], margins[1], margins[2], margins[3]);
    _b.docSetColors(d, layout['bg'] as int, layout['fg'] as int);
    // KOReader defaults: language from the book, hyphenation on.
    _b.docSetString(d, 'crengine.textlang.embedded.langs.enabled', '1');
    _b.docSetString(d, 'crengine.textlang.hyphenation.enabled', '1');
    if (!_b.docLoad(d, a['path'] as String)) {
      _b.docFree(d);
      throw EngineException('cannot open ${a['path']}');
    }
    _doc = d;
    _b.docRender(_doc);
    return {
      'info': _b.docInfoJson(_doc) ?? '{}',
      'toc': _b.docTocJson(_doc) ?? '[]',
      'pages': _b.docPageCount(_doc),
    };
  }

  Object? _render() {
    _requireDoc();
    final size = _width * _height * 4;
    final buf = calloc<Uint8>(size);
    try {
      if (_b.docDraw(_doc, buf, _width, _height) != 1) throw EngineException('draw failed');
      final pixels = TransferableTypedData.fromList([buf.asTypedList(size)]);
      return {
        'page': _b.docCurrentPage(_doc),
        'pages': _b.docPageCount(_doc),
        'percent': _b.docPercent(_doc),
        'xpointer': _b.docGetXPointer(_doc),
        'w': _width,
        'h': _height,
        'rgba': pixels,
      };
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
