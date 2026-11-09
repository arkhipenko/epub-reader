// Phase 1 test reader. It shows engine pages and the data needed to compare
// positions with KOReader: the partial MD5, the current XPointer, and the
// text at an XPointer.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/cre_engine.dart';
import '../sync/partial_md5.dart';
import 'koreader_vectors.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.engine, required this.path});

  final CreEngine engine;
  final String path;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  BookInfo? _info;
  PageState? _page;
  ui.Image? _image;
  String? _md5;
  String? _error;
  bool _showBars = false;
  bool _working = false;
  Size? _openedSize;

  @override
  void dispose() {
    _image?.dispose();
    unawaited(widget.engine.closeBook());
    super.dispose();
  }

  Future<void> _open(Size logical, double dpr) async {
    _openedSize = logical;
    try {
      final width = (logical.width * dpr).round();
      final height = (logical.height * dpr).round();
      // KOReader defaults, scaled like Screen:scaleBySize(): font 22, margins 10.
      int px(num v) => (v * dpr).round();
      final layout = ReaderLayout(
        fontSize: px(22),
        marginLeft: px(10),
        marginTop: px(10),
        marginRight: px(10),
        marginBottom: px(10),
      );
      final results = await Future.wait([
        widget.engine.open(widget.path, width: width, height: height, dpi: (160 * dpr).round(), layout: layout),
        partialMd5OfFile(widget.path),
      ]);
      _info = results[0] as BookInfo;
      _md5 = results[1] as String;
      await _render();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _render() async {
    final page = await widget.engine.render();
    final image = await _toImage(page);
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
      _page = page;
    });
  }

  Future<ui.Image> _toImage(PageState p) {
    final c = Completer<ui.Image>();
    ui.decodeImageFromPixels(p.rgba, p.width, p.height, ui.PixelFormat.rgba8888, c.complete);
    return c.future;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_working) return;
    _working = true;
    try {
      await action();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      _working = false;
    }
  }

  void _turn(int delta) {
    final p = _page;
    if (p == null) return;
    final target = p.page + delta;
    if (target < 1 || target > p.pageCount) return;
    _run(() async {
      await widget.engine.gotoPage(target);
      await _render();
    });
  }

  void _onTapUp(TapUpDetails d, double width) {
    final x = d.localPosition.dx;
    if (x < width / 3) {
      _turn(-1);
    } else if (x > width * 2 / 3) {
      _turn(1);
    } else {
      setState(() => _showBars = !_showBars);
    }
  }

  Future<void> _gotoXPointer(String xp) async {
    final found = await widget.engine.gotoXPointer(xp);
    if (!found) throw Exception('XPointer not found in this document');
    await _render();
  }

  void _showToc() {
    final toc = _info?.toc ?? const <TocEntry>[];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => toc.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Text('No table of contents'))
          : ListView.builder(
              itemCount: toc.length,
              itemBuilder: (_, i) {
                final e = toc[i];
                return ListTile(
                  contentPadding: EdgeInsets.only(left: 16.0 + 16.0 * (e.depth - 1), right: 16),
                  title: Text(e.title),
                  trailing: Text('${e.page}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _run(() => _gotoXPointer(e.xpointer));
                  },
                );
              },
            ),
    );
  }

  void _showDebug() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _DebugSheet(
        engine: widget.engine,
        md5: _md5 ?? '',
        page: _page,
        info: _info,
        onGoto: (xp) => _run(() => _gotoXPointer(xp)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final p = _page;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          if (_openedSize == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _open(size, dpr));
          }
          return Stack(children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _onTapUp(d, c.maxWidth),
                child: _image == null
                    ? Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator())
                    : RawImage(image: _image, fit: BoxFit.fill),
              ),
            ),
            if (_showBars) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 2,
                  child: Row(children: [
                    const BackButton(),
                    Expanded(
                      child: Text(_info?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    IconButton(icon: const Icon(Icons.toc), tooltip: 'Contents', onPressed: _showToc),
                    IconButton(icon: const Icon(Icons.bug_report), tooltip: 'Position data', onPressed: _showDebug),
                  ]),
                ),
              ),
              if (p != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        'Page ${p.page} of ${p.pageCount}  -  ${(p.percent / 100).toStringAsFixed(2)} %',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ]);
        }),
      ),
    );
  }
}

class _DebugSheet extends StatefulWidget {
  const _DebugSheet({
    required this.engine,
    required this.md5,
    required this.page,
    required this.info,
    required this.onGoto,
  });

  final CreEngine engine;
  final String md5;
  final PageState? page;
  final BookInfo? info;
  final void Function(String xpointer) onGoto;

  @override
  State<_DebugSheet> createState() => _DebugSheetState();
}

class _DebugSheetState extends State<_DebugSheet> {
  final _input = TextEditingController();
  String? _currentText;
  String? _lookup;
  List<VectorResult>? _vectors;

  @override
  void initState() {
    super.initState();
    final xp = widget.page?.xpointer;
    if (xp != null) {
      widget.engine.textAt(xp).then((t) {
        if (mounted) setState(() => _currentText = t);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final xp = _input.text.trim();
    if (xp.isEmpty) return;
    final text = await widget.engine.textAt(xp);
    setState(() => _lookup = text == null ? 'Not found in this document.' : 'Found. Text: $text');
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Row(children: [
            Expanded(child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace'))),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.page;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _row('Document format', widget.info?.format ?? ''),
          _row('Partial MD5 (kosync document key)', widget.md5),
          _row('Current XPointer', p?.xpointer ?? ''),
          _row('Text at current XPointer', _currentText ?? ''),
          if (p != null) _row('Page / percent', '${p.page} / ${p.pageCount}  ${p.percent / 100} %'),
          const Divider(),
          TextField(
            controller: _input,
            decoration: const InputDecoration(
              labelText: 'XPointer from KOReader',
              hintText: '/body/DocFragment[3]/body/p[5]/text().0',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Row(children: [
            OutlinedButton(onPressed: _check, child: const Text('Check')),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () {
                final xp = _input.text.trim();
                if (xp.isEmpty) return;
                Navigator.pop(context);
                widget.onGoto(xp);
              },
              child: const Text('Go to'),
            ),
          ]),
          if (_lookup != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_lookup!)),
          const Divider(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.fact_check),
            label: const Text('Run KOReader XPointer test (juliet.epub)'),
            onPressed: () async {
              final r = await runJulietVectors(widget.engine);
              if (mounted) setState(() => _vectors = r);
            },
          ),
          if (_vectors != null) ...[
            const SizedBox(height: 8),
            Text(
              '${_vectors!.where((r) => r.passed).length} of ${_vectors!.length} passed',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            for (final r in _vectors!)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${r.passed ? 'PASS' : 'FAIL'}  ${r.vector.source}\n'
                  '  expected "${r.vector.expected}"  got "${r.actual ?? '(not found)'}"',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: r.passed ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}
