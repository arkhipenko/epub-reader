// Reading settings panel (Koodo right panel; a bottom sheet on phones).
import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../reader_settings.dart';
import '../reader_theme.dart';
import '../tap_zones.dart';

Future<void> showReaderSettings(BuildContext context, {required List<String> fontFaces}) {
  final services = ServicesScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    // A light barrier, so the page change shows while the panel is open.
    barrierColor: Colors.black12,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scroll) => ValueListenableBuilder<ReaderSettings>(
        valueListenable: services.settings,
        builder: (context, s, _) => _SettingsBody(
          scroll: scroll,
          settings: s,
          fontFaces: fontFaces,
          onChanged: services.updateSettings,
        ),
      ),
    ),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.scroll,
    required this.settings,
    required this.fontFaces,
    required this.onChanged,
  });

  final ScrollController scroll;
  final ReaderSettings settings;
  final List<String> fontFaces;
  final ValueChanged<ReaderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final text = Theme.of(context).textTheme;
    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(t, style: text.labelLarge),
        );
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        label('Theme'),
        Row(
          children: [
            for (final t in kReaderThemes)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ThemeSwatch(
                  theme: t,
                  selected: t.id == s.themeId,
                  onTap: () => onChanged(s.copyWith(themeId: t.id)),
                ),
              ),
          ],
        ),
        label('Font'),
        DropdownButton<String>(
          isExpanded: true,
          value: fontFaces.contains(s.fontFace) ? s.fontFace : null,
          hint: Text(s.fontFace),
          items: [
            for (final f in fontFaces) DropdownMenuItem(value: f, child: Text(f)),
          ],
          onChanged: (f) {
            if (f != null) onChanged(s.copyWith(fontFace: f));
          },
        ),
        _SliderRow(
          label: 'Font size',
          value: s.fontSize,
          min: ReaderSettings.minFontSize,
          max: ReaderSettings.maxFontSize,
          divisions: (ReaderSettings.maxFontSize - ReaderSettings.minFontSize).round(),
          format: (v) => v.round().toString(),
          onChanged: (v) => onChanged(s.copyWith(fontSize: v.roundToDouble())),
          stepButtons: true,
        ),
        _SliderRow(
          label: 'Line spacing',
          value: s.lineSpacing.toDouble(),
          min: ReaderSettings.minLineSpacing.toDouble(),
          max: ReaderSettings.maxLineSpacing.toDouble(),
          divisions: (ReaderSettings.maxLineSpacing - ReaderSettings.minLineSpacing) ~/ 5,
          format: (v) => '${v.round()}%',
          onChanged: (v) => onChanged(s.copyWith(lineSpacing: (v / 5).round() * 5)),
        ),
        _SliderRow(
          label: 'Side margins',
          value: s.marginHorizontal,
          min: 0,
          max: ReaderSettings.maxMargin,
          divisions: ReaderSettings.maxMargin.round() ~/ 2,
          format: (v) => v.round().toString(),
          onChanged: (v) => onChanged(s.copyWith(marginHorizontal: v.roundToDouble())),
        ),
        _SliderRow(
          label: 'Top and bottom margins',
          value: s.marginVertical,
          min: 0,
          max: ReaderSettings.maxMargin,
          divisions: ReaderSettings.maxMargin.round() ~/ 2,
          format: (v) => v.round().toString(),
          onChanged: (v) => onChanged(s.copyWith(marginVertical: v.roundToDouble())),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Hyphenation'),
          value: s.hyphenation,
          onChanged: (v) => onChanged(s.copyWith(hyphenation: v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Publisher styles'),
          subtitle: const Text('Use the styles that come with the book'),
          value: s.embeddedStyles,
          onChanged: (v) => onChanged(s.copyWith(embeddedStyles: v)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Publisher fonts'),
          subtitle: const Text('Use the fonts that come with the book'),
          value: s.embeddedFonts,
          onChanged: (v) => onChanged(s.copyWith(embeddedFonts: v)),
        ),
        label('Page turn tap zones'),
        DropdownButton<TapLayout>(
          isExpanded: true,
          value: s.tapLayout,
          items: [
            for (final l in TapLayout.values) DropdownMenuItem(value: l, child: Text(l.label)),
          ],
          onChanged: (l) {
            if (l != null) onChanged(s.copyWith(tapLayout: l));
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Status line'),
          value: s.showFooter,
          onChanged: (v) => onChanged(s.copyWith(showFooter: v)),
        ),
        if (s.showFooter)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final item in FooterItem.values)
                FilterChip(
                  label: Text(item.label),
                  selected: s.footerItems.contains(item),
                  onSelected: (on) {
                    final next = {...s.footerItems};
                    on ? next.add(item) : next.remove(item);
                    onChanged(s.copyWith(footerItems: next));
                  },
                ),
            ],
          ),
        label('Accent color'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final a in kAccentColors)
              Tooltip(
                message: a.name,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(s.copyWith(accentId: a.id)),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: a.color,
                    child: a.id == s.accentId ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme, required this.selected, required this.onTap});

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: theme.name,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? accent : Colors.black26,
              width: selected ? 3 : 1,
            ),
          ),
          child: Text('Aa', style: TextStyle(color: theme.text, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// A slider that shows its value while dragging and applies it when the
/// drag ends, because each change lays out the whole book again.
class _SliderRow extends StatefulWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    this.stepButtons = false,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final bool stepButtons;

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final v = (_dragValue ?? widget.value).clamp(widget.min, widget.max);
    final step = (widget.max - widget.min) / widget.divisions;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          Text(widget.format(v)),
        ]),
        Row(children: [
          if (widget.stepButtons)
            IconButton(
              tooltip: 'Smaller',
              icon: const Icon(Icons.text_decrease),
              onPressed: v > widget.min ? () => widget.onChanged((v - step).clamp(widget.min, widget.max)) : null,
            ),
          Expanded(
            child: Slider(
              value: v,
              min: widget.min,
              max: widget.max,
              divisions: widget.divisions,
              label: widget.format(v),
              onChanged: (x) => setState(() => _dragValue = x),
              onChangeEnd: (x) {
                setState(() => _dragValue = null);
                widget.onChanged(x);
              },
            ),
          ),
          if (widget.stepButtons)
            IconButton(
              tooltip: 'Larger',
              icon: const Icon(Icons.text_increase),
              onPressed: v < widget.max ? () => widget.onChanged((v + step).clamp(widget.min, widget.max)) : null,
            ),
        ]),
      ]),
    );
  }
}
