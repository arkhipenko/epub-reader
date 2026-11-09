// OPDS catalogs: list, feed browser, search and download.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/database.dart';
import '../library/folders_screen.dart';
import '../reader/reader_screen.dart';
import 'opds_client.dart';
import 'opds_feed.dart';

class OpdsCatalogsScreen extends StatelessWidget {
  const OpdsCatalogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = ServicesScope.of(context).db;
    return Scaffold(
      appBar: AppBar(title: const Text('OPDS catalogs')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add catalog'),
        onPressed: () => editCatalog(context, null),
      ),
      body: StreamBuilder<List<OpdsCatalog>>(
        stream: db.watchCatalogs(),
        builder: (context, snap) {
          final list = snap.data ?? const <OpdsCatalog>[];
          if (list.isEmpty) return const Center(child: Text('No catalogs.'));
          return ListView(children: [
            for (final c in list)
              ListTile(
                leading: const Icon(Icons.local_library_outlined),
                title: Text(c.title),
                subtitle: Text(c.url),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => editCatalog(context, c),
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => OpdsFeedScreen(catalog: c, url: c.url, title: c.title),
                )),
              ),
          ]);
        },
      ),
    );
  }
}

/// Add ([catalog] null) or edit a catalog.
Future<void> editCatalog(BuildContext context, OpdsCatalog? catalog) {
  return showDialog<void>(context: context, builder: (_) => _CatalogDialog(catalog: catalog));
}

class _CatalogDialog extends StatefulWidget {
  const _CatalogDialog({this.catalog});

  final OpdsCatalog? catalog;

  @override
  State<_CatalogDialog> createState() => _CatalogDialogState();
}

