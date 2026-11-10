// Navigation panel (Koodo left panel): contents, bookmarks, notes, highlights.
import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../annotation_style.dart';
import '../reader_controller.dart';

class TocDrawer extends StatelessWidget {
  const TocDrawer({super.key, required this.controller});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final text = Theme.of(context).textTheme;
    final notes = [
      for (final a in c.highlights)
        if (a.note != null && a.note!.isNotEmpty) a,
    ];
    return Drawer(
      width: 340,
      child: SafeArea(
        child: DefaultTabController(
          length: 4,
          child: ListenableBuilder(
            listenable: c,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.info?.title ?? '', style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if ((c.info?.authors ?? '').isNotEmpty)
                        Text(c.info!.authors, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Contents'),
                    Tab(text: 'Bookmarks'),
                    Tab(text: 'Notes'),
                    Tab(text: 'Highlights'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Contents(controller: c),
                      _AnnotationList(
                        controller: c,
                        items: c.bookmarks,
                        empty:
                            'No bookmarks. Tap the top right corner '
                            'of a page, or use the bookmark button in the menu.',
                      ),
                      _AnnotationList(controller: c, items: notes, empty: 'No notes. Select text and choose Note.'),
                      _AnnotationList(
                        controller: c,
                        items: c.highlights,
                        empty:
                            'No highlights. Long press a word, '
                            'drag to select more, and choose a color.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Contents extends StatefulWidget {
  const _Contents({required this.controller});

  final ReaderController controller;

  @override
  State<_Contents> createState() => _ContentsState();
}

class _ContentsState extends State<_Contents> {
  static const double _itemHeight = 56;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final current = widget.controller.chapterIndex;
    _scroll = ScrollController(initialScrollOffset: current < 3 ? 0 : (current - 3) * _itemHeight);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final toc = c.toc;
    final current = c.chapterIndex;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (toc.isEmpty) return const Center(child: Text('This book has no table of contents.'));
    return ListView.builder(
      controller: _scroll,
      itemExtent: _itemHeight,
      itemCount: toc.length,
      itemBuilder: (context, i) {
        final e = toc[i];
        final selected = i == current;
        return InkWell(
          onTap: () {
            Navigator.of(context).pop();
            c.gotoXPointer(e.xpointer);
          },
          child: Container(
            color: selected ? scheme.primaryContainer.withValues(alpha: 0.6) : null,
            padding: EdgeInsets.only(left: 20.0 + 16.0 * (e.depth - 1).clamp(0, 5), right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : null,
                      color: selected ? scheme.primary : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${e.page}', style: text.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AnnotationList extends StatelessWidget {
  const _AnnotationList({required this.controller, required this.items, required this.empty});

  final ReaderController controller;
  final List<Annotation> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(empty, textAlign: TextAlign.center),
      );
    }
    final text = Theme.of(context).textTheme;
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final a = items[i];
        final isBookmark = a.pos0 == null;
        return ListTile(
          leading: isBookmark
              ? const Icon(Icons.bookmark)
              : Container(width: 6, height: 40, color: highlightColor(a.color)),
          title: Text(
            a.textContent.isEmpty ? '(no text)' : a.textContent,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: isBookmark ? null : const TextStyle(fontStyle: FontStyle.italic),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.note != null && a.note!.isNotEmpty) Text(a.note!, maxLines: 3, overflow: TextOverflow.ellipsis),
              Text(
                [if (a.chapter.isNotEmpty) a.chapter, 'p. ${controller.pageOfAnnotation(a)}'].join('  -  '),
                style: text.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).pop();
            controller.gotoAnnotation(a);
          },
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Delete',
            onPressed: () => controller.deleteAnnotation(a),
          ),
        );
      },
    );
  }
}
