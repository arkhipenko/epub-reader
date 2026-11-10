// Actions on one book (long press in the library).
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import 'book_cover.dart';

Future<void> showBookActions(BuildContext context, Book book, {required VoidCallback onOpen}) {
  final services = ServicesScope.of(context);
  final db = services.db;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      void close() => Navigator.of(sheet).pop();
      final inTrash = book.deletedAt != null;
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    SizedBox(width: 56, height: 84, child: BookCover(book: book, decodeWidth: 160)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(sheet).textTheme.titleMedium,
                          ),
                          if (book.authors.isNotEmpty)
                            Text(
                              book.authors,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(sheet).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (!inTrash) ...[
                ListTile(
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Open'),
                  onTap: () {
                    close();
                    onOpen();
                  },
                ),
                ListTile(
                  leading: Icon(book.favorite ? Icons.favorite : Icons.favorite_border),
                  title: Text(book.favorite ? 'Remove from favorites' : 'Add to favorites'),
                  onTap: () {
                    close();
                    db.setFavorite(book.id, !book.favorite);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shelves),
                  title: const Text('Shelves'),
                  onTap: () {
                    close();
                    showShelvesDialog(context, book);
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Book information'),
                onTap: () {
                  close();
                  showBookInfo(context, book);
                },
              ),
              if (!inTrash)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Move to Deleted'),
                  onTap: () {
                    close();
                    db.setDeleted(book.id, DateTime.now());
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore'),
                  onTap: () {
                    close();
                    db.setDeleted(book.id, null);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Theme.of(sheet).colorScheme.error),
                  title: const Text('Delete permanently'),
                  onTap: () {
                    close();
                    _confirmDelete(context, book);
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Deletes the file and the book data. A book file in a library folder
/// would come back at the next scan, so permanent delete removes the file.
Future<void> _confirmDelete(BuildContext context, Book book) async {
  final services = ServicesScope.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete permanently?'),
      content: Text(
        '${book.title}\n\nThe book file is deleted from the device:\n${book.path}\n\n'
        'The reading position and the shelves of this book are also removed.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return;
  try {
    final f = File(book.path);
    if (await f.exists()) await f.delete();
    final cover = book.coverPath;
    if (cover != null && await File(cover).exists()) await File(cover).delete();
    await services.db.deleteBook(book.id);
  } on FileSystemException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot delete the file: ${e.message}')));
    }
  }
}

Future<void> showShelvesDialog(BuildContext context, Book book) {
  final db = ServicesScope.of(context).db;
  return showDialog<void>(
    context: context,
    builder: (context) => StreamBuilder<List<Shelf>>(
      stream: db.watchShelves(),
      builder: (context, shelvesSnap) => StreamBuilder<Map<int, Set<String>>>(
        stream: db.watchShelfBooks(),
        builder: (context, mapSnap) {
          final shelves = shelvesSnap.data ?? const <Shelf>[];
          final map = mapSnap.data ?? const <int, Set<String>>{};
          return AlertDialog(
            title: const Text('Shelves'),
            content: SizedBox(
              width: 360,
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (shelves.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('No shelves yet.')),
                  for (final s in shelves)
                    CheckboxListTile(
                      title: Text(s.name),
                      value: map[s.id]?.contains(book.id) ?? false,
                      onChanged: (v) => db.setOnShelf(s.id, book.id, v ?? false),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final name = await askText(context, 'New shelf', '');
                  if (name != null && name.trim().isNotEmpty) {
                    final id = await db.addShelf(name.trim());
                    await db.setOnShelf(id, book.id, true);
                  }
                },
                child: const Text('New shelf'),
              ),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            ],
          );
        },
      ),
    ),
  );
}

/// A one-line text dialog. Returns null on cancel.
Future<String?> askText(BuildContext context, String title, String value, {String? hint}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(title: title, value: value, hint: hint),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.value, this.hint});

  final String title;
  final String value;
  final String? hint;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () => Navigator.pop(context, _c.text), child: const Text('OK')),
    ],
  );
}

String _size(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _date(DateTime? d) => d == null
    ? ''
    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

Future<void> showBookInfo(BuildContext context, Book book) {
  final rows = <(String, String)>[
    ('Title', book.title),
    ('Authors', book.authors),
    if (book.series.isNotEmpty)
      ('Series', book.seriesNumber > 0 ? '${book.series} #${book.seriesNumber}' : book.series),
    ('Language', book.language),
    ('Format', book.format),
    ('Progress', '${(book.progress * 100).toStringAsFixed(1)}%'),
    ('Last read', _date(book.lastOpenedAt)),
    ('Added', _date(book.addedAt)),
    ('File', book.path),
    ('Size', _size(book.fileSize)),
    ('Document key (partial MD5)', book.id),
    if (book.description.isNotEmpty) ('Description', book.description),
  ];
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Book information'),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final (k, v) in rows)
              if (v.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k, style: Theme.of(context).textTheme.labelMedium),
                      SelectableText(v),
                    ],
                  ),
                ),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ),
  );
}