class _CatalogDialogState extends State<_CatalogDialog> {
  late final _title = TextEditingController(text: widget.catalog?.title ?? '');
  late final _url = TextEditingController(text: widget.catalog?.url ?? 'http://');
  late final _user = TextEditingController(text: widget.catalog?.username ?? '');
  late final _pass = TextEditingController(text: widget.catalog?.password ?? '');

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ServicesScope.of(context).db;
    final c = widget.catalog;
    return AlertDialog(
      title: Text(c == null ? 'Add catalog' : 'Edit catalog'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Name')),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Catalog address'),
          ),
          TextField(controller: _user, decoration: const InputDecoration(labelText: 'User name (optional)')),
          TextField(
            controller: _pass,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password (optional)'),
          ),
        ]),
      ),
      actions: [
        if (c != null)
          TextButton(
            onPressed: () async {
              await db.deleteCatalog(c.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final url = _url.text.trim();
            if (Uri.tryParse(url)?.hasScheme != true) return;
            final title = _title.text.trim().isEmpty ? url : _title.text.trim();
            String? opt(TextEditingController t) => t.text.trim().isEmpty ? null : t.text;
            await db.saveCatalog(OpdsCatalogsCompanion(
              id: c == null ? const Value.absent() : Value(c.id),
              title: Value(title),
              url: Value(url),
              username: Value(opt(_user)),
              password: Value(opt(_pass)),
            ));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class OpdsFeedScreen extends StatefulWidget {
  const OpdsFeedScreen({super.key, required this.catalog, required this.url, required this.title});

  final OpdsCatalog catalog;
  final String url;
  final String title;

  @override
  State<OpdsFeedScreen> createState() => _OpdsFeedScreenState();
}

class _OpdsFeedScreenState extends State<OpdsFeedScreen> {
  late OpdsCatalog _catalog = widget.catalog;
  OpdsFeed? _feed;
  final List<OpdsEntry> _entries = [];
  String? _next;
  String? _error;
  bool _loading = true;
  bool _loadingMore = false;

  OpdsClient _client() => OpdsClient(username: _catalog.username, password: _catalog.password);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = _client();
    try {
      final feed = await client.fetchFeed(widget.url);
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _entries
          ..clear()
          ..addAll(feed.entries);
        _next = feed.nextHref;
        _loading = false;
      });
    } on OpdsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (e.needsLogin) await _askLogin();
    } finally {
      client.close();
    }
  }

  Future<void> _loadMore() async {
    final next = _next;
    if (next == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    final client = _client();
    try {
      final feed = await client.fetchFeed(next);
      if (!mounted) return;
      setState(() {
        _entries.addAll(feed.entries);
        _next = feed.nextHref;
      });
    } on OpdsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      client.close();
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _askLogin() async {
    final db = ServicesScope.of(context).db;
    final user = TextEditingController(text: _catalog.username ?? '');
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login to ${_catalog.title}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: user, decoration: const InputDecoration(labelText: 'User name')),
          TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Login')),
        ],
      ),
    );
    if (ok != true) return;
    await db.saveCatalog(OpdsCatalogsCompanion(
      id: Value(_catalog.id),
      username: Value(user.text.trim()),
      password: Value(pass.text),
    ));
    _catalog = _catalog.copyWith(username: Value(user.text.trim()), password: Value(pass.text));
    await _load();
  }

  Future<void> _search() async {
    final feed = _feed;
    if (feed == null) return;
    final terms = TextEditingController();
    final q = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search the catalog'),
        content: TextField(
          controller: terms,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Title or author'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, terms.text), child: const Text('Search')),
        ],
      ),
    );
    if (q == null || q.trim().isEmpty || !mounted) return;
    final client = _client();
    try {
      final url = await client.searchUrl(feed, q.trim());
      if (!mounted) return;
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This catalog has no search.')));
        return;
      }
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => OpdsFeedScreen(catalog: _catalog, url: url, title: 'Search: ${q.trim()}'),
      ));
    } on OpdsException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final headers = OpdsClient.authHeaders(_catalog.username, _catalog.password);
    return Scaffold(
      appBar: AppBar(
        title: Text(_feed?.title.isNotEmpty == true ? _feed!.title : widget.title),
        actions: [
          if (_feed?.hasSearch == true)
            IconButton(icon: const Icon(Icons.search), tooltip: 'Search', onPressed: _search),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reload', onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Try again')),
                    ]),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.extentAfter < 400) _loadMore();
                    return false;
                  },
                  child: ListView.separated(
                    itemCount: _entries.length + (_next != null ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      if (i == _entries.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final e = _entries[i];
                      if (!e.isBook) {
                        return ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(e.title),
                          subtitle: e.summary.isEmpty
                              ? null
                              : Text(stripHtml(e.summary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          enabled: e.navigationHref != null,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) =>
                                OpdsFeedScreen(catalog: _catalog, url: e.navigationHref!, title: e.title),
                          )),
                        );
                      }
                      final thumb = e.thumbnailHref ?? e.imageHref;
                      return ListTile(
                        leading: SizedBox(
                          width: 40,
                          height: 60,
                          child: thumb == null
                              ? const Icon(Icons.menu_book)
                              : Image.network(thumb,
                                  headers: headers,
                                  fit: BoxFit.cover,
                                  cacheWidth: 120,
                                  errorBuilder: (_, _, _) => const Icon(Icons.menu_book)),
                        ),
                        title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [e.authors.join(', '), e.acquisitions.map((a) => a.label).toSet().join(' ')]
                              .where((s) => s.isNotEmpty)
                              .join('  -  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => _BookSheet(catalog: _catalog, entry: e),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _BookSheet extends StatefulWidget {
  const _BookSheet({required this.catalog, required this.entry});

  final OpdsCatalog catalog;
  final OpdsEntry entry;

  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  double? _progress;
  String? _status;
  String? _downloaded;

  Future<void> _download(OpdsAcquisition acq) async {
    final services = ServicesScope.of(context);
    final shared = await hasStorageAccess();
    final folder = (shared ? services.library.value.effectiveDownloadFolder : null) ?? services.booksDir;
    setState(() {
      _progress = 0;
      _status = 'Downloading...';
    });
    final client = OpdsClient(username: widget.catalog.username, password: widget.catalog.password);
    try {
      final name = [
        if (widget.entry.authors.isNotEmpty) widget.entry.authors.first,
        widget.entry.title,
      ].join(' - ');
      final path = await client.download(acq, folder, name, onProgress: (r, t) {
        if (mounted) setState(() => _progress = t == null || t == 0 ? null : r / t);
      });
      await services.scanner.addFile(path);
      if (!mounted) return;
      setState(() {
        _progress = 1;
        _downloaded = path;
        _status = 'Saved to $path';
      });
    } on OpdsException catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _status = e.message;
        });
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final image = e.imageHref ?? e.thumbnailHref;
    final headers = OpdsClient.authHeaders(widget.catalog.username, widget.catalog.password);
    final busy = _status == 'Downloading...';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (image != null)
              SizedBox(
                width: 96,
                height: 144,
                child: Image.network(image,
                    headers: headers,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, _, _) => const Icon(Icons.menu_book, size: 48)),
              ),
            if (image != null) const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.title, style: Theme.of(context).textTheme.titleMedium),
                if (e.authors.isNotEmpty) Text(e.authors.join(', ')),
              ]),
            ),
          ]),
          if (e.summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(stripHtml(e.summary), maxLines: 12, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in e.acquisitions)
              FilledButton.tonal(
                onPressed: a.isSupported && !busy ? () => _download(a) : null,
                child: Text('Download ${a.label}'),
              ),
          ]),
          if (e.acquisitions.every((a) => !a.isSupported))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('This app reads EPUB and FB2. The catalog offers other formats only.'),
            ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            if (busy) LinearProgressIndicator(value: _progress),
            Text(_status!),
          ],
          if (_downloaded != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text('Open'),
                onPressed: () {
                  final path = _downloaded!;
                  Navigator.of(context)
                    ..pop()
                    ..push(MaterialPageRoute<void>(builder: (_) => ReaderScreen(path: path)));
                },
              ),
            ),
        ]),
      ),
    );
  }
}
