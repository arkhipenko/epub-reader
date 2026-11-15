// State and actions of the open book: position, rendered pages, layout,
// chapter data and position saving.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../engine/cre_engine.dart';
import '../sync/kosync_decision.dart';
import '../sync/kosync_session.dart';
import '../sync/partial_md5.dart';
import 'advanced_settings.dart';
import 'back_stack.dart';
import 'chapters.dart';
import 'line_shift.dart';
import 'power.dart';
import 'reader_settings.dart';
import 'reader_theme.dart';
import 'style_tweaks.dart';

/// Progress sync output for the reader screen.
sealed class SyncEvent {}

/// A short message (KOReader InfoMessage).
class SyncMessage extends SyncEvent {
  SyncMessage(this.text);

  final String text;
}

/// A yes/no question (KOReader ConfirmBox). Yes goes to [xpointer].
class SyncQuestion extends SyncEvent {
  SyncQuestion(this.text, this.xpointer);

  final String text;
  final String xpointer;
}

/// Time the page area must keep its size before the book opens. When the
/// reader starts, the system bars hide and the page area changes within a
/// few frames. A book that opens at once is laid out a second time.
const Duration _viewportSettle = Duration(milliseconds: 100);

const String _msgSyncError =
    'Something went wrong when syncing progress, please check your network connection and try again later.';
const String _msgLogin = 'Please register or login before using the progress synchronization feature.';

/// Search results and the hit on screen.
class SearchState {
  SearchState({required this.query, required this.hits, this.index = 0});

  final String query;
  final List<SearchHit> hits;
  int index;

  SearchHit? get current => hits.isEmpty ? null : hits[index.clamp(0, hits.length - 1)];
}

/// A page image and the rows of the book that it shows.
class ShiftSlice {
  const ShiftSlice(this.image, this.start, this.height);

  final ui.Image image;

  /// First document row and row count of the page.
  final int start;
  final int height;
}

/// What the page area shows while a vertical drag has moved the view off
/// the fixed pages: slices of page images, placed by document row.
class ShiftView {
  const ShiftView({
    required this.y,
    required this.areaTop,
    required this.areaHeight,
    required this.end,
    required this.dragging,
    required this.slices,
  });

  /// Document row at the top text edge. It follows the finger in a drag.
  final double y;

  /// Rows of a page image that can hold text: first row and row count.
  final int areaTop;
  final int areaHeight;

  /// First row after the last whole line of the view at rest. Null in a
  /// drag: the text then shows down to the lower edge.
  final int? end;
  final bool dragging;
  final List<ShiftSlice> slices;
}

class ReaderController extends ChangeNotifier {
  ReaderController({required this.services, required this.path, this.jumpTo})
    : _settings = services.settings.value,
      _advanced = services.advanced.value {
    services.settings.addListener(_onSettingsChanged);
    services.advanced.addListener(_onAdvancedChanged);
  }

  final AppServices services;
  final String path;

  /// Open the book at this XPointer instead of the saved position.
  final String? jumpTo;

  CreEngine get _engine => services.engine;

  ReaderSettings _settings;
  ReaderSettings get settings => _settings;
  ReaderTheme get theme => readerThemeById(_settings.themeId);

  /// Common advanced settings.
  AdvancedSettings _advanced;

  /// Advanced settings of this book.
  BookSettings bookSettings = const BookSettings();

  String? bookId;
  BookInfo? info;
  List<TocEntry> toc = const [];

  /// Position that the engine confirmed (with XPointer).
  EnginePosition? position;

  /// Page on screen. It can run ahead of [position] for a moment, because
  /// a cached page shows before the engine confirms the page turn.
  int displayPage = 0;
  int get pageCount => position?.pageCount ?? 0;

  Object? error;
  bool get isOpen => position != null;

  final ReadingSpeed speed = ReadingSpeed();

  KoSyncSession? _sync;
  final StreamController<SyncEvent> _syncEvents = StreamController.broadcast();
  Stream<SyncEvent> get syncEvents => _syncEvents.stream;
  Timer? _resumePullTimer;
  DateTime? _pausedAt;

  /// Last page turn direction: +1 forward, -1 back. Pre-rendering follows it.
  int _direction = 1;

  /// Android battery saver is on: the reader skips optional work.
  bool batterySaver = false;

  // ---- Annotations, selection, search, links ----

  /// Bookmarks, highlights and notes of this book.
  List<Annotation> annotations = const [];
  StreamSubscription<List<Annotation>>? _annotationSub;

  /// Boxes on page [_marksPage], by key: an annotation id, 'sel' for the
  /// selection, 'hit' for the search hit on screen.
  Map<String, List<PageRect>> _marks = const {};
  int _marksPage = 0;
  Map<String, List<PageRect>> get pageMarks => !isShifted && _marksPage == displayPage ? _marks : const {};
  List<PageLink> _links = const [];

