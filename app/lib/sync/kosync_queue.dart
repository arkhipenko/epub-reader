// Offline queue for progress updates that could not be sent.
// Same rules as koreader/plugins/kosync.koplugin/KOSyncQueue.lua:
// - a new item replaces an item for the same document queued the same day;
// - items older than 4 weeks are dropped;
// - at most 200 items (the oldest go first);
// - the queue is sent in order and stops at the first failure.
import 'dart:convert';

import 'kosync_client.dart';

const Duration kQueueMaxAge = Duration(days: 28);
const int kQueueMaxEntries = 200;

class QueuedUpdate {
  const QueuedUpdate(this.update, this.queuedAt);

  final ProgressUpdate update;

  /// Seconds since the epoch.
  final int queuedAt;

  Map<String, Object?> toJson() => {...update.toJson(), 'queued_at': queuedAt};

  static QueuedUpdate fromJson(Map<String, Object?> j) =>
      QueuedUpdate(ProgressUpdate.fromJson(j), (j['queued_at'] as num?)?.toInt() ?? 0);
}

class KoSyncQueue {
  KoSyncQueue({required this.load, required this.save, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Reads the stored queue (JSON text), or null when empty.
  final Future<String?> Function() load;
  final Future<void> Function(String) save;
  final DateTime Function() _clock;
  bool _draining = false;

  Future<List<QueuedUpdate>> items() async {
    final text = await load();
    if (text == null || text.isEmpty) return [];
    try {
      return (jsonDecode(text) as List).cast<Map<String, Object?>>().map(QueuedUpdate.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _store(List<QueuedUpdate> items) => save(jsonEncode([for (final i in items) i.toJson()]));

  Future<int> count() async => (await items()).length;

  Future<void> clear() => _store(const []);

  Future<void> push(ProgressUpdate update) async {
    final now = _clock().millisecondsSinceEpoch ~/ 1000;
    final today = now ~/ 86400;
    final kept = [
      for (final e in await items())
        if (now - e.queuedAt < kQueueMaxAge.inSeconds &&
            !(e.update.document == update.document && e.queuedAt ~/ 86400 == today))
          e,
      QueuedUpdate(update, now),
    ];
    while (kept.length > kQueueMaxEntries) {
      kept.removeAt(0);
    }
    await _store(kept);
  }

  /// Sends the queued items with [send], in order. Stops at the first error.
  /// Returns the number of items sent.
  Future<int> drain(Future<void> Function(ProgressUpdate) send) async {
    if (_draining) return 0;
    _draining = true;
    var sent = 0;
    try {
      for (final item in await items()) {
        // Skip an item that was replaced or cleared while draining.
        final current = await items();
        if (!current.any((e) => e.queuedAt == item.queuedAt && e.update.document == item.update.document)) {
          continue;
        }
        try {
          await send(item.update);
        } catch (_) {
          break;
        }
        final after = await items();
        after.removeWhere((e) => e.queuedAt == item.queuedAt && e.update.document == item.update.document);
        await _store(after);
        sent++;
      }
    } finally {
      _draining = false;
    }
    return sent;
  }
}
