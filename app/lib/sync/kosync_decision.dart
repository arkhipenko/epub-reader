// What to do with progress pulled from the server. This is the logic of
// KOSync:getProgress() in koreader/plugins/kosync.koplugin/main.lua.
import 'kosync_client.dart';
import 'kosync_settings.dart';

/// KOReader Math.roundPercent(): floor to 4 decimal places.
double roundPercent(double p) => (p * 10000).floorToDouble() / 10000;

enum PullOutcome {
  /// The server has no progress for this document.
  noProgress,

  /// The latest progress was sent by this device.
  fromThisDevice,

  /// The server position is the same as the local one.
  alreadySynced,

  /// Go to the server position now.
  jump,

  /// Ask the user: the server position is newer.
  askForward,

  /// Ask the user: the server position is older.
  askBackward,

  /// The sync rule for this direction is "never".
  ignored,
}

class PullDecision {
  const PullDecision(this.outcome, [this.remote]);

  final PullOutcome outcome;
  final RemoteProgress? remote;

  /// Server percent rounded as KOReader shows it in the prompt.
  int get remotePercent => remote == null ? 0 : (roundPercent(remote!.percentage) * 100).round();
}

/// [localPercent] is KOReader getLastPercent() (already rounded).
/// [lastPageTurn] is the time of the last page turn in this session, in
/// seconds since the epoch, or 0 when there was none.
/// A manual pull ([interactive]) always jumps, as in KOReader.
PullDecision decidePull({
  required RemoteProgress? remote,
  required String localXPointer,
  required double localPercent,
  required String deviceName,
  required String deviceId,
  required int lastPageTurn,
  required bool interactive,
  required SyncStrategy forward,
  required SyncStrategy backward,
}) {
  if (remote == null) return const PullDecision(PullOutcome.noProgress);
  if (remote.device == deviceName && remote.deviceId == deviceId) {
    return PullDecision(PullOutcome.fromThisDevice, remote);
  }
  final remotePct = roundPercent(remote.percentage);
  if (remotePct == localPercent || remote.progress == localXPointer) {
    return PullDecision(PullOutcome.alreadySynced, remote);
  }
  if (interactive) return PullDecision(PullOutcome.jump, remote);

  final ts = remote.timestamp;
  final selfOlder = ts != null ? ts > lastPageTurn : remotePct > localPercent;
  final strategy = selfOlder ? forward : backward;
  switch (strategy) {
    case SyncStrategy.silent:
      return PullDecision(PullOutcome.jump, remote);
    case SyncStrategy.prompt:
      return PullDecision(selfOlder ? PullOutcome.askForward : PullOutcome.askBackward, remote);
    case SyncStrategy.disable:
      return PullDecision(PullOutcome.ignored, remote);
  }
}