  /// Links of the page on screen.
  List<PageLink> get pageLinks => !isShifted && _marksPage == displayPage ? _links : const [];

  /// Page of an XPointer in the current layout (cleared on a new layout).
  final Map<String, int> _pageOf = {};

  TextSelection? selection;
  SearchState? search;
  final BackStack _backStack = BackStack();
  bool get canGoBack => _backStack.isNotEmpty;
  (ui.Offset, ui.Offset)? _pendingExtend;
  bool _extending = false;

  /// Page size the view asks for (physical pixels).
  ui.Size? _requestedSize;

  /// Page size the engine renders at now. It differs from [_requestedSize]
  /// until a delayed resize runs.
  ui.Size? _renderSize;
  double _dpr = 1;
  bool _openStarted = false;
  final Map<int, ui.Image> _pages = {};
  int _generation = 0;
  bool _disposed = false;
  Timer? _saveTimer;
  Timer? _resizeTimer;
  Future<void> _queue = Future.value();

  /// The last page image, kept on screen while a new layout renders.
  ui.Image? _fallback;

  ui.Image? get pageImage => _pages[displayPage] ?? _fallback;

  // ---- Line shift ----
  //
  // A vertical drag moves the text by whole lines. The view then shows the
  // book from a row that is not the start of a page, until the next page
  // turn. Highlights, links and text selection are off in that state.

  /// Pages and text lines around the view. Null: not loaded.
  ShiftGeometry? _geo;

  /// Completes when the geometry that was asked for last is there.
  Future<void> _geoReady = Future.value();

  /// Document row at the top text edge while the view is off the fixed
  /// pages. In a drag it follows the finger. Null: the view is a page, or
  /// a drag started and the geometry is not there yet.
  double? _shiftY;

  /// Row of the view when the drag started.
  int _shiftStart = 0;

  /// First row after the last whole line of the view at rest.
  int? _shiftEnd;
  bool _dragging = false;

  /// Finger travel of a drag before the geometry arrived.
  double _pendingDrag = 0;

  /// The view is off the fixed pages, or a vertical drag is in progress.
  bool get isShifted => _shiftY != null || _dragging;

  /// The shifted view to draw, or null when the view is a page.
  ShiftView? get shiftView {
    if (!isShifted) return null;
    final size = _renderSize;
    if (size == null) return null;
    final g = _geo;
    final y = _shiftY;
    if (g == null || y == null) {
      // The geometry is on its way: the page on screen moves as one slice.
      final image = pageImage;
      if (image == null) return null;
      final top = (_settings.marginVertical * _dpr).round();
      final height = size.height.toInt() - 2 * top;
      return ShiftView(
        y: _pendingDrag,
        areaTop: top,
        areaHeight: height,
        end: null,
        dragging: true,
        slices: [ShiftSlice(image, 0, height)],
      );
    }
    // Only pages in reach: their images stay while the view is shifted.
    final reach = _shiftPages();
    return ShiftView(
      y: y,
      areaTop: g.areaTop,
      areaHeight: g.areaHeight,
      end: _dragging ? null : _shiftEnd,
      dragging: _dragging,
      slices: [
        for (final p in g.pages)
          if (p.height > 0 && reach.contains(p.page) && _pages[p.page] != null)
            ShiftSlice(_pages[p.page]!, p.start, p.height),
      ],
    );
  }

  void _resetShift() {
    _shiftY = null;
    _shiftEnd = null;
    _dragging = false;
    _pendingDrag = 0;
    _geo = null;
  }

  /// Pages that the shifted view can show: one screen before it and two
  /// screens after it (a drag moves the text by one screen at most).
  Set<int> _shiftPages() {
    final g = _geo;
    final y = _shiftY;
    if (g == null || y == null) return const {};
    final from = y - g.areaHeight;
    final to = y + 2 * g.areaHeight;
    return {
      for (final p in g.pages)
        if (p.end > from && p.start < to) p.page,
    };
  }

  /// Loads the geometry around the start of the page on screen, or around
  /// document row [y], then renders the pages in reach.
  void _loadGeometry({int? y}) {
    final generation = _generation;
    final page = displayPage;
    _geoReady = _serial(() async {
      final info = await _engine.shiftInfo(page: y == null ? page : null, y: y);
      if (generation != _generation || _disposed) return;
      if (y == null) {
        // For a drag that started on a page and still waits for this.
        if (!_dragging || _shiftY != null || displayPage != page) return;
      } else if (_shiftY == null) {
        return; // the view went back to a page
      }
      final g = ShiftGeometry.fromRows(
        pages: info.pages,
        lines: info.lines,
        minY: info.minY,
        maxY: info.maxY,
        areaTop: info.areaTop,
        areaHeight: info.areaHeight,
      );
      _geo = g;
      if (y == null) {
        _shiftStart = info.top;
        _shiftY = g.clamp(info.top + _pendingDrag);
        _pendingDrag = 0;
      }
      notifyListeners();
    }).catchError((Object _) {});
    unawaited(_serial(_renderShiftPages));
  }

