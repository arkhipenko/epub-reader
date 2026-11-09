// App-wide services: database, engine and settings.
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'engine/cre_engine.dart';
import 'engine/engine_assets.dart';
import 'reader/reader_settings.dart';
import 'sync/kosync_service.dart';

class AppServices {
  AppServices._(this.db, this.engine, this.settings, this.kosync);

  final AppDatabase db;
  final CreEngine engine;
  final KoSyncService kosync;

  /// Current reading settings. The reader listens to this.
  final ValueNotifier<ReaderSettings> settings;

  static const String _settingsKey = 'reader_settings';

  static Future<AppServices> start() async {
    final db = AppDatabase();
    final paths = await prepareEngineData();
    final engine = await CreEngine.start(dataDir: paths.dataDir, cacheDir: paths.cacheDir);
    final settings = ReaderSettings.decode(await db.readPref(_settingsKey));
    final kosync = await KoSyncService.create(db, deviceModel: await _deviceModel());
    // Send progress that was queued while offline.
    kosync.drainQueue().ignore();
    return AppServices._(db, engine, ValueNotifier(settings), kosync);
  }

  /// Device model, as KOReader sends it (Device.model).
  static Future<String> _deviceModel() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) return (await info.androidInfo).model;
      if (Platform.isIOS) return (await info.iosInfo).model;
    } catch (_) {}
    return Platform.operatingSystem;
  }

  Future<void> updateSettings(ReaderSettings value) async {
    settings.value = value;
    await db.writePref(_settingsKey, value.encode());
  }
}

/// Gives the widget tree access to [AppServices].
class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope oldWidget) => services != oldWidget.services;
}
