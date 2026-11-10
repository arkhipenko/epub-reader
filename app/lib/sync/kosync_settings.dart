// kosync settings, with the KOReader defaults (KOSync.default_settings).
import 'dart:convert';

enum SyncStrategy {
  prompt('Ask'),
  silent('Automatic'),
  disable('Never');

  const SyncStrategy(this.label);

  final String label;

  static SyncStrategy byName(String? n, SyncStrategy fallback) =>
      SyncStrategy.values.firstWhere((s) => s.name == n, orElse: () => fallback);
}

/// How the document key is made (KOReader CHECKSUM_METHOD).
enum ChecksumMethod {
  /// Partial MD5 of the file content (KOReader "binary").
  binary('File content'),

  /// MD5 of the file name.
  filename('File name');

  const ChecksumMethod(this.label);

  final String label;

  static ChecksumMethod byName(String? n) =>
      ChecksumMethod.values.firstWhere((m) => m.name == n, orElse: () => ChecksumMethod.binary);
}

class KoSyncSettings {
  const KoSyncSettings({
    this.serverUrl = '',
    this.username,
    this.userkey,
    this.autoSync = false,
    this.pagesBeforeUpdate = 0,
    this.syncForward = SyncStrategy.prompt,
    this.syncBackward = SyncStrategy.disable,
    this.checksumMethod = ChecksumMethod.binary,
    this.sendMetadata = false,
    this.deviceName,
  });

  /// Server address. Empty until the user sets one (no server is built in).
  final String serverUrl;

  bool get hasServer => serverUrl.trim().isNotEmpty;
  final String? username;

  /// md5 of the password. The password itself is not stored.
  final String? userkey;

  /// KOReader default: off.
  final bool autoSync;

  /// Push after this many page turns (0: only on close, pause and manual push).
  final int pagesBeforeUpdate;
  final SyncStrategy syncForward;
  final SyncStrategy syncBackward;
  final ChecksumMethod checksumMethod;
  final bool sendMetadata;

  /// Name sent as "device". Null uses the device model (KOReader Device.model).
  final String? deviceName;

  bool get isLoggedIn => hasServer && (username ?? '').isNotEmpty && (userkey ?? '').isNotEmpty;

  KoSyncSettings copyWith({
    String? serverUrl,
    String? Function()? username,
    String? Function()? userkey,
    bool? autoSync,
    int? pagesBeforeUpdate,
    SyncStrategy? syncForward,
    SyncStrategy? syncBackward,
    ChecksumMethod? checksumMethod,
    bool? sendMetadata,
    String? Function()? deviceName,
  }) =>
      KoSyncSettings(
        serverUrl: serverUrl ?? this.serverUrl,
        username: username != null ? username() : this.username,
        userkey: userkey != null ? userkey() : this.userkey,
        autoSync: autoSync ?? this.autoSync,
        pagesBeforeUpdate: pagesBeforeUpdate ?? this.pagesBeforeUpdate,
        syncForward: syncForward ?? this.syncForward,
        syncBackward: syncBackward ?? this.syncBackward,
        checksumMethod: checksumMethod ?? this.checksumMethod,
        sendMetadata: sendMetadata ?? this.sendMetadata,
        deviceName: deviceName != null ? deviceName() : this.deviceName,
      );

  Map<String, Object?> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'userkey': userkey,
        'autoSync': autoSync,
        'pagesBeforeUpdate': pagesBeforeUpdate,
        'syncForward': syncForward.name,
        'syncBackward': syncBackward.name,
        'checksumMethod': checksumMethod.name,
        'sendMetadata': sendMetadata,
        'deviceName': deviceName,
      };

  static KoSyncSettings decode(String? text) {
    if (text == null) return const KoSyncSettings();
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return const KoSyncSettings();
      const d = KoSyncSettings();
      return KoSyncSettings(
        serverUrl: j['serverUrl'] is String ? j['serverUrl'] as String : '',
        username: j['username'] as String?,
        userkey: j['userkey'] as String?,
        autoSync: j['autoSync'] == true,
        pagesBeforeUpdate: j['pagesBeforeUpdate'] is int ? j['pagesBeforeUpdate'] as int : 0,
        syncForward: SyncStrategy.byName(j['syncForward'] as String?, d.syncForward),
        syncBackward: SyncStrategy.byName(j['syncBackward'] as String?, d.syncBackward),
        checksumMethod: ChecksumMethod.byName(j['checksumMethod'] as String?),
        sendMetadata: j['sendMetadata'] == true,
        deviceName: j['deviceName'] as String?,
      );
    } on FormatException {
      return const KoSyncSettings();
    }
  }

  String encode() => jsonEncode(toJson());
}
