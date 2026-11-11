// Library (Koodo manager layout): sidebar with sections and shelves,
// search, sort, card / list / cover views.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../dict/dictionary_screens.dart';
import '../opds/opds_screens.dart';
import '../reader/advanced_screens.dart';
import '../reader/reader_screen.dart';
import '../sync/kosync_settings_screen.dart';
import 'annotations_screen.dart';
import 'folders_screen.dart';
import 'library_filter.dart';
import 'library_scanner.dart';
import 'library_settings.dart';
import '../reader/power.dart';
import 'widgets/book_actions.dart';
import 'widgets/book_cover.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with WidgetsBindingObserver {
  LibrarySection _section = LibrarySection.books;
  final _search = TextEditingController();
  bool _searching = false;
  bool? _access;
  bool _started = false;

  AppServices get _services => ServicesScope.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _checkAccessAndScan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkAccessAndScan(onResume: true);
  }

  /// Checks storage access and scans the library. A return to the app scans
  /// only when access was just granted or the last scan is old (walking big
  /// folders on every app switch costs battery).
  Future<void> _checkAccessAndScan({bool onResume = false}) async {
    final before = _access;
    final access = await hasStorageAccess();
    if (!mounted) return;
    setState(() => _access = access);
    final scanner = _services.scanner;
    if (onResume &&
        !shouldRescanOnResume(
          lastScan: scanner.lastScan,
          now: DateTime.now(),
          accessGranted: access && before == false,
        )) {
      return;
    }
    // Without access only the app's own folder is scanned.
    scanner.scan(access ? _services.library.value.folders : const []).ignore();
  }

  Future<void> _open(String path) async {
    if (!await File(path).exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File not found: $path')));
      }
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(path: path)));
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    final picked = files.first;
    final dest = File('${_services.booksDir}/${picked.name}');
    // Android gives a content URI without a path: the book is copied into app
    // storage (byte-identical, so the partial MD5 is the same).
    final sink = dest.openWrite();
    await sink.addStream(picked.xFile.openRead());
    await sink.close();
    await _services.scanner.addFile(dest.path);
    await _open(dest.path);
  }

  void _select(LibrarySection s, {bool closeDrawer = true}) {
    setState(() => _section = s);
    // Navigator.pop closes a Scaffold drawer (its local history entry).
    if (closeDrawer) Navigator.of(context).pop();
  }

  void _go(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final services = _services;
    return StreamBuilder<List<Book>>(
      stream: services.db.watchLibrary(),
      builder: (context, booksSnap) => StreamBuilder<List<Shelf>>(
        stream: services.db.watchShelves(),
        builder: (context, shelvesSnap) => StreamBuilder<Map<int, Set<String>>>(
          stream: services.db.watchShelfBooks(),
          builder: (context, mapSnap) => ValueListenableBuilder<LibrarySettings>(
            valueListenable: services.library,
            builder: (context, settings, _) {
              final all = booksSnap.data ?? const <Book>[];
              final shelves = shelvesSnap.data ?? const <Shelf>[];
              final map = mapSnap.data ?? const <int, Set<String>>{};
              // A deleted shelf falls back to all books.
              if (_section.kind == SectionKind.shelf && !shelves.any((s) => s.id == _section.shelfId)) {
                _section = LibrarySection.books;
              }
              final books = libraryView(
                all,
                section: _section,
                query: _search.text.trim(),
                sort: settings.sort,
                shelves: map,
              );
              final sidebar = _Sidebar(
                selected: _section,
                all: all,
                shelves: shelves,
                shelfBooks: map,
                onSelect: (s) => _select(s, closeDrawer: !wide),
                onOpenScreen: (w) {
                  if (!wide) Navigator.of(context).pop();
                  _go(w);
                },
              );
              final body = Column(
                children: [
                  _ScanBar(progress: services.scanner.progress),
                  // Only when there are folders to scan: a new install has none.
                  if (_access == false && Platform.isAndroid && settings.folders.isNotEmpty)
                    MaterialBanner(
                      content: const Text('Allow access to all files to find the books in your folders.'),
                      actions: [
                        TextButton(onPressed: () => _go(const FoldersScreen()), child: const Text('Settings')),
                        FilledButton(
                          onPressed: () async {
                            await requestStorageAccess();
                            await _checkAccessAndScan();
                          },
                          child: const Text('Allow'),
                        ),
                      ],
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => services.scanner.scan(_access == true ? settings.folders : const []),
                      child: books.isEmpty ? _empty(context, all.isEmpty) : _books(context, books, settings.view),
                    ),
                  ),
                ],
              );
              return Scaffold(
                drawer: wide ? null : Drawer(child: sidebar),
                appBar: _appBar(context, settings),
                floatingActionButton: _section.kind == SectionKind.deleted
                    ? null
                    : FloatingActionButton.extended(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open book'),
                      ),
                body: wide
                    ? Row(
                        children: [
                          SizedBox(width: 280, child: Material(elevation: 1, child: sidebar)),
                          Expanded(child: body),
                        ],
                      )
                    : body,
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context, LibrarySettings settings) {
    return AppBar(
      title: _searching
          ? TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search title, author, series', border: InputBorder.none),
              onChanged: (_) => setState(() {}),
            )
          : Text(_section.title),
      actions: [
        IconButton(
          icon: Icon(_searching ? Icons.close : Icons.search),
          tooltip: _searching ? 'Close search' : 'Search',
          onPressed: () => setState(() {
            _searching = !_searching;
            if (!_searching) _search.clear();
          }),
        ),
        PopupMenuButton<LibrarySort>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort',
          onSelected: (s) => _services.updateLibrary(settings.copyWith(sort: s)),
          itemBuilder: (_) => [
            for (final s in LibrarySort.values)
              CheckedPopupMenuItem(value: s, checked: s == settings.sort, child: Text(s.label)),
          ],
        ),
        PopupMenuButton<LibraryView>(
          icon: Icon(switch (settings.view) {
            LibraryView.card => Icons.grid_view,
            LibraryView.list => Icons.view_list,
            LibraryView.cover => Icons.view_module,
          }),
          tooltip: 'View',
          onSelected: (v) => _services.updateLibrary(settings.copyWith(view: v)),
          itemBuilder: (_) => [
            for (final v in LibraryView.values)
              CheckedPopupMenuItem(value: v, checked: v == settings.view, child: Text(v.label)),
          ],
        ),
      ],
    );
  }

  Widget _empty(BuildContext context, bool libraryEmpty) {
    final text = switch (_section.kind) {
      _ when _search.text.isNotEmpty => 'No books match the search.',
      SectionKind.books when libraryEmpty =>
        'No books yet.\n\nAdd a folder with EPUB or FB2 files in Library folders, download books from an OPDS '
            'catalog, or open a file.',
      SectionKind.recent => 'Books you read show here.',
      SectionKind.favorites => 'No favorites. Long press a book to add it.',
      SectionKind.deleted => 'Deleted books show here. You can restore them.',
      SectionKind.shelf => 'This shelf is empty. Long press a book to add it.',
      _ => 'No books.',
    };
    // A scrollable view, so that pull-to-refresh works when the list is empty.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _books(BuildContext context, List<Book> books, LibraryView view) {
    void actions(Book b) => showBookActions(context, b, onOpen: () => _open(b.path));
    void tap(Book b) => b.deletedAt != null ? actions(b) : _open(b.path);
    switch (view) {
      case LibraryView.list:
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: books.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, i) {
            final b = books[i];
            return ListTile(
              leading: SizedBox(width: 44, height: 66, child: BookCover(book: b, decodeWidth: 132)),
              title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  if (b.authors.isNotEmpty) b.authors,
                  if (b.series.isNotEmpty) b.seriesNumber > 0 ? '${b.series} #${b.seriesNumber}' : b.series,
                ].join('  -  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _ProgressText(book: b),
              onTap: () => tap(b),
              onLongPress: () => actions(b),
            );
          },
        );
      case LibraryView.card:
      case LibraryView.cover:
        final covers = view == LibraryView.cover;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: covers ? 180 : 140,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: covers ? 2 / 3 : 0.5,
          ),
          itemCount: books.length,
          itemBuilder: (context, i) {
            final b = books[i];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => tap(b),
              onLongPress: () => actions(b),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(6),
                          child: BookCover(book: b, decodeWidth: covers ? 360 : 280),
                        ),
                        if (b.progress > 0)
                          Positioned(right: 4, bottom: 4, child: _ProgressBadge(progress: b.progress)),
                        if (b.favorite)
                          const Positioned(
                            left: 4,
                            top: 4,
                            child: Icon(
                              Icons.favorite,
                              size: 18,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 4)],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!covers) ...[
                    const SizedBox(height: 6),
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.2),
                    ),
                    if (b.authors.isNotEmpty)
                      Text(
                        b.authors,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ],
              ),
            );
          },
        );
    }
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
    child: Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 11)),
  );
}

