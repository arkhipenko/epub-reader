// Library "Notes" and "Highlights" (Koodo manager sections): annotations of
// all books. A tap opens the book at the annotation.
import 'dart:io';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../reader/annotation_style.dart';
import '../reader/reader_screen.dart';

class AnnotationsScreen extends StatelessWidget {
  const AnnotationsScreen({super.key, required this.notesOnly});

  /// True: only highlights with a note.
  final bool notesOnly;

  @override
  Widget build(BuildContext context) {
    final db = ServicesScope.of(context).db;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(notesOnly ? 'Notes' : 'Highlights')),
      body: StreamBuilder<List<(Annotation, Book)>>(
        stream: db.watchAllHighlights(),
        builder: (context, snap) {
          final all = snap.data ?? const <(Annotation, Book)>[];
          final list = notesOnly ? all.where((e) => (e.$1.note ?? '').isNotEmpty).toList() : all;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  notesOnly
                      ? 'No notes yet. In a book, select text and choose Note.'
                      : 'No highlights yet. In a book, long press a word, drag to select more, and choose a color.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final (a, b) = list[i];
              return ListTile(
                leading: Container(width: 6, height: 48, color: highlightColor(a.color)),
                title: Text(a.textContent, maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((a.note ?? '').isNotEmpty) Text(a.note!, style: text.bodyMedium),
                  Text(
                    [b.title, if (a.chapter.isNotEmpty) a.chapter].join('  -  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ]),
                onTap: () async {
                  if (!await File(b.path).exists()) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('Book file not found: ${b.path}')));
                    }
                    return;
                  }
                  if (!context.mounted) return;
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ReaderScreen(path: b.path, jumpTo: a.page),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
