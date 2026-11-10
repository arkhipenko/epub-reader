// Dictionary lookup sheet and dictionary settings.
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../library/folders_screen.dart';
import 'dictionary_service.dart';
import 'stardict.dart';

Future<void> showDictionary(BuildContext context, String word) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scroll) => _DictionarySheet(word: word, scroll: scroll),
    ),
  );
}

class _DictionarySheet extends StatefulWidget {
  const _DictionarySheet({required this.word, required this.scroll});

  final String word;
  final ScrollController scroll;

  @override
  State<_DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<_DictionarySheet> {
  late final _query = TextEditingController(text: lookupVariants(widget.word).firstOrNull ?? widget.word.trim());
  Future<List<DictResult>>? _results;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _results ??= _lookup();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<List<DictResult>> _lookup() => ServicesScope.of(context).dictionaries.lookup(_query.text);

  @override
  Widget build(BuildContext context) {
    final service = ServicesScope.of(context).dictionaries;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Dictionaries',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DictionariesScreen())),
              ),
            ),
            onSubmitted: (_) => setState(() => _results = _lookup()),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<DictResult>>(
            future: _results,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = snap.data ?? const <DictResult>[];
              if (list.isEmpty) {
                final none = service.dictionaries.value.isEmpty;
                return ListView(
                  controller: widget.scroll,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      none
                          ? 'No dictionaries.\n\nPut StarDict dictionaries (.ifo, .idx, .dict or .dict.dz files) in a '
                                'folder on the device, then add that folder in Dictionaries (the settings button above).'
                          : 'No entry for "${_query.text.trim()}".',
                    ),
                  ],
                );
              }
              return ListView.separated(
                controller: widget.scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, i) {
                  final r = list[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.dictionary,
                        style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(r.word, style: text.titleMedium),
                      const SizedBox(height: 4),
                      SelectableText(r.text),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DictionariesScreen extends StatefulWidget {
  const DictionariesScreen({super.key});

  @override
  State<DictionariesScreen> createState() => _DictionariesScreenState();
}

class _DictionariesScreenState extends State<DictionariesScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ServicesScope.of(context).dictionaries.refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = ServicesScope.of(context).dictionaries;
    return ValueListenableBuilder<DictSettings>(
      valueListenable: service.settings,
      builder: (context, s, _) => ValueListenableBuilder<List<StarDictInfo>>(
        valueListenable: service.dictionaries,
        builder: (context, dicts, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Dictionaries'),
            actions: [
              IconButton(
                icon: _refreshing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _refreshing ? null : _refresh,
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: ListTile(
                  title: Text('Folders'),
                  subtitle: Text('StarDict dictionaries in these folders and their subfolders are used.'),
                ),
              ),
              SliverList.list(
                children: [
                  for (final f in s.folders)
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(f),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Remove',
                        onPressed: () async {
                          await service.updateSettings(s.copyWith(folders: [...s.folders]..remove(f)));
                          await _refresh();
                        },
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Icons.create_new_folder_outlined),
                    title: const Text('Add folder'),
                    onTap: () async {
                      if (!await hasStorageAccess() && !await requestStorageAccess()) return;
                      if (!context.mounted) return;
                      final dir = await pickFolder(context);
                      if (dir == null || s.folders.contains(dir)) return;
                      await service.updateSettings(s.copyWith(folders: [...s.folders, dir]));
                      await _refresh();
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Dictionaries'),
                    subtitle: Text(dicts.isEmpty ? 'None found.' : 'Drag to change the order of the results.'),
                  ),
                ],
              ),
              SliverReorderableList(
                itemCount: dicts.length,
                onReorderItem: (from, to) {
                  final list = [...dicts];
                  final item = list.removeAt(from);
                  list.insert(to, item);
                  service.dictionaries.value = list;
                  service.updateSettings(s.copyWith(order: [for (final d in list) d.ifoPath]));
                },
                itemBuilder: (context, i) {
                  final d = dicts[i];
                  return Material(
                    key: ValueKey(d.ifoPath),
                    child: SwitchListTile.adaptive(
                      secondary: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                      title: Text(d.name),
                      subtitle: Text('${d.wordCount} words'),
                      value: !s.disabled.contains(d.ifoPath),
                      onChanged: (on) {
                        final disabled = {...s.disabled};
                        on ? disabled.remove(d.ifoPath) : disabled.add(d.ifoPath);
                        service.updateSettings(s.copyWith(disabled: disabled));
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