class _ProgressText extends StatelessWidget {
  const _ProgressText({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) => book.progress > 0
      ? Text('${(book.progress * 100).round()}%', style: Theme.of(context).textTheme.bodySmall)
      : const SizedBox.shrink();
}

class _ScanBar extends StatelessWidget {
  const _ScanBar({required this.progress});

  final ValueNotifier<ScanProgress> progress;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ScanProgress>(
    valueListenable: progress,
    builder: (context, p, _) {
      if (!p.running) return const SizedBox.shrink();
      final label = p.total == 0 ? 'Looking for books...' : 'Reading new books: ${p.done} of ${p.total}';
      return Column(
        children: [
          LinearProgressIndicator(value: p.total == 0 ? null : p.done / p.total),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      );
    },
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.all,
    required this.shelves,
    required this.shelfBooks,
    required this.onSelect,
    required this.onOpenScreen,
  });

  final LibrarySection selected;
  final List<Book> all;
  final List<Shelf> shelves;
  final Map<int, Set<String>> shelfBooks;
  final ValueChanged<LibrarySection> onSelect;
  final ValueChanged<Widget> onOpenScreen;

  @override
  Widget build(BuildContext context) {
    final db = ServicesScope.of(context).db;
    final active = all.where((b) => b.deletedAt == null);
    int countOf(SectionKind k) => switch (k) {
      SectionKind.books => active.length,
      SectionKind.recent => active.where((b) => b.lastOpenedAt != null).length,
      SectionKind.favorites => active.where((b) => b.favorite).length,
      SectionKind.deleted => all.length - active.length,
      SectionKind.shelf => 0,
    };
    Widget item(LibrarySection s, IconData icon) => ListTile(
      leading: Icon(icon),
      title: Text(s.title),
      trailing: Text('${countOf(s.kind)}'),
      selected: selected == s,
      onTap: () => onSelect(s),
    );
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('images/icon.png', width: 40, height: 40),
                ),
                const SizedBox(width: 12),
                Text('Library', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          item(LibrarySection.books, Icons.menu_book_outlined),
          item(LibrarySection.recent, Icons.history),
          item(LibrarySection.favorites, Icons.favorite_border),
          item(LibrarySection.deleted, Icons.delete_outline),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Notes'),
            onTap: () => onOpenScreen(const AnnotationsScreen(notesOnly: true)),
          ),
          ListTile(
            leading: const Icon(Icons.border_color_outlined),
            title: const Text('Highlights'),
            onTap: () => onOpenScreen(const AnnotationsScreen(notesOnly: false)),
          ),
          const Divider(),
          ListTile(
            title: Text('Shelves', style: Theme.of(context).textTheme.labelLarge),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'New shelf',
              onPressed: () async {
                final name = await askText(context, 'New shelf', '');
                if (name != null && name.trim().isNotEmpty) await db.addShelf(name.trim());
              },
            ),
          ),
          for (final s in shelves)
            ListTile(
              leading: const Icon(Icons.shelves),
              title: Text(s.name),
              trailing: Text('${shelfBooks[s.id]?.length ?? 0}'),
              selected: selected.kind == SectionKind.shelf && selected.shelfId == s.id,
              onTap: () => onSelect(LibrarySection(SectionKind.shelf, shelfId: s.id, shelfName: s.name)),
              onLongPress: () => _shelfMenu(context, s),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_library_outlined),
            title: const Text('OPDS catalogs'),
            onTap: () => onOpenScreen(const OpdsCatalogsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Library folders'),
            onTap: () => onOpenScreen(const FoldersScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('Dictionaries'),
            onTap: () => onOpenScreen(const DictionariesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Progress sync'),
            onTap: () => onOpenScreen(const KoSyncSettingsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Advanced'),
            onTap: () => onOpenScreen(const AdvancedScreen()),
          ),
        ],
      ),
    );
  }

  Future<void> _shelfMenu(BuildContext context, Shelf s) async {
    final db = ServicesScope.of(context).db;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename shelf'),
              onTap: () => Navigator.pop(sheet, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete shelf (books stay in the library)'),
              onTap: () => Navigator.pop(sheet, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'rename') {
      final name = await askText(context, 'Rename shelf', s.name);
      if (name != null && name.trim().isNotEmpty) await db.renameShelf(s.id, name.trim());
    } else if (action == 'delete') {
      await db.deleteShelf(s.id);
    }
  }
}
