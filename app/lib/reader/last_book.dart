// The book that was open when the app closed. At the next start the app
// opens it again at its saved position.
import 'dart:io';

import '../data/database.dart';

class LastOpenBook {
  LastOpenBook(this._db);

  static const String prefKey = 'open_book';

  final AppDatabase _db;

  /// The path this session wrote, so that [closed] clears only its own book.
  String? _current;

  /// Reads and clears the saved path. It returns the path only when the file
  /// still exists, else null (the app then starts in the library).
  ///
  /// The value is cleared before the book opens. The reader writes it again
  /// only after the book opened, so a book that stops the app during the open
  /// is not opened again at the next start.
  Future<String?> take() async {
    final path = await _db.readPref(prefKey);
    if (path == null) return null;
    await _db.deletePref(prefKey);
    if (path.isEmpty) return null;
    try {
      return await File(path).exists() ? path : null;
    } on FileSystemException {
      return null;
    }
  }

  /// The reader opened [path].
  Future<void> opened(String path) {
    _current = path;
    return _db.writePref(prefKey, path);
  }

  /// The reader closed [path] (the user went back). If the app closes while
  /// the reader shows, this is not called and the book stays saved.
  Future<void> closed(String path) async {
    if (_current != path) return;
    _current = null;
    await _db.deletePref(prefKey);
  }
}
