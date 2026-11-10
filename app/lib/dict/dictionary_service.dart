// Dictionaries: discovery in folders, order and enable state, and lookups
// in a background isolate (indexes of big dictionaries take time to load).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../data/database.dart';
import 'stardict.dart';

class DictSettings {
  const DictSettings({this.folders = const [], this.order = const [], this.disabled = const {}});

  final List<String> folders;

  /// .ifo paths in the user's order. Dictionaries not listed come after.
  final List<String> order;
  final Set<String> disabled;

  DictSettings copyWith({List<String>? folders, List<String>? order, Set<String>? disabled}) => DictSettings(
        folders: folders ?? this.folders,
        order: order ?? this.order,
        disabled: disabled ?? this.disabled,
      );

  String encode() => jsonEncode({'folders': folders, 'order': order, 'disabled': disabled.toList()});

  static DictSettings decode(String? text) {
    if (text == null) return const DictSettings();
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      return DictSettings(
        folders: (j['folders'] as List?)?.whereType<String>().toList() ?? const [],
        order: (j['order'] as List?)?.whereType<String>().toList() ?? const [],
        disabled: (j['disabled'] as List?)?.whereType<String>().toSet() ?? const {},
      );
    } catch (_) {
      return const DictSettings();
    }
  }
}

class DictResult {
  const DictResult({required this.dictionary, required this.word, required this.text});

  final String dictionary;
  final String word;
  final String text;
}

/// The forms of a selected word to look up: without surrounding
/// punctuation, as is, lower case, and capitalized.
List<String> lookupVariants(String selection) {
  final w = selection
      .trim()
      .replaceAll(RegExp(r"^[\p{P}\p{S}\s]+|[\p{P}\p{S}\s]+$", unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (w.isEmpty) return const [];
  final lower = w.toLowerCase();
  final cap = lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  return {w, lower, cap}.toList();
}

/// Finds .ifo files under [folders] (runs in a background isolate).
List<String> findIfoFiles(List<String> folders) {
  final out = <String>[];
  for (final f in folders) {
    final d = Directory(f);
    if (!d.existsSync()) continue;
    try {
      for (final e in d.listSync(recursive: true, followLinks: false)) {
        if (e is File && e.path.toLowerCase().endsWith('.ifo')) out.add(e.path);
      }
    } on FileSystemException {
      continue;
    }
  }
  return out;
}

class DictionaryService {
  DictionaryService({required this.db, required this.settings});

  static const String _key = 'dict_settings';

  final AppDatabase db;
  final ValueNotifier<DictSettings> settings;
  _DictWorker? _worker;

  /// Discovered dictionaries in the user's order.
  final ValueNotifier<List<StarDictInfo>> dictionaries = ValueNotifier(const []);

  static Future<DictionaryService> create(AppDatabase db) async {
    final s = DictSettings.decode(await db.readPref(_key));
    final service = DictionaryService(db: db, settings: ValueNotifier(s));
    service.refresh().ignore();
    return service;
  }

  Future<void> updateSettings(DictSettings s) async {
    settings.value = s;
    await db.writePref(_key, s.encode());
  }

  /// Finds the dictionaries in the folders again.
  Future<void> refresh() async {
    final folders = settings.value.folders;
    final files = await Isolate.run(() => findIfoFiles(folders));
    final infos = [for (final f in files) StarDictInfo.read(f)].whereType<StarDictInfo>().toList();
    dictionaries.value = ordered(infos, settings.value.order);
  }

  static List<StarDictInfo> ordered(List<StarDictInfo> infos, List<String> order) {
    int rank(StarDictInfo i) {
      final r = order.indexOf(i.ifoPath);
      return r < 0 ? order.length : r;
    }

    return [...infos]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  /// Looks [selection] up in the enabled dictionaries, in order.
  Future<List<DictResult>> lookup(String selection) async {
    final variants = lookupVariants(selection);
    if (variants.isEmpty) return const [];
    final enabled = [
      for (final d in dictionaries.value)
        if (!settings.value.disabled.contains(d.ifoPath)) d.ifoPath,
    ];
    if (enabled.isEmpty) return const [];
    _worker ??= await _DictWorker.start();
    return _worker!.lookup(enabled, variants);
  }
}

class _DictWorker {
  _DictWorker(this._send);

  final SendPort _send;
  final Map<int, Completer<List<DictResult>>> _pending = {};
  int _next = 1;

  static Future<_DictWorker> start() async {
    final receive = ReceivePort();
    await Isolate.spawn(_main, receive.sendPort, debugName: 'dictionaries');
    final ready = Completer<SendPort>();
    late final _DictWorker w;
    receive.listen((m) {
      if (m is SendPort) {
        ready.complete(m);
        return;
      }
      final list = m as List;
      final c = w._pending.remove(list[0] as int);
      c?.complete([
        for (final r in (list[1] as List).cast<List>())
          DictResult(dictionary: r[0] as String, word: r[1] as String, text: r[2] as String),
      ]);
    });
    w = _DictWorker(await ready.future);
    return w;
  }

  Future<List<DictResult>> lookup(List<String> ifoPaths, List<String> variants) {
    final id = _next++;
    final c = Completer<List<DictResult>>();
    _pending[id] = c;
    _send.send([id, ifoPaths, variants]);
    return c.future;
  }

  static void _main(SendPort out) {
    final inbox = ReceivePort();
    out.send(inbox.sendPort);
    final open = <String, StarDict?>{};
    inbox.listen((m) {
      final msg = m as List;
      final results = <List<String>>[];
      for (final path in (msg[1] as List).cast<String>()) {
        final dict = open.putIfAbsent(path, () {
          final info = StarDictInfo.read(path);
          if (info == null) return null;
          try {
            return StarDict.open(info);
          } catch (_) {
            return null; // A broken dictionary gives no results.
          }
        });
        if (dict == null) continue;
        final seen = <String>{};
        for (final v in (msg[2] as List).cast<String>()) {
          for (final e in dict.lookup(v)) {
            final text = e.plainText;
            if (seen.add('${e.word}\n$text')) results.add([dict.info.name, e.word, text]);
          }
        }
      }
      out.send([msg[0], results]);
    });
  }
}
