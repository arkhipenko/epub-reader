// Advanced settings screens.
//
// - AdvancedScreen: common settings for every book (library menu: Advanced).
// - BookAdvancedScreen: settings of the open book (reader menu: Advanced for
//   this book).
//
// New settings go to one of these two screens, not to the quick reading
// settings panel.
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../engine/text_language.dart';
import 'advanced_settings.dart';
import 'reader_controller.dart';

class AdvancedScreen extends StatelessWidget {
  const AdvancedScreen({super.key});

  static String _weightLabel(double w) => w == 0 ? '0' : '${w > 0 ? '+' : ''}${w == w.roundToDouble() ? w.round() : w}';

  @override
  Widget build(BuildContext context) {
    final services = ServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced')),
      body: ValueListenableBuilder<AdvancedSettings>(
        valueListenable: services.advanced,
        builder: (context, a, _) {
          void set(AdvancedSettings next) => services.updateAdvanced(next);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const _Note(
                'These settings apply to all books. The settings of one book are in the menu of the open book: '
                'Advanced for this book.',
              ),
              const _Section('Text'),
              _Steps(
                label: 'Font weight',
                index: kFontWeightSteps.indexOf(a.fontWeight),
                count: kFontWeightSteps.length,
                format: (i) => _weightLabel(kFontWeightSteps[i]),
                onChanged: (i) => set(a.copyWith(fontWeight: kFontWeightSteps[i])),
              ),
              _Steps(
                label: 'Contrast',
                index: kFontGammaSteps.indexOf(a.fontGamma),
                count: kFontGammaSteps.length,
                format: (i) => '${kFontGammaLabels[i]}',
                onChanged: (i) => set(a.copyWith(fontGamma: kFontGammaSteps[i])),
              ),
              _Choice<WordSpacing>(
                label: 'Word spacing',
                values: WordSpacing.values,
                value: a.wordSpacing,
                text: (v) => v.label,
                onChanged: (v) => set(a.copyWith(wordSpacing: v)),
              ),
              _Choice<WordExpansion>(
                label: 'Word expansion',
                help: 'Space that the reader can add between letters to justify a line.',
                values: WordExpansion.values,
                value: a.wordExpansion,
                text: (v) => v.label,
                onChanged: (v) => set(a.copyWith(wordExpansion: v)),
              ),
              SwitchListTile(
                title: const Text('Hanging punctuation'),
                subtitle: const Text('Quotation marks, hyphens and periods can go into the margin'),
                value: a.hangingPunctuation,
                onChanged: (v) => set(a.copyWith(hangingPunctuation: v)),
              ),
              const _Section('Hyphenation'),
              SwitchListTile(
                title: const Text('Trust soft hyphens'),
                subtitle: const Text('Where a word has hyphenation points from the book, use only those'),
                value: a.trustSoftHyphens,
                onChanged: (v) => set(a.copyWith(trustSoftHyphens: v)),
              ),
              const _Section('Paragraphs'),
              const _Note('Publisher: as the book sets it.'),
              _Choice<TweakAlign>(
                label: 'Text alignment',
                values: TweakAlign.values,
                value: a.alignment,
                text: (v) => v.label,
                onChanged: (v) => set(a.copyWith(alignment: v)),
              ),
              _Choice<TweakIndent>(
                label: 'First-line indent',
                values: TweakIndent.values,
                value: a.indent,
                text: (v) => v.label,
                onChanged: (v) => set(a.copyWith(indent: v)),
              ),
              _Choice<TweakSpacing>(
                label: 'Space between paragraphs',
                values: TweakSpacing.values,
                value: a.paragraphSpacing,
                text: (v) => v.label,
                onChanged: (v) => set(a.copyWith(paragraphSpacing: v)),
              ),
              const _Section('Pages'),
              SwitchListTile(
                title: const Text('Avoid widows and orphans'),
                subtitle: const Text(
                  'No single first or last line of a paragraph alone on a page. A page can end with empty space.',
                ),
                value: a.avoidWidowsOrphans,
                onChanged: (v) => set(a.copyWith(avoidWidowsOrphans: v)),
              ),
              SwitchListTile(
                title: const Text('Avoid blank pages at chapter start and end'),
                subtitle: const Text('A chapter can start in the middle of a page'),
                value: a.avoidBlankPages,
                onChanged: (v) => set(a.copyWith(avoidBlankPages: v)),
              ),
              SwitchListTile(
                title: const Text('In-page footnotes'),
                subtitle: const Text('Show a footnote at the bottom of the page that has the link to it'),
                value: a.inPageFootnotes,
                onChanged: (v) => set(a.copyWith(inPageFootnotes: v)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset to the defaults'),
                    onPressed: a == const AdvancedSettings() ? null : () => set(const AdvancedSettings()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BookAdvancedScreen extends StatefulWidget {
  const BookAdvancedScreen({super.key, required this.controller});

  final ReaderController controller;

  @override
  State<BookAdvancedScreen> createState() => _BookAdvancedScreenState();
}

class _BookAdvancedScreenState extends State<BookAdvancedScreen> {
  late final _css = TextEditingController(text: widget.controller.bookSettings.customCss);

  ReaderController get _c => widget.controller;

  @override
  void dispose() {
    _css.dispose();
    super.dispose();
  }

  Future<void> _pickLanguage(String? bookLanguage) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LanguageSheet(selected: _c.bookSettings.language, fromBook: _fromBookLabel(bookLanguage)),
    );
    if (picked == null) return;
    await _c.updateBookSettings(_c.bookSettings.copyWith(language: () => picked.isEmpty ? null : picked));
  }

  static String _fromBookLabel(String? bookLanguage) => bookLanguage == null
      ? 'From the book (none given: ${languageLabel(kDefaultTextLanguage)})'
      : 'From the book: ${languageLabel(bookLanguage)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced for this book')),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          final b = _c.bookSettings;
          final bookLanguage = fixLanguageTag(_c.info?.language);
          void set(BookSettings next) => _c.updateBookSettings(next);
          final title = _c.info?.title ?? '';
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _Note(
                '${title.isEmpty ? 'These settings' : '"$title". These settings'} apply to this book only. '
                'The settings for all books are in the library menu: Advanced.',
              ),
              const _Section('Language'),
              ListTile(
                title: const Text('Language for hyphenation'),
                subtitle: Text(b.language == null ? _fromBookLabel(bookLanguage) : languageLabel(b.language!)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _pickLanguage(bookLanguage),
              ),
              const _Section('Ignore publisher styles'),
              SwitchListTile(
                title: const Text('Page margins'),
                subtitle: const Text('Use when the margin settings have no effect on this book'),
                value: b.ignoreMargins,
                onChanged: (v) => set(b.copyWith(ignoreMargins: v)),
              ),
              SwitchListTile(
                title: const Text('Font sizes'),
                value: b.ignoreFontSizes,
                onChanged: (v) => set(b.copyWith(ignoreFontSizes: v)),
              ),
              SwitchListTile(
                title: const Text('Font families'),
                value: b.ignoreFontFamilies,
                onChanged: (v) => set(b.copyWith(ignoreFontFamilies: v)),
              ),
              SwitchListTile(
                title: const Text('Line heights'),
                subtitle: const Text('Use when the line spacing setting has no effect on this book'),
                value: b.ignoreLineHeights,
                onChanged: (v) => set(b.copyWith(ignoreLineHeights: v)),
              ),
              const _Section('Custom CSS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _css,
                  minLines: 4,
                  maxLines: 10,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'p { text-indent: 0 !important; }',
                    helperText: 'Applied after all other styles of this book.',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    ListenableBuilder(
                      listenable: _css,
                      builder: (context, _) => FilledButton(
                        onPressed: _css.text.trim() == b.customCss.trim()
                            ? null
                            : () {
                                FocusScope.of(context).unfocus();
                                set(b.copyWith(customCss: _css.text.trim()));
                              },
                        child: const Text('Apply'),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset this book'),
                      onPressed: b.isDefault
                          ? null
                          : () {
                              _css.clear();
                              set(const BookSettings());
                            },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Language list. Pops the selected tag, or an empty string for the
/// language of the book.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.selected, required this.fromBook});

  final String? selected;
  final String fromBook;

  @override
  Widget build(BuildContext context) {
    Widget tile(String text, String value, bool on) => ListTile(
      title: Text(text),
      trailing: on ? const Icon(Icons.check) : null,
      selected: on,
      onTap: () => Navigator.of(context).pop(value),
    );
    final known = kTextLanguages.any((l) => l.tag == selected);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          tile(fromBook, '', selected == null),
          const Divider(),
          // A tag from an older setting that the table does not have.
          if (selected != null && !known) tile(selected!, selected!, true),
          for (final l in kTextLanguages) tile(languageLabel(l.tag), l.tag, l.tag == selected),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

/// A setting with a few named values, shown as one row of buttons.
class _Choice<T extends Object> extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.values,
    required this.value,
    required this.text,
    required this.onChanged,
    this.help,
  });

  final String label;
  final String? help;
  final List<T> values;
  final T value;
  final String Function(T) text;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.bodyLarge),
          if (help != null) Text(help!, style: theme.bodySmall),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [for (final v in values) ButtonSegment(value: v, label: Text(text(v)))],
              selected: {value},
              onSelectionChanged: (s) => onChanged(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

/// A setting with a short list of steps, shown as a slider. The value is
/// applied when the user lets go, because a change lays the book out again.
class _Steps extends StatefulWidget {
  const _Steps({
    required this.label,
    required this.index,
    required this.count,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final int index;
  final int count;
  final String Function(int) format;
  final ValueChanged<int> onChanged;

  @override
  State<_Steps> createState() => _StepsState();
}

class _StepsState extends State<_Steps> {
  int? _drag;

  @override
  Widget build(BuildContext context) {
    final last = widget.count - 1;
    final i = (_drag ?? widget.index).clamp(0, last);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.label, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              Text(widget.format(i)),
            ],
          ),
          Slider(
            value: i.toDouble(),
            max: last.toDouble(),
            divisions: last,
            label: widget.format(i),
            onChanged: (x) => setState(() => _drag = x.round()),
            onChangeEnd: (x) {
              setState(() => _drag = null);
              if (x.round() != widget.index) widget.onChanged(x.round());
            },
          ),
        ],
      ),
    );
  }
}
