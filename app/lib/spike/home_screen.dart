// Phase 1 test screen: starts the engine and opens a sample or a picked book.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../engine/cre_engine.dart';
import '../engine/engine_assets.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CreEngine? _engine;
  String _status = 'Starting engine...';
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _startEngine();
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  Future<void> _startEngine() async {
    try {
      final sw = Stopwatch()..start();
      final paths = await prepareEngineData();
      final engine = await CreEngine.start(dataDir: paths.dataDir, cacheDir: paths.cacheDir);
      setState(() {
        _engine = engine;
        _busy = false;
        _status = 'Engine ready (${sw.elapsedMilliseconds} ms)';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Engine failed to start:\n$e';
      });
    }
  }

  Future<Directory> _booksDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/books');
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> _openAsset(String asset) async {
    final dir = await _booksDir();
    final file = File('${dir.path}/${asset.split('/').last}');
    if (!await file.exists()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
    }
    await _openPath(file.path);
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final picked = files.first;
    final dir = await _booksDir();
    final dest = File('${dir.path}/${picked.name}');
    // Android returns a content URI without a file path. Copy the book into
    // app storage. The copy is byte-identical, so its partial MD5 is the same.
    final sink = dest.openWrite();
    await sink.addStream(picked.xFile.openRead());
    await sink.close();
    await _openPath(dest.path);
  }

  Future<void> _openPath(String path) async {
    final engine = _engine;
    if (engine == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(engine: engine, path: path),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _engine != null && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('epub-reader: engine test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: ready ? () => _openAsset('assets/samples/leaves.epub') : null,
              icon: const Icon(Icons.menu_book),
              label: const Text('Open sample EPUB (leaves.epub)'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ready ? () => _openAsset('assets/samples/sample.fb2') : null,
              icon: const Icon(Icons.menu_book),
              label: const Text('Open sample FB2 (sample.fb2)'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: ready ? () => _openAsset('assets/samples/juliet.epub') : null,
              icon: const Icon(Icons.fact_check),
              label: const Text('Open juliet.epub (KOReader XPointer test)'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: ready ? _pickFile : null,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open a book file...'),
            ),
          ],
        ),
      ),
    );
  }
}
