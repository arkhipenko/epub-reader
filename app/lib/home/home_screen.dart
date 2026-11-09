// Start screen: recent books and opening a file. The full library
// (Koodo layout, folder scan, OPDS) replaces this in phase 4.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../reader/reader_screen.dart';
import '../sync/kosync_settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static Future<Directory> _booksDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/books');
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _open(BuildContext context, String path) async {
    if (!await File(path).exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File not found: $path')));
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(path: path)));
  }

  Future<void> _openSample(BuildContext context, String asset) async {
    final dir = await _booksDir();
    final file = File('${dir.path}/${asset.split('/').last}');
    if (!await file.exists()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    }
    if (context.mounted) await _open(context, file.path);
  }

  Future<void> _pickFile(BuildContext context) async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final picked = files.first;
    final dir = await _booksDir();
    final dest = File('${dir.path}/${picked.name}');
    // Android gives a content URI without a file path. The book is copied
    // into app storage. The copy is byte-identical, so its partial MD5 is the same.
    final sink = dest.openWrite();
    await sink.addStream(picked.xFile.openRead());
    await sink.close();
    if (context.mounted) await _open(context, dest.path);
  }

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        actions: [
          IconButton(
            tooltip: 'Progress sync',
            icon: const Icon(Icons.sync),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const KoSyncSettingsScreen())),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sample books',
            icon: const Icon(Icons.science_outlined),
            onSelected: (asset) => _openSample(context, asset),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'assets/samples/leaves.epub', child: Text('Sample EPUB (leaves.epub)')),
              PopupMenuItem(value: 'assets/samples/sample.fb2', child: Text('Sample FB2 (sample.fb2)')),
              PopupMenuItem(value: 'assets/samples/juliet.epub', child: Text('KOReader test book (juliet.epub)')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickFile(context),
        icon: const Icon(Icons.folder_open),
        label: const Text('Open book'),
      ),
      body: StreamBuilder<List<Book>>(
        stream: services.db.watchRecentBooks(),
        builder: (context, snapshot) {
          final books = snapshot.data ?? const <Book>[];
          if (books.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No books yet. Open an EPUB or FB2 file.', textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: books.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final b = books[i];
              return ListTile(
                leading: CircleAvatar(child: Text(b.format.startsWith('Fiction') ? 'FB2' : 'EPUB',
                    style: const TextStyle(fontSize: 10))),
                title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [if (b.authors.isNotEmpty) b.authors, '${(b.progress * 100).toStringAsFixed(0)}%'].join('  -  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _open(context, b.path),
                onLongPress: () async {
                  final remove = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Remove from list?'),
                      content: Text('${b.title}\n\nThe file and the reading position for it are removed.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (remove == true) {
                    await services.db.deleteBook(b.id);
                    final f = File(b.path);
                    final dir = await _booksDir();
                    // Only files that the app copied into its own folder are deleted.
                    if (f.path.startsWith(dir.path) && await f.exists()) await f.delete();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
