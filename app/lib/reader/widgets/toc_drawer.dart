// Navigation panel (Koodo left panel): table of contents.
import 'package:flutter/material.dart';

import '../reader_controller.dart';

class TocDrawer extends StatefulWidget {
  const TocDrawer({super.key, required this.controller});

  final ReaderController controller;

  @override
  State<TocDrawer> createState() => _TocDrawerState();
}

class _TocDrawerState extends State<TocDrawer> {
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
    return Drawer(
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.info?.title ?? '', style: text.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
              if ((c.info?.authors ?? '').isNotEmpty)
                Text(c.info!.authors, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text('Contents', style: text.labelLarge?.copyWith(color: scheme.primary)),
          ),
          const Divider(height: 1),
          Expanded(
            child: toc.isEmpty
                ? const Center(child: Text('This book has no table of contents.'))
                : ListView.builder(
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
                          child: Row(children: [
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
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
