// The reader: full-screen page, tap zones, swipes, status line, and the
// menu bars (Koodo layout).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../sync/kosync_settings_screen.dart';
import 'reader_controller.dart';
import 'tap_zones.dart';
import 'widgets/goto_dialog.dart';
import 'widgets/position_info_sheet.dart';
import 'widgets/reader_footer.dart';
import 'widgets/settings_sheet.dart';
import 'widgets/toc_drawer.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.path});

  final String path;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ReaderController? _controller;
  StreamSubscription<SyncEvent>? _syncSub;
  bool _showBars = false;

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
      final c = ReaderController(services: ServicesScope.of(context), path: widget.path);
      _controller = c;
      _syncSub = c.syncEvents.listen(_onSyncEvent);
    }
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
    _syncSub?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _controller?.onPause();
      case AppLifecycleState.inactive:
        unawaited(_controller?.saveNow());
      case AppLifecycleState.resumed:
        _controller?.onResume();
      default:
        break;
    }
  }

  // The system bars stay hidden while the menu shows. Showing them would
  // change the page area, and each change lays out the book again.
  void _setBars(bool show) => setState(() => _showBars = show);

  void _onTap(TapUpDetails d, Size size) {
    final c = _controller!;
    if (_showBars) {
      _setBars(false);
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
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 200) return;
    // Swipe to the left shows the next page.
    _controller!.turnPage(v < 0 ? 1 : -1);
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
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: theme.background,
          drawer: c.isOpen ? TocDrawer(controller: c) : null,
          drawerEnableOpenDragGesture: false,
          body: Stack(children: [
            Positioned.fill(
              // Keeps text out of a camera cutout.
              child: SafeArea(
                child: Column(children: [
                  Expanded(child: _page(context, c)),
                  if (c.settings.showFooter && c.isOpen) ReaderFooter(controller: c),
                ]),
              ),
            ),
            if (_showBars && c.isOpen) ...[
              Positioned(top: 0, left: 0, right: 0, child: _topBar(context, c)),
              Positioned(bottom: 0, left: 0, right: 0, child: _bottomBar(context, c)),
            ],
          ]),
        );
      },
    );
  }

  Widget _page(BuildContext context, ReaderController c) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(builder: (context, constraints) {
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
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _onTap(d, size),
        onHorizontalDragEnd: _onSwipe,
        child: content,
      );
    });
  }

  Widget _topBar(BuildContext context, ReaderController c) {
    return Material(
      elevation: 3,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(children: [
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
              icon: const Icon(Icons.toc),
              tooltip: 'Contents',
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
                  case 'push':
                    c.pushProgress(interactive: true);
                  case 'pull':
                    c.pullProgress(interactive: true);
                  case 'sync':
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const KoSyncSettingsScreen()));
                  case 'info':
                    showPositionInfo(context, c);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'goto', child: Text('Go to page')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'push', child: Text('Push progress from this device')),
                PopupMenuItem(value: 'pull', child: Text('Pull progress from other devices')),
                PopupMenuItem(value: 'sync', child: Text('Progress sync settings')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'info', child: Text('Position info')),
              ],
            ),
          ]),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              onTap: _goto,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(children: [
                  if (c.chapterTitle.isNotEmpty)
                    Text(c.chapterTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                  Text(
                    'Page ${c.displayPage} of ${c.pageCount}  -  ${(c.progress * 100).toStringAsFixed(1)}%',
                    style: text.bodySmall,
                  ),
                ]),
              ),
            ),
            Row(children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Previous chapter',
                onPressed: c.previousChapter,
              ),
              Expanded(child: _ProgressSlider(controller: c)),
              IconButton(
                icon: const Icon(Icons.skip_next),
                tooltip: 'Next chapter',
                onPressed: c.nextChapter,
              ),
            ]),
          ]),
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
