// Selection menu, highlight sheet and note editor.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/database.dart';
import '../annotation_style.dart';

/// The colors offered in the selection menu (KOReader default first).
const List<String> kQuickColors = ['yellow', 'green', 'cyan', 'red', 'purple'];

/// Edits a note. Returns null on cancel, '' to remove the note.
Future<String?> editNote(BuildContext context, {String initial = '', String? quote}) =>
    showDialog<String>(context: context, builder: (_) => _NoteDialog(initial: initial, quote: quote));

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial, this.quote});

  final String initial;
  final String? quote;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Note'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.quote != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(widget.quote!, maxLines: 4, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          TextField(
            controller: _c,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(hintText: 'Your note', border: OutlineInputBorder()),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _c.text.trim()), child: const Text('Save')),
      ],
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.name, required this.onTap, this.selected = false, this.size = 28});

  final String name;
  final VoidCallback onTap;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: name[0].toUpperCase() + name.substring(1),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: highlightColor(name),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Theme.of(context).colorScheme.onSurface : Colors.black26,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      );
}

/// Actions for a text selection (Koodo popup / KOReader highlight menu).
class SelectionMenu extends StatelessWidget {
  const SelectionMenu({
    super.key,
    required this.onHighlight,
    required this.onNote,
    required this.onCopy,
    required this.onDictionary,
    required this.onSearch,
    required this.onClose,
  });

  final ValueChanged<String> onHighlight;
  final VoidCallback onNote;
  final VoidCallback onCopy;
  final VoidCallback onDictionary;
  final VoidCallback onSearch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22),
              Text(label, style: const TextStyle(fontSize: 11)),
            ]),
          ),
        );
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (final c in kQuickColors) ColorDot(name: c, onTap: () => onHighlight(c)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            action(Icons.edit_note, 'Note', onNote),
            action(Icons.copy, 'Copy', onCopy),
            action(Icons.menu_book, 'Dictionary', onDictionary),
            action(Icons.search, 'Search', onSearch),
            action(Icons.close, 'Close', onClose),
          ]),
        ]),
      ),
    );
  }
}

/// Sheet for an existing highlight: color, style, note, copy, delete.
Future<void> showHighlightSheet(
  BuildContext context,
  Annotation a, {
  required void Function({String? color, String? drawer, String? Function()? note}) onUpdate,
  required VoidCallback onDelete,
  required VoidCallback onDictionary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(a.textContent, maxLines: 6, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontStyle: FontStyle.italic)),
          if (a.note != null && a.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(a.note!, style: Theme.of(sheet).textTheme.bodyMedium),
            ),
          const SizedBox(height: 12),
          Wrap(children: [
            for (final c in kHighlightColors.keys)
              ColorDot(
                name: c,
                selected: c == a.color,
                onTap: () {
                  Navigator.pop(sheet);
                  onUpdate(color: c);
                },
              ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final d in HighlightDrawer.values)
              ChoiceChip(
                label: Text(d.label),
                selected: d.name == a.drawer,
                onSelected: (_) {
                  Navigator.pop(sheet);
                  onUpdate(drawer: d.name);
                },
              ),
          ]),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: Text(a.note == null || a.note!.isEmpty ? 'Add note' : 'Edit note'),
            onTap: () async {
              Navigator.pop(sheet);
              final n = await editNote(context, initial: a.note ?? '', quote: a.textContent);
              if (n != null) onUpdate(note: () => n.isEmpty ? null : n);
            },
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy text'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: a.textContent));
              Navigator.pop(sheet);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Dictionary'),
            onTap: () {
              Navigator.pop(sheet);
              onDictionary();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Theme.of(sheet).colorScheme.error),
            title: const Text('Delete highlight'),
            onTap: () {
              Navigator.pop(sheet);
              onDelete();
            },
          ),
        ]),
      ),
    ),
  );
}
