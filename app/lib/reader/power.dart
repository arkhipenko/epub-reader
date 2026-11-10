// Battery saving rules, kept free of Flutter and the engine so they can be
// unit-tested. The callers apply them.

/// Pages to render ahead after the reader shows [current].
/// [direction] is the last turn: +1 forward, -1 back. The page the reader
/// came from is still cached, so only the page in the reading direction is
/// rendered. In battery saver mode nothing is rendered ahead.
List<int> pagesToPrefetch({required int current, required int direction, required int pageCount, bool saver = false}) {
  if (saver) return const [];
  final next = current + (direction < 0 ? -1 : 1);
  return next >= 1 && next <= pageCount ? [next] : const [];
}

/// Pages to keep in the image cache: the current page and its neighbours.
Set<int> pagesToKeep(int current) => {current - 1, current, current + 1};

/// Minimum time in the background before a return to the app pulls the
/// reading position. KOReader pulls on every resume; this app skips short
/// app switches to save radio wake-ups.
const Duration kResumePullMinAway = Duration(minutes: 5);

bool shouldPullOnResume({required DateTime? pausedAt, required DateTime now}) =>
    pausedAt == null || now.difference(pausedAt) >= kResumePullMinAway;

/// Minimum time between library scans started by a return to the app.
const Duration kRescanMinInterval = Duration(hours: 6);

/// A return to the app rescans the library folders only when storage
/// access was just granted, or the last scan is old.
bool shouldRescanOnResume({required DateTime? lastScan, required DateTime now, required bool accessGranted}) =>
    accessGranted || lastScan == null || now.difference(lastScan) >= kRescanMinInterval;

/// Status line refresh interval (clock and battery).
Duration footerInterval({required bool saver}) => saver ? const Duration(minutes: 1) : const Duration(seconds: 30);

/// Screen timeout choices in minutes. 0: the system setting (no wake lock).
const List<int> kScreenTimeoutChoices = [0, 5, 10, 15, 30, 60];

/// Time after which an idle dictionary process is stopped.
const Duration kDictionaryIdle = Duration(minutes: 5);