  Future<void> _renderShiftPages() async {
    final g = _geo;
    if (g == null) return;
    for (final page in _shiftPages()) {
      if (_pages.containsKey(page)) continue;
      await _ensurePage(page);
      if (_geo != g || _disposed) return;
      notifyListeners();
    }
    _dropUnusedPages();
  }

  /// Starts a vertical drag of the text. Returns false when the view
  /// cannot move now.
  bool beginShift() {
    if (!isOpen || selection != null || _renderSize == null || _dragging) return false;
    _dragging = true;
    _pendingDrag = 0;
    final y = _shiftY;
    if (y != null && _geo != null) {
      _shiftStart = y.round();
    } else {
      _shiftY = null;
      _loadGeometry();
    }
    notifyListeners();
    return true;
  }

  /// Moves the text by [rows] page pixels. A positive value moves forward
  /// in the book (the finger goes up).
  void dragShift(double rows) {
    if (!_dragging) return;
    final g = _geo;
    final y = _shiftY;
    if (g == null || y == null) {
      _pendingDrag += rows;
    } else {
      _shiftY = g.clamp(y + rows);
    }
    notifyListeners();
  }

  /// Ends the drag. The text settles with a whole line at the top. A view
  /// that then starts where a page starts is that page again.
  Future<void> endShift() async {
    if (!_dragging) return;
    await _geoReady;
    if (!_dragging) return; // a jump went to another place meanwhile
    final g = _geo;
    final y = _shiftY;
    if (g == null || y == null) {
      _resetShift();
      notifyListeners();
      return;
    }
    _dragging = false;
    final row = g.settle(y, _shiftStart);
    final aligned = g.pageStartingAt(row);
    if (aligned != null) {
      final wasOnPage = _shiftStart == row && aligned.page == displayPage && position?.page == aligned.page;
      _resetShift();
      if (wasOnPage) {
        notifyListeners(); // the drag returned to the page it started on
      } else {
        _showPage(aligned.page);
      }
      return;
    }
    _shiftY = row.toDouble();
    _shiftEnd = g.visibleEnd(row);
    notifyListeners();
    unawaited(
      _serial(() async {
        if (_shiftY != row.toDouble() || _dragging) return; // moved again
        final p = await _engine.shiftTo(row);
        if (p == null || _disposed || _shiftY != row.toDouble()) return;
        // The reading position is the first line on screen (the KOReader
        // rule for its scroll view). The page is the one that holds it.
        position = p;
        displayPage = p.page;
        notifyListeners();
        _sync?.onPageChanged(p.page, () => unawaited(pushProgress()));
        _scheduleSave();
      }),
    );
    _loadGeometry(y: row);
  }

  /// Shows [page] now when its image is cached. The engine follows.
  void _showPage(int page) {
    if (_pages.containsKey(page)) displayPage = page;
    notifyListeners();
    _serial(() async => _setPosition(await _engine.gotoPage(page)));
  }

  int get chapterIndex => chapterIndexAt(toc, displayPage);
  String get chapterTitle => chapterIndex < 0 ? '' : toc[chapterIndex].title;
  int get chapterPagesLeft => pagesLeftInChapter(toc, displayPage, pageCount);

  /// KOReader getLastPercent() in page mode: current page / page count.
  double get progress => pageCount == 0 ? 0 : displayPage / pageCount;

  /// Runs engine operations one after another, in call order.
  Future<T> _serial<T>(Future<T> Function() op) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        completer.complete(await op());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  EngineLayout _layout() {
    final t = theme;
    int px(double v) => (v * _dpr).round();
    return EngineLayout(
      fontFace: _settings.fontFace,
      fontSize: px(_settings.fontSize),
      interlinePercent: _settings.lineSpacing,
      marginLeft: px(_settings.marginHorizontal),
      marginTop: px(_settings.marginVertical),
      marginRight: px(_settings.marginHorizontal),
      marginBottom: px(_settings.marginVertical),
      hyphenation: _settings.hyphenation,
      embeddedStyles: _settings.embeddedStyles,
      embeddedFonts: _settings.embeddedFonts,
      // Dark themes draw black on white and invert on screen.
      backgroundRgb: t.isDark ? 0xFFFFFF : t.backgroundRgb,
      textRgb: t.isDark ? 0x000000 : t.textRgb,
      textLanguage: bookSettings.language,
      props: _advanced.engineProps(),
      extraCss: buildTweakCss(_advanced, bookSettings),
      gammaIndex: _advanced.fontGamma,
    );
  }

