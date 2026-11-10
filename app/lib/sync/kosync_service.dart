// App-wide kosync service: settings, login, server calls and the offline
// queue. KoSyncSession holds the per-book state.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import 'kosync_client.dart';
import 'kosync_queue.dart';
import 'kosync_settings.dart';

/// A device id in the KOReader format (random.uuid() without dashes):
/// 32 upper-case hex digits of a version 4 UUID.
String newKoReaderDeviceId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x4F) | 0x40;
  b[8] = (b[8] & 0xBF) | 0x80;
  return b.map((x) => x.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
}

String md5Hex(String s) => md5.convert(utf8.encode(s)).toString();

class KoSyncService {
  KoSyncService({
    required this.db,
    required this.settings,
    required this.deviceId,
    required this.deviceModel,
    KoSyncClient Function(String serverUrl)? clientFactory,
  }) : _clientFactory = clientFactory ?? KoSyncClient.new {
    queue = KoSyncQueue(load: () => db.readPref(_queueKey), save: (t) => db.writePref(_queueKey, t));
  }

  static const String _settingsKey = 'kosync_settings';
  static const String _queueKey = 'kosync_queue';
  static const String _deviceIdKey = 'device_id';

  final AppDatabase db;
  final ValueNotifier<KoSyncSettings> settings;
  final String deviceId;
  final String deviceModel;
  final KoSyncClient Function(String serverUrl) _clientFactory;
  late final KoSyncQueue queue;

  static Future<KoSyncService> create(AppDatabase db, {required String deviceModel}) async {
    var id = await db.readPref(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = newKoReaderDeviceId();
      await db.writePref(_deviceIdKey, id);
    }
    final s = KoSyncSettings.decode(await db.readPref(_settingsKey));
    return KoSyncService(db: db, settings: ValueNotifier(s), deviceId: id, deviceModel: deviceModel);
  }

  KoSyncSettings get current => settings.value;

  /// Name sent as "device" (KOReader: kosync_hostname or Device.model).
  String get deviceName {
    final n = current.deviceName?.trim() ?? '';
    return n.isEmpty ? deviceModel : n;
  }

  Future<void> updateSettings(KoSyncSettings s) async {
    settings.value = s;
    await db.writePref(_settingsKey, s.encode());
  }

  Future<T> _withClient<T>(Future<T> Function(KoSyncClient c) f) async {
    if (!current.hasServer) throw KoSyncException('Set the sync server address first.');
    final c = _clientFactory(current.serverUrl.trim());
    try {
      return await f(c);
    } finally {
      c.close();
    }
  }

  /// Logs in. The password is not stored, only its md5 (the KOReader userkey).
  Future<void> login(String username, String password) async {
    final user = username.trim();
    final key = md5Hex(password);
    await _withClient((c) => c.authorize(user, key));
    await updateSettings(current.copyWith(username: () => user, userkey: () => key));
  }

  Future<void> register(String username, String password) async {
    final user = username.trim();
    final key = md5Hex(password);
    await _withClient((c) => c.register(user, key));
    await updateSettings(current.copyWith(username: () => user, userkey: () => key));
  }

  /// Logs out and clears the offline queue (as KOReader does).
  Future<void> logout() async {
    await updateSettings(current.copyWith(userkey: () => null));
    await queue.clear();
  }

  /// The kosync document key for a book.
  String documentKey({required String partialMd5, required String path}) {
    if (current.checksumMethod == ChecksumMethod.filename) {
      // KOReader util.splitFilePathName(): the part after the last separator.
      return md5Hex(path.split(RegExp(r'[/\\]')).last);
    }
    return partialMd5;
  }

  /// Sends one update. When it fails for a reason other than a rejected
  /// login, the update goes into the offline queue. Rethrows the error.
  Future<void> push(ProgressUpdate update) async {
    final s = current;
    try {
      await _withClient((c) => c.updateProgress(s.username!, s.userkey!, update));
    } on KoSyncException catch (e) {
      if (!e.isUnauthorized) await queue.push(update);
      rethrow;
    }
  }

  Future<RemoteProgress?> fetch(String document) {
    final s = current;
    return _withClient((c) => c.getProgress(s.username!, s.userkey!, document));
  }

  /// Sends queued updates. Returns the number sent.
  Future<int> drainQueue() async {
    final s = current;
    if (!s.isLoggedIn) return 0;
    return _withClient((c) => queue.drain((u) => c.updateProgress(s.username!, s.userkey!, u)));
  }
}
