// "Go to" dialog: a page number, or a percent such as "50%".
import 'package:flutter/material.dart';

/// Result of the dialog: a page, or a fraction 0 to 1.
class GotoTarget {
  const GotoTarget.page(this.page) : fraction = null;
  const GotoTarget.fraction(this.fraction) : page = null;

  final int? page;
  final double? fraction;
}

/// Parses "123" as a page and "45%" or "45.5 %" as a percent.
/// Returns null for input that is not valid for [pageCount].
GotoTarget? parseGotoInput(String input, int pageCount) {
  final t = input.trim();
  if (t.endsWith('%')) {
    final v = double.tryParse(t.substring(0, t.length - 1).trim());
    if (v == null || v < 0 || v > 100) return null;
    return GotoTarget.fraction(v / 100);
  }
  final p = int.tryParse(t);
  if (p == null || p < 1 || p > pageCount) return null;
  return GotoTarget.page(p);
}

Future<GotoTarget?> showGotoDialog(BuildContext context, {required int page, required int pageCount}) =>
    showDialog<GotoTarget>(
      context: context,
      builder: (_) => _GotoDialog(page: page, pageCount: pageCount),
    );

class _GotoDialog extends StatefulWidget {
  const _GotoDialog({required this.page, required this.pageCount});

  final int page;
  final int pageCount;

  @override
  State<_GotoDialog> createState() => _GotoDialogState();
}

class _GotoDialogState extends State<_GotoDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final target = parseGotoInput(_controller.text, widget.pageCount);
    if (target == null) {
      setState(() => _error = 'Enter a page from 1 to ${widget.pageCount}, or a percent such as 50%');
      return;
    }
    Navigator.pop(context, target);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Go to'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Page or percent',
          hintText: 'Page ${widget.page} of ${widget.pageCount}, or 50%',
          errorText: _error,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Go')),
      ],
    );
  }
}