  /// Called by the page widget with the size of the page area.
  /// The book opens when the size stays the same for [_viewportSettle].
  /// Later calls change the page size.
  void setViewport(ui.Size logical, double dpr) {
    final physical = ui.Size((logical.width * dpr).roundToDouble(), (logical.height * dpr).roundToDouble());
    if (physical.isEmpty || physical == _requestedSize) return;
    _requestedSize = physical;
    _dpr = dpr;
    _resizeTimer?.cancel();
    if (_openStarted) {
      _resizeTimer = Timer(const Duration(milliseconds: 250), () => _serial(_resize));
    } else {
      _resizeTimer = Timer(_viewportSettle, () {
        _openStarted = true;
        _serial(_open);
      });
    }
  }

  Future<void> _checkBatterySaver() async {
    try {
      batterySaver = await Battery().isInBatterySaveMode;
    } catch (_) {
      batterySaver = false;
    }
  }

  Future<void> _open() async {
    await _checkBatterySaver();
    try {
      final size = _requestedSize!;
      final id = await partialMd5OfFile(path);
      bookId = id;
      final saved = await services.db.bookById(id);
      bookSettings = BookSettings.decode(saved?.settings);
      final r = await _engine.open(
        path,
        width: size.width.toInt(),
        height: size.height.toInt(),
        dpi: (160 * _dpr).round(),
        layout: _layout(),
        xpointer: jumpTo ?? saved?.lastXPointer,
        languageHint: saved?.language,
      );
      _renderSize = size;
      info = r.info;
      toc = r.toc;
      await services.db.upsertBook(
        id: id,
        path: path,
        title: r.info.title.isEmpty ? path.split('/').last : r.info.title,
        authors: r.info.authors,
        format: r.info.format,
        language: r.info.language,
      );
      final kosync = services.kosync;
      _sync = KoSyncSession(
        service: kosync,
        documentKey: kosync.documentKey(partialMd5: id, path: path),
        metadata: {'filename': path.split('/').last, 'title': r.info.title, 'authors': r.info.authors},
      );
      _annotationSub = services.db.watchAnnotations(id).listen((list) {
        annotations = list;
        if (isOpen) {
          _serial(() async {
            await _refreshMarks();
            notifyListeners();
          });
        }
      });
      await _setPosition(r.position);
      // Open this book again if the app closes while it shows.
      if (!_disposed) unawaited(services.lastBook.opened(path));
      // A jump (from a note in the library) is not a sync conflict to resolve.
      if (kosync.current.autoSync && jumpTo == null) unawaited(_autoPull());
    } catch (e) {
      error = e;
      notifyListeners();
    }
  }

  Future<void> _resize() async {
    final size = _requestedSize!;
    if (size == _renderSize || _renderSize == null) return;
    final r = await _engine.resize(size.width.toInt(), size.height.toInt());
    _renderSize = size;
    _clearPages();
    toc = r.toc;
    await _setPosition(r.position);
  }

  void _onSettingsChanged() {
    final next = services.settings.value;
    final old = _settings;
    _settings = next;
    final relayout = old.layoutDiffers(next) || old.themeId != next.themeId;
    if (relayout && isOpen) {
      _relayout();
    } else {
      notifyListeners();
    }
  }

  /// Lays the book out again with the current settings and keeps the
  /// reading position.
  Future<void> _relayout() => _serial(() async {
    final r = await _engine.setLayout(_layout());
    _clearPages();
    toc = r.toc;
    await _setPosition(r.position);
  });

  void _onAdvancedChanged() {
    final next = services.advanced.value;
    final old = _advanced;
    _advanced = next;
    if (!isOpen) return;
    if (old.layoutDiffers(next)) {
      _relayout();
    } else if (old.fontGamma != next.fontGamma) {
      // Contrast changes how the engine draws glyphs, not the layout.
      _serial(() async {
        await _engine.setGamma(next.fontGamma);
        final p = position;
        if (p == null) return;
        _clearPages();
        await _setPosition(p);
      });
    }
  }

  /// Changes the advanced settings of this book, stores them with the book
  /// and lays the book out again.
  Future<void> updateBookSettings(BookSettings value) async {
    if (value == bookSettings) return;
    bookSettings = value;
    notifyListeners();
    final id = bookId;
    if (id != null) await services.db.saveBookSettings(id, value.encode());
    if (isOpen) await _relayout();
  }

