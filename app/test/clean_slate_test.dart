import 'dart:io';

import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/dict/dictionary_service.dart';
import 'package:epub_reader/library/library_settings.dart';
import 'package:epub_reader/opds/default_catalogs.dart';
import 'package:epub_reader/sync/kosync_client.dart';
import 'package:epub_reader/sync/kosync_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:epub_reader/sync/kosync_service.dart';
import 'package:flutter_test/flutter_test.dart';

// A new install has no sync server and no folders. The only built-in data is
// the list of public OPDS catalogs; no home server and no login is built in.
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

  test('database: a new install has the public OPDS catalogs, without login data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final list = await db.watchCatalogs().first;
    expect(
      {for (final c in list) c.title: c.url},
      {
        'Project Gutenberg': 'https://m.gutenberg.org/ebooks.opds/?format=opds',
        'Standard Ebooks': 'https://standardebooks.org/feeds/opds',
        'ManyBooks': 'http://manybooks.net/opds/index.php',
      },
    );
    expect(list.every((c) => c.username == null && c.password == null), isTrue);
    await db.close();
  });

  test('defaults: no home network address is built in', () {
    expect(const KoSyncSettings().serverUrl, isEmpty);
    for (final c in kDefaultCatalogs) {
      final host = Uri.parse(c.url).host;
      expect(host.endsWith('.lan') || host.endsWith('.local'), isFalse, reason: c.url);
      expect(RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host), isFalse, reason: c.url);
    }
  });

  test('database: a deleted default catalog does not come back', () async {
    final file = File('${Directory.systemTemp.createTempSync('catalogs').path}/db.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    final first = (await db.watchCatalogs().first).first;
    await db.deleteCatalog(first.id);
    await db.close();
    db = AppDatabase(NativeDatabase(file));
    final titles = [for (final c in await db.watchCatalogs().first) c.title];
    expect(titles, hasLength(kDefaultCatalogs.length - 1));
    expect(titles, isNot(contains(first.title)));
    await db.close();
    file.parent.deleteSync(recursive: true);
  });
}
