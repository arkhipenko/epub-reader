// Library settings: scanned folders, download folder, view and sort.
import 'dart:convert';

enum LibraryView {
  card('Cards'),
  list('List'),
  cover('Covers');

  const LibraryView(this.label);

  final String label;
}

enum LibrarySort {
  recent('Recently read'),
  title('Title'),
  author('Author'),
  added('Recently added'),
  progress('Progress');

  const LibrarySort(this.label);

  final String label;
}

/// Book file extensions that the library scans (EPUB and FB2, also zipped FB2).
const List<String> kBookExtensions = ['.epub', '.fb2', '.fb2.zip', '.fbz'];

bool isBookFile(String path) {
  final p = path.toLowerCase();
  return kBookExtensions.any(p.endsWith);
}

class LibrarySettings {
  const LibrarySettings({
    this.folders = const [],
    this.downloadFolder,
    this.view = LibraryView.card,
    this.sort = LibrarySort.recent,
  });

  /// Android shared storage root.
  static const String storageRoot = '/storage/emulated/0';

  final List<String> folders;

  /// Folder for OPDS downloads. Null: the first library folder, or the
  /// app's own folder when there is none.
  final String? downloadFolder;
  final LibraryView view;
  final LibrarySort sort;

  String? get effectiveDownloadFolder => downloadFolder ?? (folders.isNotEmpty ? folders.first : null);

  LibrarySettings copyWith({
    List<String>? folders,
    String? Function()? downloadFolder,
    LibraryView? view,
    LibrarySort? sort,
  }) =>
      LibrarySettings(
        folders: folders ?? this.folders,
        downloadFolder: downloadFolder != null ? downloadFolder() : this.downloadFolder,
        view: view ?? this.view,
        sort: sort ?? this.sort,
      );

  String encode() => jsonEncode({
        'folders': folders,
        'downloadFolder': downloadFolder,
        'view': view.name,
        'sort': sort.name,
      });

  static LibrarySettings decode(String? text) {
    if (text == null) return const LibrarySettings();
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      return LibrarySettings(
        folders: (j['folders'] as List?)?.whereType<String>().toList() ?? const [],
        downloadFolder: j['downloadFolder'] as String?,
        view: LibraryView.values.firstWhere((v) => v.name == j['view'], orElse: () => LibraryView.card),
        sort: LibrarySort.values.firstWhere((s) => s.name == j['sort'], orElse: () => LibrarySort.recent),
      );
    } catch (_) {
      return const LibrarySettings();
    }
  }
}