  /// Shows the engine position, then renders the pages around it.
  /// Runs inside a serial engine operation: the engine is on page p.page.
  Future<void> _setPosition(EnginePosition p) async {
    // Render first, so that the screen never shows a page without an image.
    await _ensurePage(p.page, p.pageCount);
    if (_disposed) return;
    // An engine position is a place on the fixed pages.
    _resetShift();
    position = p;
    await _refreshMarks(p.page);
    if (_disposed) return;
    displayPage = p.page;
    notifyListeners();
    _sync?.onPageChanged(p.page, () => unawaited(pushProgress()));
    final fallback = _fallback;
    if (fallback != null) {
      _fallback = null;
      _disposeLater(fallback);
    }
    _scheduleSave();
    unawaited(_serial(_prefetch));
  }

  Future<void> _ensurePage(int page, [int? count]) async {
    if (_pages.containsKey(page) || page < 1 || page > (count ?? pageCount)) return;
    final size = _renderSize!;
    final generation = _generation;
    final rgba = await _engine.drawPage(page, invertImages: theme.isDark);
    if (rgba == null || generation != _generation || _disposed) return;
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      size.width.toInt(),
      size.height.toInt(),
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final image = await completer.future;
    if (generation != _generation || _disposed) {
      image.dispose();
      return;
    }
    _pages[page] = image;
  }

  /// Renders the page in the reading direction ahead (none in battery
  /// saver mode) and drops pages that are not neighbours of the current one.
  Future<void> _prefetch() async {
    final current = displayPage;
    for (final p in pagesToPrefetch(
      current: current,
      direction: _direction,
      pageCount: pageCount,
      saver: batterySaver,
    )) {
      await _ensurePage(p);
    }
    _dropUnusedPages();
  }

  /// Drops the page images that are not neighbours of the page on screen
  /// and not in reach of a shifted view.
  void _dropUnusedPages() {
    final keep = {...pagesToKeep(displayPage), displayPage, ..._shiftPages()};
    final drop = _pages.keys.where((k) => !keep.contains(k)).toList();
    for (final k in drop) {
      _disposeLater(_pages.remove(k)!);
    }
    // A shifted view is drawn from several page images. It must be built
    // again before the dropped images go (they go after the next frame).
    if (drop.isNotEmpty && isShifted && !_disposed) notifyListeners();
  }

  void _clearPages({bool keepCurrent = true}) {
    _generation++;
    if (isShifted) {
      // A new layout: the rows and the page images are no longer valid.
      // The listeners must stop drawing the slices before the images go.
      _resetShift();
      if (!_disposed) notifyListeners();
    }
    _pageOf.clear();
    _marks = const {};
    final current = keepCurrent ? _pages.remove(displayPage) : null;
    if (current != null) {
      final old = _fallback;
      if (old != null) _disposeLater(old);
      _fallback = current;
    }
    for (final image in _pages.values) {
      _disposeLater(image);
    }
    _pages.clear();
  }

  /// Disposes an image after the next frame, so that a widget that still
  /// paints it this frame does not use a disposed image.
  void _disposeLater(ui.Image image) {
    SchedulerBinding.instance.addPostFrameCallback((_) => image.dispose());
    SchedulerBinding.instance.scheduleFrame();
  }

  // ---- Navigation ----

  void turnPage(int delta) {
    if (!isOpen || _dragging) return;
    var target = displayPage + delta;
    final g = _geo;
    final y = _shiftY;
    final shifted = g != null && y != null;
    if (shifted) {
      // A page turn returns to the fixed pages. Forward shows the page
      // with the first line below the view, back the page with the last
      // line above it.
      final forward = delta > 0;
      final top = y.round();
      final current = g.pageAt(top) ?? displayPage;
      final row = shiftTurnRow(forward: forward, top: top, end: _shiftEnd ?? g.visibleEnd(top));
      target = shiftTurnPage(forward: forward, found: g.pageAt(row) ?? current, current: current, pageCount: pageCount);
      _resetShift();
    } else if (target < 1 || target > pageCount) {
      return;
    }
    _direction = delta < 0 ? -1 : 1;
    speed.pageTurned(DateTime.now());
    if (_pages.containsKey(target)) {
      // Show the cached page now. The engine follows.
      displayPage = target;
      notifyListeners();
    } else if (shifted) {
      notifyListeners();
    }
    _serial(() async => _setPosition(await _engine.gotoPage(target)));
  }

  Future<void> gotoPage(int page) {
    if (!isOpen) return Future.value();
    _direction = 1;
    final target = page.clamp(1, pageCount);
    return _serial(() async => _setPosition(await _engine.gotoPage(target)));
  }

  /// A jump with the page slider. The place before the jump goes on the
  /// back stack, as for a link: back (or the undo button) returns there.
  /// A slider moved by accident is then easy to undo.
  Future<void> jumpToPage(int page) {
    if (!isOpen) return Future.value();
    final target = page.clamp(1, pageCount);
    if (target == displayPage) return Future.value();
    _direction = 1;
    return _serial(() async {
      final from = position?.xpointer;
      final p = await _engine.gotoPage(target);
      if (from != null) _backStack.push(from);
      await _setPosition(p);
    });
  }

