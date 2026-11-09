// Status line under the page (KOReader footer). The items are set in the
// reading settings.
import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';

import '../reader_controller.dart';
import '../reader_settings.dart';

class ReaderFooter extends StatefulWidget {
  const ReaderFooter({super.key, required this.controller});

  static const double height = 24;

  final ReaderController controller;

  @override
  State<ReaderFooter> createState() => _ReaderFooterState();
}

class _ReaderFooterState extends State<ReaderFooter> {
  final Battery _battery = Battery();
  Timer? _timer;
  int? _batteryLevel;

  @override
  void initState() {
    super.initState();
    _tick();
    // The clock shows minutes. Battery level changes slowly.
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  Future<void> _tick() async {
    int? level;
    try {
      level = await _battery.batteryLevel;
    } catch (_) {
      level = null;
    }
    if (mounted) setState(() => _batteryLevel = level);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _duration(Duration d) {
    final m = d.inMinutes;
    if (m < 1) return '< 1 min';
    if (m < 60) return '$m min';
    return '${m ~/ 60} h ${m % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final items = c.settings.footerItems;
    final theme = c.theme;
    final style = TextStyle(fontSize: 12, color: theme.text.withValues(alpha: 0.65), height: 1.0);
    final parts = <String>[];
    final now = TimeOfDay.now();
    if (items.contains(FooterItem.clock)) {
      parts.add('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
    }
    if (items.contains(FooterItem.pageNumber)) parts.add('${c.displayPage} / ${c.pageCount}');
    if (items.contains(FooterItem.percent)) parts.add('${(c.progress * 100).toStringAsFixed(1)}%');
    if (items.contains(FooterItem.chapterPagesLeft)) parts.add('=> ${c.chapterPagesLeft}');
    if (items.contains(FooterItem.chapterTimeLeft)) {
      final t = c.speed.timeFor(c.chapterPagesLeft + 1);
      if (t != null) parts.add(_duration(t));
    }
    if (items.contains(FooterItem.battery) && _batteryLevel != null) parts.add('$_batteryLevel%');
    final showTitle = items.contains(FooterItem.chapterTitle) && c.chapterTitle.isNotEmpty;

    return Container(
      height: ReaderFooter.height,
      color: theme.background,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        if (showTitle)
          Expanded(
            child: Text(c.chapterTitle, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        else
          const Spacer(),
        if (showTitle && parts.isNotEmpty) const SizedBox(width: 12),
        Text(parts.join('  |  '), style: style),
        if (!showTitle) const Spacer(),
      ]),
    );
  }
}
