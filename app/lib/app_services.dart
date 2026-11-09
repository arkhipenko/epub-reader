// App-wide services: database, engine and settings.
import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'engine/cre_engine.dart';
import 'engine/engine_assets.dart';
import 'reader/reader_settings.dart';

class AppServices {
  AppServices._(this.db, this.engine, this.settings);

  final AppDatabase db;
  final CreEngine engine;

  /// Current reading settings. The reader listens to this.
  final ValueNotifier<ReaderSettings> settings;

  static const String _settingsKey = 'reader_settings';

  static Future<AppServices> start() async {
    final db = AppDatabase();
    final paths = await prepareEngineData();
    final engine = await CreEngine.start(dataDir: paths.dataDir, cacheDir: paths.cacheDir);
    final settings = ReaderSettings.decode(await db.readPref(_settingsKey));
    return AppServices._(db, engine, ValueNotifier(settings));
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
