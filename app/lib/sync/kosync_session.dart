// kosync state for one open book: debounce, page-turn counter, periodic
// push. Timing follows koreader/plugins/kosync.koplugin/main.lua.
import 'dart:async';

import 'kosync_client.dart';
import 'kosync_decision.dart';
import 'kosync_service.dart';

/// KOReader API_CALL_DEBOUNCE_DELAY.
const Duration kSyncDebounce = Duration(seconds: 25);

/// KOReader schedules the periodic push this long after the page turn.
const Duration kPeriodicPushDelay = Duration(seconds: 10);

enum PushOutcome { pushed, skipped, notLoggedIn, failed }

class PushResult {
  const PushResult(this.outcome, [this.error]);

  final PushOutcome outcome;
  final String? error;
}

class PullResult {
  const PullResult.decision(PullDecision this.decision) : notLoggedIn = false, skipped = false, error = null;
  const PullResult.notLoggedIn() : decision = null, notLoggedIn = true, skipped = false, error = null;
  const PullResult.skipped() : decision = null, notLoggedIn = false, skipped = true, error = null;
  const PullResult.failed(String this.error) : decision = null, notLoggedIn = false, skipped = false;

  final PullDecision? decision;
  final bool notLoggedIn;
  final bool skipped;
  final String? error;
}

/// The local reading position, as kosync sends it.
class LocalProgress {
  const LocalProgress({required this.xpointer, required this.percent});

  final String xpointer;

  /// KOReader getLastPercent(): page / page count, rounded with roundPercent().
  final double percent;
}

class KoSyncSession {
  KoSyncSession({required this.service, required this.documentKey, this.metadata, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KoSyncService service;
  final String documentKey;
  final Map<String, String>? metadata;
  final DateTime Function() _clock;

  DateTime? _pushAt;
  DateTime? _pullAt;
  int _lastPage = -1;
  int _pageCounter = 0;
  Timer? _periodic;

  /// Seconds since the epoch of the last page turn, or 0 (KOReader
  /// last_page_turn_timestamp).
  int lastPageTurn = 0;

  bool _debounced(DateTime? last) => last != null && _clock().difference(last) <= kSyncDebounce;

  ProgressUpdate _update(LocalProgress p) => ProgressUpdate(
    document: documentKey,
    progress: p.xpointer,
    percentage: p.percent,
    device: service.deviceName,
    deviceId: service.deviceId,
    metadata: service.current.sendMetadata ? metadata : null,
  );

  Future<PushResult> push(LocalProgress p, {bool interactive = false}) async {
    if (!service.current.isLoggedIn) return const PushResult(PushOutcome.notLoggedIn);
    if (!interactive && _debounced(_pushAt)) return const PushResult(PushOutcome.skipped);
    _pushAt = _clock();
    try {
      await service.push(_update(p));
      // The network works now: also send what was queued.
      unawaited(service.drainQueue().catchError((_) => 0));
      return const PushResult(PushOutcome.pushed);
    } on KoSyncException catch (e) {
      return PushResult(PushOutcome.failed, e.toString());
    }
  }

  /// Queues the position without a network call (KOReader does this on
  /// close when it is offline).
  Future<void> queueOnly(LocalProgress p) => service.queue.push(_update(p));

  Future<PullResult> pull(LocalProgress p, {bool interactive = false}) async {
    if (!service.current.isLoggedIn) return const PullResult.notLoggedIn();
    if (!interactive && _debounced(_pullAt)) return const PullResult.skipped();
    _pullAt = _clock();
    try {
      final remote = await service.fetch(documentKey);
      final s = service.current;
      return PullResult.decision(
        decidePull(
          remote: remote,
          localXPointer: p.xpointer,
          localPercent: p.percent,
          deviceName: service.deviceName,
          deviceId: service.deviceId,
          lastPageTurn: lastPageTurn,
          interactive: interactive,
          forward: s.syncForward,
          backward: s.syncBackward,
        ),
      );
    } on KoSyncException catch (e) {
      return PullResult.failed(e.toString());
    }
  }

  /// KOSync:_onPageUpdate(): counts page turns and schedules the periodic
  /// push. [pushNow] sends the current position.
  void onPageChanged(int page, void Function() pushNow) {
    if (page == _lastPage) return;
    final first = _lastPage == -1;
    _lastPage = page;
    if (first) return; // Opening the book is not a page turn.
    lastPageTurn = _clock().millisecondsSinceEpoch ~/ 1000;
    _pageCounter++;
    final n = service.current.pagesBeforeUpdate;
    if (!service.current.autoSync) return;
    if (_periodic != null || (n > 0 && _pageCounter >= n)) {
      _periodic?.cancel();
      _periodic = Timer(kPeriodicPushDelay, () {
        _periodic = null;
        _pageCounter = 0;
        pushNow();
      });
    }
  }

  void dispose() {
    _periodic?.cancel();
    _periodic = null;
  }
}