  /// [fraction] is 0 to 1.
  Future<void> gotoPercent(double fraction) => gotoPage((fraction * pageCount).ceil().clamp(1, pageCount));

  /// Returns false when the XPointer is not in the document.
  Future<bool> gotoXPointer(String xpointer) => _serial(() async {
    final p = await _engine.gotoXPointer(xpointer);
    if (p == null) return false;
    await _setPosition(p);
    return true;
  });

  Future<void> nextChapter() async {
    final p = nextChapterPage(toc, displayPage);
    if (p != null) await gotoPage(p);
  }

  Future<void> previousChapter() async {
    final p = previousChapterPage(toc, displayPage);
    if (p != null) await gotoPage(p);
  }

  Future<String?> textAt(String xpointer, {int maxChars = 200}) => _engine.textAt(xpointer, maxChars: maxChars);

  // ---- Annotations and marks ----

  /// Recomputes the boxes of annotations, selection and search hit on the
  /// engine's current page. Call only inside a serial engine operation.
  Future<void> _refreshMarks([int? page]) async {
    final current = page ?? position?.page ?? 0;
    final need = <String>{};
    for (final a in annotations) {
      need.add(a.page);
      if (a.pos1 != null) need.add(a.pos1!);
    }
    need.removeAll(_pageOf.keys);
    if (need.isNotEmpty) _pageOf.addAll(await _engine.pagesOf(need));
    final ranges = <String, (String, String)>{};
    for (final a in annotations) {
      final p0 = a.pos0, p1 = a.pos1;
      if (p0 == null || p1 == null) continue;
      final first = _pageOf[a.page] ?? 0;
      final last = _pageOf[p1] ?? first;
      if (first <= current && current <= last) ranges['${a.id}'] = (p0, p1);
    }
    final sel = selection;
    if (sel != null) ranges['sel'] = (sel.pos0, sel.pos1);
    final hit = search?.current;
    if (hit != null) ranges['hit'] = (hit.start, hit.end);
    _marks = await _engine.boxes(ranges);
    if (current != _marksPage || page != null) _links = await _engine.pageLinks();
    _marksPage = current;
  }

  /// The bookmark of the page on screen, or null.
  Annotation? get pageBookmark {
    for (final a in annotations) {
      if (a.pos0 == null && _pageOf[a.page] == displayPage) return a;
    }
    return null;
  }

  List<Annotation> get bookmarks => [
    for (final a in annotations)
      if (a.pos0 == null) a,
  ]..sort((a, b) => (_pageOf[a.page] ?? a.pageno).compareTo(_pageOf[b.page] ?? b.pageno));

  List<Annotation> get highlights => [
    for (final a in annotations)
      if (a.pos0 != null) a,
  ]..sort((a, b) => (_pageOf[a.page] ?? a.pageno).compareTo(_pageOf[b.page] ?? b.pageno));

  /// Page of an annotation in the current layout (its saved page if unknown).
  int pageOfAnnotation(Annotation a) => _pageOf[a.page] ?? a.pageno;

  /// Converts a point in the page widget to page pixels.
  ui.Offset toPagePixels(ui.Offset local, ui.Size widget) {
    final r = _renderSize;
    if (r == null || widget.isEmpty) return local;
    return ui.Offset(local.dx * r.width / widget.width, local.dy * r.height / widget.height);
  }

  /// Scale from page pixels to widget pixels.
  double pixelScale(ui.Size widget) => _renderSize == null ? 1 : widget.width / _renderSize!.width;

  /// The highlight under a point (page pixels), or null.
  Annotation? annotationAt(ui.Offset px) {
    for (final e in pageMarks.entries) {
      final id = int.tryParse(e.key);
      if (id == null) continue;
      if (e.value.any((r) => r.contains(px.dx, px.dy))) {
        for (final a in annotations) {
          if (a.id == id) return a;
        }
      }
    }
    return null;
  }

  Future<void> toggleBookmark() async {
    final id = bookId;
    final p = position;
    final xp = p?.xpointer;
    if (id == null || p == null || xp == null) return;
    final existing = pageBookmark;
    if (existing != null) {
      await services.db.deleteAnnotation(existing.id);
      return;
    }
    final text = await _serial(() => _engine.textAt(xp, maxChars: 120)) ?? '';
    _pageOf[xp] = p.page;
    await services.db.addAnnotation(
      AnnotationsCompanion.insert(
        bookId: id,
        page: xp,
        textContent: Value(text.trim()),
        chapter: Value(chapterTitle),
        pageno: Value(p.page),
        datetime: DateTime.now(),
      ),
    );
  }

  // ---- Selection ----

