// App-wide services: database, engine and settings.
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'data/database.dart';
import 'dict/dictionary_service.dart';
import 'engine/cre_engine.dart';
import 'engine/engine_assets.dart';
import 'library/library_scanner.dart';
import 'library/library_settings.dart';
import 'reader/reader_settings.dart';
import 'sync/kosync_service.dart';

class AppServices {
  AppServices._(
    this.db,
    this.engine,
    this.settings,
    this.kosync,
    this.library,
    this.scanner,
    this.booksDir,
    this.dictionaries,
  );

  final AppDatabase db;
  final CreEngine engine;
  final KoSyncService kosync;

  /// Library folders, view and sort.
  final ValueNotifier<LibrarySettings> library;
  final LibraryScanner scanner;

  /// The app's own folder for books opened with the file picker.
  final String booksDir;
  final DictionaryService dictionaries;

  /// Current reading settings. The reader listens to this.
  final ValueNotifier<ReaderSettings> settings;

  static const String _settingsKey = 'reader_settings';
  static const String _libraryKey = 'library_settings';

  static Future<AppServices> start() async {
    final db = AppDatabase();
    final paths = await prepareEngineData();
    final engine = await CreEngine.start(dataDir: paths.dataDir, cacheDir: paths.cacheDir);
    final settings = ReaderSettings.decode(await db.readPref(_settingsKey));
    final kosync = await KoSyncService.create(db, deviceModel: await _deviceModel());
    // Send progress that was queued while offline.
    kosync.drainQueue().ignore();
    final docs = await getApplicationDocumentsDirectory();
    final support = await getApplicationSupportDirectory();
    final booksDir = '${docs.path}/books';
    await Directory(booksDir).create(recursive: true);
    final library = LibrarySettings.decode(await db.readPref(_libraryKey));
    final scanner = LibraryScanner(
      db: db,
      engine: engine,
      coversDir: '${support.path}/covers',
      internalBooksDir: booksDir,
    );
    final dictionaries = await DictionaryService.create(db);
    return AppServices._(
      db,
      engine,
      ValueNotifier(settings),
      kosync,
      ValueNotifier(library),
      scanner,
      booksDir,
      dictionaries,
    );
  }

  Future<void> updateLibrary(LibrarySettings value) async {
    library.value = value;
    await db.writePref(_libraryKey, value.encode());
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
