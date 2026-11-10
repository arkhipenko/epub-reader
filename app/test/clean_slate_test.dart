import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/dict/dictionary_service.dart';
import 'package:epub_reader/library/library_settings.dart';
import 'package:epub_reader/sync/kosync_client.dart';
import 'package:epub_reader/sync/kosync_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:epub_reader/sync/kosync_service.dart';
import 'package:flutter_test/flutter_test.dart';

// A new install has no servers, catalogs or folders: nothing is built in.
void main() {
  test('sync: no server, not logged in, calls refuse to run', () async {
    const s = KoSyncSettings();
    expect(s.serverUrl, isEmpty);
    expect(s.hasServer, isFalse);
    expect(s.copyWith(username: () => 'a', userkey: () => 'k').isLoggedIn, isFalse);
    expect(KoSyncSettings.decode(null).serverUrl, isEmpty);
    final db = AppDatabase(NativeDatabase.memory());
    final service = KoSyncService(db: db, settings: ValueNotifier(s), deviceId: 'D', deviceModel: 'M');
    await expectLater(service.login('a', 'b'), throwsA(isA<KoSyncException>()));
    expect(await service.drainQueue(), 0);
    await db.close();
  });

  test('library, downloads and dictionaries: no folders', () {
    expect(LibrarySettings.decode(null).folders, isEmpty);
    expect(LibrarySettings.decode(null).effectiveDownloadFolder, isNull);
    expect(DictSettings.decode(null).folders, isEmpty);
  });

  test('database: no OPDS catalogs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await db.watchCatalogs().first, isEmpty);
    await db.close();
  });
}