  /// Selects the word at a point (page pixels).
  Future<void> selectWordAt(ui.Offset px) => _serial(() async {
    if (isShifted) return; // the engine selects on a fixed page
    selection = await _engine.select(px.dx.round(), px.dy.round(), px.dx.round(), px.dy.round());
    await _refreshMarks();
    notifyListeners();
  });

  /// Selects from [anchor] to [point] (page pixels). While a drag sends many
  /// points, only the latest waiting one is sent to the engine.
  void extendSelection(ui.Offset anchor, ui.Offset point) {
    _pendingExtend = (anchor, point);
    if (_extending) return;
    _extending = true;
    unawaited(
      _serial(() async {
        try {
          while (_pendingExtend != null) {
            final (a, b) = _pendingExtend!;
            _pendingExtend = null;
            final s = await _engine.select(a.dx.round(), a.dy.round(), b.dx.round(), b.dy.round());
            if (s != null) selection = s;
            await _refreshMarks();
            notifyListeners();
          }
        } finally {
          _extending = false;
        }
      }),
    );
  }

  void clearSelection() {
    if (selection == null) return;
    selection = null;
    _marks = Map.of(_marks)..remove('sel');
    notifyListeners();
  }

  Future<void> addHighlight({String color = 'yellow', String drawer = 'lighten', String? note}) async {
    final s = selection;
    final id = bookId;
    if (s == null || id == null) return;
    _pageOf[s.pos0] = displayPage;
    await services.db.addAnnotation(
      AnnotationsCompanion.insert(
        bookId: id,
        page: s.pos0,
        pos0: Value(s.pos0),
        pos1: Value(s.pos1),
        textContent: Value(s.text),
        note: Value(note == null || note.trim().isEmpty ? null : note),
        color: Value(color),
        drawer: Value(drawer),
        chapter: Value(chapterTitle),
        pageno: Value(displayPage),
        datetime: DateTime.now(),
      ),
    );
    clearSelection();
  }

  Future<void> updateAnnotation(Annotation a, {String? color, String? drawer, String? Function()? note}) =>
      services.db.updateAnnotation(
        a.id,
        AnnotationsCompanion(
          color: color == null ? const Value.absent() : Value(color),
          drawer: drawer == null ? const Value.absent() : Value(drawer),
          note: note == null ? const Value.absent() : Value(note()),
        ),
      );

  Future<void> deleteAnnotation(Annotation a) => services.db.deleteAnnotation(a.id);

  Future<void> gotoAnnotation(Annotation a) async {
    await gotoXPointer(a.page);
  }

  // ---- Search ----

  Future<List<SearchHit>> findAll(String query, {bool caseInsensitive = true}) =>
      _serial(() => _engine.findAll(query, caseInsensitive: caseInsensitive));

  /// Shows hit [index] of [state] (goes to its page and marks it).
  Future<void> showSearchHit(SearchState state, int index) async {
    if (state.hits.isEmpty) return;
    state.index = index.clamp(0, state.hits.length - 1);
    search = state;
    final hit = state.current!;
    await gotoXPointer(hit.start);
  }

  void closeSearch() {
    if (search == null) return;
    search = null;
    _marks = Map.of(_marks)..remove('hit');
    notifyListeners();
  }

  // ---- Links ----

  /// The link under a point (page pixels) on the page on screen, or null.
  /// Uses the page's link boxes, so a tap needs no engine call.
  PageLink? linkAt(ui.Offset px) {
    // A little slack: link text is small for a finger.
    const pad = 12.0;
    for (final l in pageLinks) {
      for (final r in l.boxes) {
        if (px.dx >= r.left - pad && px.dx <= r.right + pad && px.dy >= r.top - pad && px.dy <= r.bottom + pad) {
          return l;
        }
      }
    }
    return null;
  }

  /// Follows a link. External links are shown as a message.
  Future<void> followLink(PageLink link) async {
    if (!link.isInternal) {
      _say('Link to ${link.href}');
      return;
    }
    await _serial(() async {
      final from = position?.xpointer;
      final p = await _engine.gotoLink(link.href);
      if (p == null) return;
      if (from != null) _backStack.push(from);
      await _setPosition(p);
    });
  }

  /// Returns to the place before the last followed link or slider jump.
  Future<void> goBack() async {
    final place = _backStack.pop();
    if (place == null) return;
    await gotoXPointer(place);
    notifyListeners();
  }

  /// Forgets all places to go back to (a long press on the undo button).
  /// The undo button hides, and Android back closes the book again.
  void clearBack() {
    if (_backStack.isEmpty) return;
    _backStack.clear();
    notifyListeners();
  }

  // ---- Progress sync (kosync) ----

