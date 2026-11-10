// Full-text search in the open book (KOReader ReaderSearch: find all).
import 'package:flutter/material.dart';

import '../../engine/cre_engine.dart';
import '../reader_controller.dart';

Future<void> showBookSearch(BuildContext context, ReaderController controller, {String initial = ''}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => _SearchSheet(controller: controller, scroll: scroll, initial: initial),
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.controller, required this.scroll, required this.initial});

  final ReaderController controller;
  final ScrollController scroll;
  final String initial;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final _query = TextEditingController(
    text: widget.initial.isNotEmpty ? widget.initial : widget.controller.search?.query ?? '',
  );
  bool _caseInsensitive = true;
  bool _busy = false;
  List<SearchHit>? _hits;

  @override
  void initState() {
    super.initState();
    if (widget.initial.isNotEmpty) {
      _run();
    } else if (widget.controller.search != null) {
      _hits = widget.controller.search!.hits;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() => _busy = true);
    final hits = await widget.controller.findAll(q, caseInsensitive: _caseInsensitive);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hits = hits;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: TextField(
            controller: _query,
            autofocus: widget.initial.isEmpty,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search in book',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _busy
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _run),
            ),
            onSubmitted: (_) => _run(),
          ),
        ),
        SwitchListTile.adaptive(
          dense: true,
          title: const Text('Match case'),
          value: !_caseInsensitive,
          onChanged: (v) {
            setState(() => _caseInsensitive = !v);
            _run();
          },
        ),
        if (hits != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hits.isEmpty ? 'No results.' : '${hits.length} results${hits.length >= 1000 ? ' (first 1000)' : ''}',
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            controller: widget.scroll,
            itemCount: hits?.length ?? 0,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final h = hits![i];
              return ListTile(
                dense: true,
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: h.before.isEmpty ? '' : '...${h.before}'),
                      TextSpan(
                        text: h.text,
                        style: TextStyle(fontWeight: FontWeight.bold, backgroundColor: scheme.primaryContainer),
                      ),
                      TextSpan(text: h.after.isEmpty ? '' : '${h.after}...'),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${h.page}'),
                onTap: () {
                  Navigator.pop(context);
                  widget.controller.showSearchHit(SearchState(query: _query.text.trim(), hits: hits, index: i), i);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
