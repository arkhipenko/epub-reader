// Finds book files in the library folders and keeps the database in step.
//
// 1. A background isolate walks the folders. It computes the partial MD5
//    only for files that are new or changed since the last scan.
// 2. The engine reads metadata and the cover of each new book, one at a
//    time, so that a book open for reading waits for at most one file.
// 3. Books whose file is gone are marked missing (their data is kept).
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../engine/cre_engine.dart';
import '../sync/partial_md5.dart';
import 'library_settings.dart';

class ScanProgress {
  const ScanProgress({this.running = false, this.done = 0, this.total = 0, this.added = 0});

  final bool running;
  final int done;
  final int total;
  final int added;
}

/// A file found by the folder walk.
class FoundFile {
  const FoundFile(this.path, this.size, this.modifiedMs, this.md5);

  final String path;
  final int size;
  final int modifiedMs;

  /// Null when the file is unchanged since the last scan.
  final String? md5;
}

final RegExp _separators = RegExp(r'[/\\]');

/// Walks [roots] and returns the book files. [known] maps a path to
/// [size, modifiedMs] from the last scan; matching files are not hashed.
/// Runs in a background isolate.
List<FoundFile> walkLibrary(List<String> roots, Map<String, List<int>> known) {
  final found = <FoundFile>[];
  final seen = <String>{};
  final stack = <Directory>[
    for (final r in roots)
      if (Directory(r).existsSync()) Directory(r),
  ];
  while (stack.isNotEmpty) {
    final dir = stack.removeLast();
    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }
    for (final e in entries) {
      final name = e.path.split(_separators).last;
      if (name.startsWith('.')) continue;
      if (e is Directory) {
        // KOReader sidecar folders and Android app data hold no books.
        final parent = dir.path.split(_separators).last;
        if (name.endsWith('.sdr') || (parent == 'Android' && (name == 'data' || name == 'obb'))) continue;
        stack.add(e);
      } else if (e is File && isBookFile(e.path) && seen.add(e.path)) {
        try {
          final stat = e.statSync();
          final mtime = stat.modified.millisecondsSinceEpoch;
          final k = known[e.path];
          final unchanged = k != null && k[0] == stat.size && k[1] == mtime;
          found.add(FoundFile(e.path, stat.size, mtime, unchanged ? null : partialMd5OfFileSync(e.path)));
        } on FileSystemException {
          continue;
        }
      }
    }
  }
  return found;
}

class LibraryScanner {
  LibraryScanner({required this.db, required this.engine, required this.coversDir, required this.internalBooksDir});

  final AppDatabase db;
  final CreEngine engine;
  final String coversDir;

  /// Folder where the app keeps books opened with the file picker.
  final String internalBooksDir;

  final ValueNotifier<ScanProgress> progress = ValueNotifier(const ScanProgress());
  Future<void>? _running;

  /// End of the last completed scan (null: none in this run of the app).
  DateTime? lastScan;

  /// Scans [folders] (and the app's own book folder). A second call while a
  /// scan runs returns the running scan.
  Future<void> scan(List<String> folders) => _running ??= _scan(folders).whenComplete(() {
    _running = null;
    lastScan = DateTime.now();
  });

  Future<void> _scan(List<String> folders) async {
    progress.value = const ScanProgress(running: true);
    var added = 0;
    try {
      final books = await db.allBooks();
      final byPath = {for (final b in books) b.path: b};
      final known = <String, List<int>>{
        for (final b in books)
          if (b.fileSize != null && b.fileModified != null)
            b.path: [b.fileSize!, b.fileModified!.millisecondsSinceEpoch],
      };
      final roots = [...folders, internalBooksDir];
      final found = await Isolate.run(() => walkLibrary(roots, known));
      await Directory(coversDir).create(recursive: true);

      final seenIds = <String>{};
      final changed = <FoundFile>[];
      for (final f in found) {
        if (f.md5 == null) {
          seenIds.add(byPath[f.path]!.id);
        } else {
          seenIds.add(f.md5!);
          changed.add(f);
        }
      }
      var done = 0;
      progress.value = ScanProgress(running: true, total: changed.length);
      for (final f in changed) {
        if (await _indexFile(f)) added++;
        done++;
        progress.value = ScanProgress(running: true, done: done, total: changed.length, added: added);
      }

      // Books not found in this scan: missing, unless the file is still
      // there (for example a book opened from outside the library folders).
      final gone = [
        for (final b in books)
          if (!seenIds.contains(b.id) && !b.missing && !File(b.path).existsSync()) b.id,
      ];
      if (gone.isNotEmpty) await db.setMissing(gone, true);
      final back = [
        for (final b in books)
          if (seenIds.contains(b.id) && b.missing) b.id,
      ];
      if (back.isNotEmpty) await db.setMissing(back, false);
    } finally {
      progress.value = ScanProgress(added: added);
    }
  }

  /// Adds or updates one file. Returns true for a new book.
  Future<bool> _indexFile(FoundFile f) async {
    final id = f.md5!;
    final existing = await db.bookById(id);
    final stats = BooksCompanion(
      path: Value(f.path),
      fileSize: Value(f.size),
      fileModified: Value(DateTime.fromMillisecondsSinceEpoch(f.modifiedMs)),
      missing: const Value(false),
    );
    // A known book that moved or was touched: keep its metadata.
    if (existing != null && existing.fileSize != null) {
      await db.saveScannedBook(stats.copyWith(id: Value(id)));
      return false;
    }
    final coverPath = '$coversDir/$id';
    BookFileInfo? info;
    try {
      info = await engine.bookInfo(f.path, coverPath);
    } on EngineException {
      info = null;
    }
    if (info == null) return false;
    final fileName = f.path.split('/').last;
    await db.saveScannedBook(
      stats.copyWith(
        id: Value(id),
        title: Value(info.title.isEmpty ? fileName : info.title),
        authors: Value(info.authors),
        format: Value(info.format),
        language: Value(info.language),
        series: Value(info.series),
        seriesNumber: Value(info.seriesNumber),
        description: Value(info.description),
        coverPath: Value(info.hasCover ? coverPath : null),
      ),
    );
    return existing == null;
  }

  /// Indexes one file now (for example after a download).
  Future<void> addFile(String path) async {
    final stat = await File(path).stat();
    final md5 = await partialMd5OfFile(path);
    await Directory(coversDir).create(recursive: true);
    await _indexFile(FoundFile(path, stat.size, stat.modified.millisecondsSinceEpoch, md5));
  }
}