  LocalProgress? _local() {
    final p = position;
    final xp = p?.xpointer;
    if (p == null || xp == null || p.pageCount == 0) return null;
    return LocalProgress(xpointer: xp, percent: roundPercent(p.page / p.pageCount));
  }

  void _say(String text) {
    if (!_syncEvents.isClosed) _syncEvents.add(SyncMessage(text));
  }

  /// Sends the position. A manual push ([interactive]) reports the result.
  Future<void> pushProgress({bool interactive = false}) async {
    final s = _sync;
    final p = _local();
    if (s == null || p == null) return;
    final r = await s.push(p, interactive: interactive);
    if (!interactive) return;
    switch (r.outcome) {
      case PushOutcome.pushed:
        _say('Progress has been pushed.');
      case PushOutcome.notLoggedIn:
        _say(_msgLogin);
      case PushOutcome.failed:
        _say('$_msgSyncError\n\n${r.error}');
      case PushOutcome.skipped:
        break;
    }
  }

  /// Gets the position from the server and applies the sync rules.
  Future<void> pullProgress({bool interactive = false}) async {
    final s = _sync;
    final p = _local();
    if (s == null || p == null) return;
    final r = await s.pull(p, interactive: interactive);
    if (r.notLoggedIn) {
      if (interactive) _say(_msgLogin);
      return;
    }
    if (r.error != null) {
      if (interactive) _say('$_msgSyncError\n\n${r.error}');
      return;
    }
    final d = r.decision;
    if (d == null) return;
    final remote = d.remote;
    switch (d.outcome) {
      case PullOutcome.noProgress:
        if (interactive) _say('No progress found for this document.');
      case PullOutcome.fromThisDevice:
        if (interactive) _say('Latest progress is coming from this device.');
      case PullOutcome.alreadySynced:
        if (interactive) _say('The progress has already been synchronized.');
      case PullOutcome.jump:
        if (await gotoXPointer(remote!.progress)) {
          _say('Progress has been synchronized.');
        } else {
          _say('The synced position is not in this file. The two devices may have different versions of the book.');
        }
      case PullOutcome.askForward:
        if (!_syncEvents.isClosed) {
          _syncEvents.add(
            SyncQuestion(
              "Sync to latest location ${d.remotePercent}% from device '${remote!.device}'?",
              remote.progress,
            ),
          );
        }
      case PullOutcome.askBackward:
        if (!_syncEvents.isClosed) {
          _syncEvents.add(
            SyncQuestion(
              "Sync to previous location ${d.remotePercent}% from device '${remote!.device}'?",
              remote.progress,
            ),
          );
        }
      case PullOutcome.ignored:
        break;
    }
  }

  Future<void> _autoPull() async {
    await services.kosync.drainQueue().catchError((_) => 0);
    await pullProgress();
  }

  /// App goes to the background (KOReader onSuspend: push).
  void onPause() {
    _pausedAt = DateTime.now();
    unawaited(saveNow());
    if (services.kosync.current.autoSync) unawaited(pushProgress());
  }

  /// App comes back. KOReader pulls 1 s after every resume; this app pulls
  /// only after [kResumePullMinAway] in the background (fewer radio wake-ups).
  void onResume() {
    unawaited(_checkBatterySaver());
    final away = _pausedAt;
    _pausedAt = null;
    if (!services.kosync.current.autoSync || _sync == null) return;
    if (!shouldPullOnResume(pausedAt: away, now: DateTime.now())) return;
    _resumePullTimer?.cancel();
    _resumePullTimer = Timer(const Duration(seconds: 1), () => unawaited(_autoPull()));
  }

  // ---- Saving ----

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), saveNow);
  }

  /// Writes the reading position to the database now.
  Future<void> saveNow() async {
    _saveTimer?.cancel();
    final id = bookId;
    final xp = position?.xpointer;
    if (id == null || xp == null) return;
    await services.db.savePosition(id, xp, progress);
  }

  @override
  void dispose() {
    services.settings.removeListener(_onSettingsChanged);
    services.advanced.removeListener(_onAdvancedChanged);
    _annotationSub?.cancel();
    _resizeTimer?.cancel();
    _resumePullTimer?.cancel();
    unawaited(saveNow());
    // The user closed the book: the next start opens the library.
    unawaited(services.lastBook.closed(path));
    // KOReader onCloseDocument: push the position (a failure is queued).
    final sync = _sync;
    final local = _local();
    if (sync != null && local != null && services.kosync.current.autoSync) {
      unawaited(sync.push(local).whenComplete(sync.dispose));
    } else {
      sync?.dispose();
    }
    _syncEvents.close();
    _disposed = true;
    _clearPages(keepCurrent: false);
    final fallback = _fallback;
    if (fallback != null) _disposeLater(fallback);
    _fallback = null;
    unawaited(_engine.closeBook());
    super.dispose();
  }
}
