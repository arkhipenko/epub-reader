// Developer panel: the data that kosync uses (document key, XPointer,
// progress), an XPointer lookup, and the KOReader XPointer test.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_services.dart';
import '../../dev/koreader_vectors.dart';
import '../reader_controller.dart';

Future<void> showPositionInfo(BuildContext context, ReaderController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PositionInfo(controller: controller),
  );
}

class _PositionInfo extends StatefulWidget {
  const _PositionInfo({required this.controller});

  final ReaderController controller;

  @override
  State<_PositionInfo> createState() => _PositionInfoState();
}

class _PositionInfoState extends State<_PositionInfo> {
  final _input = TextEditingController();
  String? _currentText;
  String? _lookup;
  List<VectorResult>? _vectors;

  @override
  void initState() {
    super.initState();
    final xp = widget.controller.position?.xpointer;
    if (xp != null) {
      widget.controller.textAt(xp).then((t) {
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
    final text = await widget.controller.textAt(xp);
    setState(() => _lookup = text == null ? 'Not found in this document.' : 'Found. Text: $text');
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Row(
          children: [
            Expanded(
              child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace')),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy',
              onPressed: () => Clipboard.setData(ClipboardData(text: value)),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final p = c.position;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _row('Document format', c.info?.format ?? ''),
            _row('Partial MD5 (kosync document key)', c.bookId ?? ''),
            _row('Current XPointer (kosync progress)', p?.xpointer ?? ''),
            _row('Text at current XPointer', _currentText ?? ''),
            _row('Progress (kosync percentage)', c.progress.toStringAsFixed(4)),
            if (p != null) _row('Page, engine percent', '${p.page} / ${p.pageCount}, ${p.percent / 100} %'),
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
            Row(
              children: [
                OutlinedButton(onPressed: _check, child: const Text('Check')),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () async {
                    final xp = _input.text.trim();
                    if (xp.isEmpty) return;
                    final found = await c.gotoXPointer(xp);
                    if (!context.mounted) return;
                    if (found) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _lookup = 'Not found in this document.');
                    }
                  },
                  child: const Text('Go to'),
                ),
              ],
            ),
            if (_lookup != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_lookup!)),
            // Developer check against KOReader test data (juliet.epub); not in release builds.
            if (kDebugMode) ...[
              const Divider(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.fact_check),
                label: const Text('Run KOReader XPointer test (juliet.epub)'),
                onPressed: () async {
                  final r = await runJulietVectors(ServicesScope.of(context).engine);
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
            ],
          ],
        ),
      ),
    );
  }
}
