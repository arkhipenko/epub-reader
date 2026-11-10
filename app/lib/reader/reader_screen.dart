// The reader: full-screen page, tap zones, swipes, text selection,
// highlights, bookmarks, links, search, status line and the menu bars
// (Koodo layout).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../dict/dictionary_screens.dart';
import '../sync/kosync_settings_screen.dart';
import 'reader_controller.dart';
import 'tap_zones.dart';
import 'widgets/annotation_widgets.dart';
import 'widgets/goto_dialog.dart';
import 'widgets/page_marks.dart';
import 'widgets/position_info_sheet.dart';
import 'widgets/reader_footer.dart';
import 'widgets/search_sheet.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/toc_drawer.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.path, this.jumpTo});

  final String path;

  /// Open at this XPointer (for example a note from the library).
  final String? jumpTo;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _pageKey = GlobalKey();
  ReaderController? _controller;
  StreamSubscription<SyncEvent>? _syncSub;
  bool _showBars = false;

  /// Fixed end of a selection drag, in page pixels.
  Offset? _anchor;

  // Screen timeout (wake lock) and brightness.
  Timer? _wakeTimer;
  bool _wakeLocked = false;
  double? _appliedBrightness;
  double? _dragBrightness;
  double _dragStartValue = 0.5;
  double _dragStartY = 0;
  Timer? _brightnessHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final services = ServicesScope.of(context);
      final c = ReaderController(services: services, path: widget.path, jumpTo: widget.jumpTo);
      _controller = c;
      _syncSub = c.syncEvents.listen(_onSyncEvent);
      services.settings.addListener(_onSettings);
      _onSettings();
    }
  }

  void _onSettings() {
    final s = _controller!.services.settings.value;
    _applyBrightness(s.brightness);
    _activity();
  }

  /// Sets the reader window brightness (null: the system brightness).
  /// It applies to this app's window only and resets when the reader closes.
  Future<void> _applyBrightness(double? value) async {
    if (value == _appliedBrightness) return;
    _appliedBrightness = value;
    try {
      if (value == null) {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      } else {
        await ScreenBrightness.instance.setApplicationScreenBrightness(value.clamp(0.01, 1.0));
      }
    } catch (_) {
      // Not available on this platform.
    }
  }

  /// Keeps the screen on for the chosen minutes after the last interaction
  /// (KOReader screen timeout). 0 leaves it to the system: no wake lock.
  void _activity() {
    final minutes = _controller?.services.settings.value.screenTimeoutMinutes ?? 0;
    _wakeTimer?.cancel();
    if (minutes <= 0) {
      _setWakeLock(false);
      return;
    }
    _setWakeLock(true);
    _wakeTimer = Timer(Duration(minutes: minutes), () => _setWakeLock(false));
  }

  void _setWakeLock(bool on) {
    if (on == _wakeLocked) return;
    _wakeLocked = on;
    (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {});
  }

  // Left edge vertical drag: brightness (KOReader frontlight gesture).
  bool _isEdgeDrag(Offset local, Size size) => local.dx < size.width / 8;

  Future<void> _brightnessDragStart(DragStartDetails d, Size size) async {
    if (!_isEdgeDrag(d.localPosition, size)) return;
    _dragStartY = d.localPosition.dy;
    var start = _controller!.services.settings.value.brightness;
    if (start == null) {
      try {
        start = await ScreenBrightness.instance.application;
      } catch (_) {
        start = 0.5;
      }
    }
    _dragStartValue = start;
    setState(() => _dragBrightness = start);
  }

  void _brightnessDragUpdate(DragUpdateDetails d, Size size) {
    if (_dragBrightness == null) return;
    // Up is brighter; the full drag range is 80 % of the page height.
    final delta = (_dragStartY - d.localPosition.dy) / (size.height * 0.8);
    final v = (_dragStartValue + delta).clamp(0.01, 1.0);
    setState(() => _dragBrightness = v);
    _appliedBrightness = v;
    ScreenBrightness.instance.setApplicationScreenBrightness(v).catchError((_) {});
  }

  void _brightnessDragEnd(DragEndDetails d) {
    final v = _dragBrightness;
    if (v == null) return;
    final services = _controller!.services;
    services.updateSettings(services.settings.value.copyWith(brightness: () => v));
    _brightnessHint?.cancel();
    _brightnessHint = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _dragBrightness = null);
    });
  }

  Future<void> _onSyncEvent(SyncEvent e) async {
    if (!mounted) return;
    switch (e) {
      case SyncMessage(:final text):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 3)));
      case SyncQuestion(:final text, :final xpointer):
        final yes = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(text),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
            ],
          ),
        );
        if (yes == true) await _controller?.gotoXPointer(xpointer);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.services.settings.removeListener(_onSettings);
    _wakeTimer?.cancel();
    _brightnessHint?.cancel();
    _setWakeLock(false);
    ScreenBrightness.instance.resetApplicationScreenBrightness().catchError((_) {});
    _syncSub?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wakeTimer?.cancel();
        _setWakeLock(false);
        _controller?.onPause();
      case AppLifecycleState.inactive:
        unawaited(_controller?.saveNow());
      case AppLifecycleState.resumed:
        _activity();
        _controller?.onResume();
      default:
        break;
    }
  }

  // The system bars stay hidden while the menu shows. Showing them would
  // change the page area, and each change lays out the book again.
  void _setBars(bool show) => setState(() => _showBars = show);

  Size get _pageSize => (_pageKey.currentContext?.findRenderObject() as RenderBox?)?.size ?? Size.zero;

  Offset _toPage(Offset local) => _controller!.toPagePixels(local, _pageSize);

  void _onTap(TapUpDetails d, Size size) {
    _activity();
    final c = _controller!;
    if (_showBars) {
      _setBars(false);
      return;
    }
    if (c.selection != null) {
      c.clearSelection();
      return;
    }
    final px = _toPage(d.localPosition);
    final a = c.annotationAt(px);
    if (a != null) {
      _highlightSheet(a);
      return;
    }
    // KOReader DTAP_ZONE_TOP_RIGHT: toggle the bookmark of the page.
    if (d.localPosition.dx > size.width * 7 / 8 && d.localPosition.dy < size.height / 8) {
      c.toggleBookmark();
      return;
    }
    final link = c.linkAt(px);
    if (link != null) {
      c.followLink(link);
      return;
    }
    switch (tapActionFor(c.settings.tapLayout, d.localPosition, size)) {
      case TapAction.previous:
        c.turnPage(-1);
      case TapAction.next:
        c.turnPage(1);
      case TapAction.menu:
        _setBars(true);
    }
  }

  void _onSwipe(DragEndDetails d) {
    _activity();
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 200 || _controller!.selection != null) return;
    // Swipe to the left shows the next page.
    _controller!.turnPage(v < 0 ? 1 : -1);
  }

  void _highlightSheet(Annotation a) {
    final c = _controller!;
    showHighlightSheet(
      context,
      a,
      onUpdate: ({color, drawer, note}) => c.updateAnnotation(a, color: color, drawer: drawer, note: note),
      onDelete: () => c.deleteAnnotation(a),
      onDictionary: () => showDictionary(context, a.textContent),
    );
  }

  Future<void> _goto() async {
    final c = _controller!;
    final target = await showGotoDialog(context, page: c.displayPage, pageCount: c.pageCount);
    if (target == null) return;
    if (target.page != null) {
      await c.gotoPage(target.page!);
    } else {
      await c.gotoPercent(target.fraction!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final theme = c.theme;
        return PopScope(
          canPop: c.selection == null && !c.canGoBack,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (c.selection != null) {
              c.clearSelection();
            } else if (c.canGoBack) {
              c.goBack();
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: theme.background,
            // The keyboard (search, notes) must not shrink the page: each
            // size change lays out the whole book again, and page numbers
            // would change while the keyboard shows.
            resizeToAvoidBottomInset: false,
            drawer: c.isOpen ? TocDrawer(controller: c) : null,
            drawerEnableOpenDragGesture: false,
            body: Stack(
              children: [
                Positioned.fill(
                  // Keeps text out of a camera cutout.
                  child: SafeArea(
                    child: Column(
                      children: [
                        Expanded(child: _page(context, c)),
                        if (c.settings.showFooter && c.isOpen) ReaderFooter(controller: c),
                      ],
                    ),
                  ),
                ),
                if (_showBars && c.isOpen) ...[
                  Positioned(top: 0, left: 0, right: 0, child: _topBar(context, c)),
                  Positioned(bottom: 0, left: 0, right: 0, child: _bottomBar(context, c)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _page(BuildContext context, ReaderController c) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) => c.setViewport(size, dpr));
        final image = c.pageImage;
        Widget content;
        if (c.error != null) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Cannot open this book.\n\n${c.error}', style: TextStyle(color: c.theme.text)),
            ),
          );
        } else if (image == null) {
          content = const Center(child: CircularProgressIndicator());
        } else {
          content = RawImage(image: image, fit: BoxFit.fill, filterQuality: FilterQuality.medium);
          if (c.theme.isDark) {
            content = ColorFiltered(colorFilter: ColorFilter.matrix(c.theme.darkMatrix), child: content);
          }
        }
        final scale = c.pixelScale(size);
        final marks = c.pageMarks;
        final accent = Theme.of(context).colorScheme.primary;
        final layers = <Widget>[
          Positioned.fill(
            child: GestureDetector(
              key: _pageKey,
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _onTap(d, size),
              onHorizontalDragEnd: _onSwipe,
              onVerticalDragStart: (d) => _brightnessDragStart(d, size),
              onVerticalDragUpdate: (d) => _brightnessDragUpdate(d, size),
              onVerticalDragEnd: _brightnessDragEnd,
              onLongPressStart: (d) {
                _activity();
                final px = _toPage(d.localPosition);
                _anchor = px;
                c.selectWordAt(px);
              },
              onLongPressMoveUpdate: (d) {
                final a = _anchor;
                if (a != null) c.extendSelection(a, _toPage(d.localPosition));
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  content,
                  if (marks.isNotEmpty)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: PageMarksPainter(
                          marks: marks,
                          annotations: {for (final a in c.annotations) a.id: a},
                          scale: scale,
                          selectionColor: accent,
                          dark: c.theme.isDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (c.pageBookmark != null)
            Positioned(
              top: 0,
              right: 12,
              child: IgnorePointer(child: Icon(Icons.bookmark, size: 32, color: accent.withValues(alpha: 0.85))),
            ),
          ..._selectionLayer(c, scale, size),
          if (_dragBrightness != null)
            Positioned(
              left: 16,
              top: size.height / 2 - 28,
              child: IgnorePointer(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.brightness_6),
                        const SizedBox(width: 8),
                        Text('${(_dragBrightness! * 100).round()}%'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (c.search != null) Positioned(left: 8, right: 8, bottom: 8, child: _searchBar(c)),
          if (c.canGoBack && c.search == null && c.selection == null)
            Positioned(
              left: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Back to the place before the link',
                onPressed: c.goBack,
                child: const Icon(Icons.undo),
              ),
            ),
        ];
        return Stack(children: layers);
      },
    );
  }

  /// Handles at both ends of the selection and the selection menu.
  List<Widget> _selectionLayer(ReaderController c, double scale, Size size) {
    final sel = c.selection;
    final boxes = c.pageMarks['sel'];
    if (sel == null || boxes == null || boxes.isEmpty) return const [];
    final first = boxes.first;
    final last = boxes.last;
    final start = Offset(first.left * scale, first.bottom * scale);
    final end = Offset(last.right * scale, last.bottom * scale);
    // Page-pixel points just inside each end, used as the fixed end of a drag.
    final startInside = Offset(first.left + 1.0, (first.top + first.bottom) / 2);
    final endInside = Offset(last.right - 1.0, (last.top + last.bottom) / 2);

    Widget handle(Offset at, Offset fixed) => Positioned(
      left: at.dx - 14,
      top: at.dy - 4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) {
          final box = _pageKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          // The finger is below the text; aim a little above it.
          final local = box.globalToLocal(d.globalPosition) - const Offset(0, 24);
          c.extendSelection(fixed, _toPage(local));
        },
        child: SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );

    // The menu goes to the half of the page that the selection does not use.
    final selectionInLowerHalf = start.dy > size.height / 2;
    final menu = SelectionMenu(
      onHighlight: (color) => c.addHighlight(color: color),
      onNote: () async {
        final note = await editNote(context, quote: sel.text);
        if (note != null) await c.addHighlight(color: 'yellow', note: note);
      },
      onCopy: () {
        Clipboard.setData(ClipboardData(text: sel.text));
        c.clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied.')));
      },
      onDictionary: () => showDictionary(context, sel.text),
      onSearch: () {
        c.clearSelection();
        showBookSearch(context, c, initial: sel.text.trim());
      },
      onClose: c.clearSelection,
    );
    return [
      handle(start, endInside),
      handle(end, startInside),
      Positioned(
        left: 8,
        right: 8,
        top: selectionInLowerHalf ? 16 : null,
        bottom: selectionInLowerHalf ? null : 16,
        child: Center(child: menu),
      ),
    ];
  }

  Widget _searchBar(ReaderController c) {
    final s = c.search!;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'All results',
              onPressed: () => showBookSearch(context, c),
            ),
            Expanded(
              child: Text(
                '"${s.query}"  ${s.index + 1} of ${s.hits.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous result',
              onPressed: s.index > 0 ? () => c.showSearchHit(s, s.index - 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next result',
              onPressed: s.index < s.hits.length - 1 ? () => c.showSearchHit(s, s.index + 1) : null,
            ),
            IconButton(icon: const Icon(Icons.close), tooltip: 'Close search', onPressed: c.closeSearch),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ReaderController c) {
    final bookmarked = c.pageBookmark != null;
    return Material(
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  c.info?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
                tooltip: bookmarked ? 'Remove bookmark' : 'Add bookmark',
                onPressed: c.toggleBookmark,
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Search in book',
                onPressed: () {
                  _setBars(false);
                  showBookSearch(context, c);
                },
              ),
              IconButton(
                icon: const Icon(Icons.toc),
                tooltip: 'Contents, bookmarks and notes',
                onPressed: () {
                  _setBars(false);
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              IconButton(
                icon: const Icon(Icons.text_fields),
                tooltip: 'Reading settings',
                onPressed: () {
                  _setBars(false);
                  showReaderSettings(context, fontFaces: ServicesScope.of(context).engine.fontFaces);
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) {
                  _setBars(false);
                  switch (v) {
                    case 'goto':
                      _goto();
                    case 'dict':
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DictionariesScreen()));
                    case 'push':
                      c.pushProgress(interactive: true);
                    case 'pull':
                      c.pullProgress(interactive: true);
                    case 'sync':
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KoSyncSettingsScreen()));
                    case 'info':
                      showPositionInfo(context, c);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'goto', child: Text('Go to page')),
                  PopupMenuItem(value: 'dict', child: Text('Dictionaries')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'push', child: Text('Push progress from this device')),
                  PopupMenuItem(value: 'pull', child: Text('Pull progress from other devices')),
                  PopupMenuItem(value: 'sync', child: Text('Progress sync settings')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'info', child: Text('Position info')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, ReaderController c) {
    final text = Theme.of(context).textTheme;
    return Material(
      elevation: 3,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _goto,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Column(
                    children: [
                      if (c.chapterTitle.isNotEmpty)
                        Text(c.chapterTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                      Text(
                        'Page ${c.displayPage} of ${c.pageCount}  -  ${(c.progress * 100).toStringAsFixed(1)}%',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    tooltip: 'Previous chapter',
                    onPressed: c.previousChapter,
                  ),
                  Expanded(child: _ProgressSlider(controller: c)),
                  IconButton(icon: const Icon(Icons.skip_next), tooltip: 'Next chapter', onPressed: c.nextChapter),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page slider. It moves only on release, because a jump needs a render.
class _ProgressSlider extends StatefulWidget {
  const _ProgressSlider({required this.controller});

  final ReaderController controller;

  @override
  State<_ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<_ProgressSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final count = c.pageCount;
    if (count < 2) return const SizedBox.shrink();
    final value = (_drag ?? c.displayPage.toDouble()).clamp(1.0, count.toDouble());
    return Slider(
      value: value,
      min: 1,
      max: count.toDouble(),
      label: '${value.round()}',
      divisions: count - 1,
      onChanged: (v) => setState(() => _drag = v),
      onChangeEnd: (v) {
        setState(() => _drag = null);
        c.gotoPage(v.round());
      },
    );
  }
}
