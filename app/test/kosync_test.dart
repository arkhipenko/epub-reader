import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:epub_reader/data/database.dart';
import 'package:epub_reader/sync/kosync_client.dart';
import 'package:epub_reader/sync/kosync_decision.dart';
import 'package:epub_reader/sync/kosync_queue.dart';
import 'package:epub_reader/sync/kosync_service.dart';
import 'package:epub_reader/sync/kosync_session.dart';
import 'package:epub_reader/sync/kosync_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory kosync server. The 412 (no accept header) and 401 body
/// {"code":2001,"message":"Unauthorized"} match the home server. The other
/// bodies are modeled on koreader-sync-server and are not verified.
class FakeKoSyncServer {
  late HttpServer _server;
  final Map<String, String> users = {};
  final Map<String, Map<String, Object?>> progress = {};
  final List<HttpRequest> requests = [];
  final List<Object?> bodies = [];
  bool down = false;
  int clock = 1000;

  String get url => 'http://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() => _server.close(force: true);

  Future<void> _reply(HttpRequest r, int status, Object body) async {
    r.response.statusCode = status;
    r.response.headers.contentType = ContentType.json;
    r.response.write(jsonEncode(body));
    await r.response.close();
  }

  Future<void> _handle(HttpRequest r) async {
    requests.add(r);
    final text = await utf8.decoder.bind(r).join();
    final body = text.isEmpty ? null : jsonDecode(text);
    bodies.add(body);
    if (down) return _reply(r, 503, {'message': 'down'});
    if (r.headers.value('accept') != 'application/vnd.koreader.v1+json') {
      return _reply(r, 412, {'code': 2000, 'message': 'Invalid Accept header format.'});
    }
    final path = r.uri.path;
    if (r.method == 'POST' && path == '/users/create') {
      final m = body as Map;
      if (users.containsKey(m['username'])) {
        return _reply(r, 402, {'code': 2002, 'message': 'Username is already registered.'});
      }
      users[m['username'] as String] = m['password'] as String;
      return _reply(r, 201, {'username': m['username']});
    }
    final user = r.headers.value('x-auth-user');
    final key = r.headers.value('x-auth-key');
    if (user == null || users[user] != key) {
      return _reply(r, 401, {'code': 2001, 'message': 'Unauthorized'});
    }
    if (r.method == 'GET' && path == '/users/auth') return _reply(r, 200, {'authorized': 'OK'});
    if (r.method == 'PUT' && path == '/syncs/progress') {
      final m = (body as Map).cast<String, Object?>();
      progress['$user/${m['document']}'] = {...m, 'timestamp': ++clock};
      return _reply(r, 200, {'document': m['document'], 'timestamp': clock});
    }
    if (r.method == 'GET' && path.startsWith('/syncs/progress/')) {
      final doc = Uri.decodeComponent(path.substring('/syncs/progress/'.length));
      return _reply(r, 200, progress['$user/$doc'] ?? <String, Object?>{});
    }
    return _reply(r, 404, {'message': 'not found'});
  }
}

void main() {
  late FakeKoSyncServer server;

  setUp(() async {
    server = FakeKoSyncServer();
    await server.start();
  });
  tearDown(() => server.stop());

  group('client', () {
    test('register, login, push and pull use the KOReader protocol', () async {
      final c = KoSyncClient(server.url);
      final key = md5Hex('secret');
      await c.register('anna', key);
      expect(server.bodies.last, {'username': 'anna', 'password': key});

      await expectLater(c.register('anna', key), throwsA(isA<KoSyncException>()
          .having((e) => e.status, 'status', 402)
          .having((e) => e.message, 'message', 'Username is already registered.')));

      await c.authorize('anna', key);
      expect(server.requests.last.headers.value('x-auth-user'), 'anna');
      expect(server.requests.last.headers.value('x-auth-key'), key);

      await expectLater(c.authorize('anna', 'wrong'),
          throwsA(isA<KoSyncException>().having((e) => e.isUnauthorized, 'unauthorized', isTrue)));

      expect(await c.getProgress('anna', key, 'doc1'), isNull);

      await c.updateProgress(
          'anna',
          key,
          const ProgressUpdate(
              document: 'doc1', progress: '/body/DocFragment[3]/body/p[2]/text().0', percentage: 0.1234,
              device: 'Pixel 6', deviceId: 'ABC'));
      expect(server.requests.last.method, 'PUT');
      expect(server.bodies.last, {
        'document': 'doc1',
        'progress': '/body/DocFragment[3]/body/p[2]/text().0',
        'percentage': 0.1234,
        'device': 'Pixel 6',
        'device_id': 'ABC',
      });

      final p = (await c.getProgress('anna', key, 'doc1'))!;
      expect(p.progress, '/body/DocFragment[3]/body/p[2]/text().0');
      expect(p.percentage, 0.1234);
      expect(p.device, 'Pixel 6');
      expect(p.deviceId, 'ABC');
      expect(p.timestamp, isNotNull);
      c.close();
    });

    test('base URL with a path and no trailing slash', () async {
      final c = KoSyncClient('${server.url}/');
      await c.register('bob', 'k');
      expect(server.requests.last.uri.path, '/users/create');
      c.close();
    });

    test('network error has no status', () async {
      final c = KoSyncClient('http://127.0.0.1:1');
      await expectLater(
          c.authorize('a', 'b'), throwsA(isA<KoSyncException>().having((e) => e.status, 'status', isNull)));
      c.close();
    });
  });

  group('pull decision (KOSync:getProgress)', () {
    RemoteProgress remote({double pct = 0.5, String xp = '/x', String device = 'Kindle', String id = 'K1', int? ts}) =>
        RemoteProgress(document: 'd', progress: xp, percentage: pct, device: device, deviceId: id, timestamp: ts);

    PullDecision decide(RemoteProgress? r,
            {double local = 0.2,
            String localXp = '/local',
            bool interactive = false,
            int lastTurn = 0,
            SyncStrategy forward = SyncStrategy.prompt,
            SyncStrategy backward = SyncStrategy.disable}) =>
        decidePull(
          remote: r,
          localXPointer: localXp,
          localPercent: local,
          deviceName: 'Pixel 6',
          deviceId: 'P1',
          lastPageTurn: lastTurn,
          interactive: interactive,
          forward: forward,
          backward: backward,
        );

    test('no progress, own device, already synced', () {
      expect(decide(null).outcome, PullOutcome.noProgress);
      expect(decide(remote(device: 'Pixel 6', id: 'P1')).outcome, PullOutcome.fromThisDevice);
      expect(decide(remote(pct: 0.2)).outcome, PullOutcome.alreadySynced);
      expect(decide(remote(xp: '/local')).outcome, PullOutcome.alreadySynced);
    });

    test('a manual pull always jumps', () {
      expect(decide(remote(pct: 0.1), interactive: true).outcome, PullOutcome.jump);
    });

    test('defaults: ask for newer, ignore older (by percent without timestamp)', () {
      expect(decide(remote(pct: 0.6)).outcome, PullOutcome.askForward);
      expect(decide(remote(pct: 0.1)).outcome, PullOutcome.ignored);
    });

    test('timestamp decides direction when present', () {
      // Remote percent is lower, but it was saved after the last local page turn.
      expect(decide(remote(pct: 0.1, ts: 2000), lastTurn: 1000).outcome, PullOutcome.askForward);
      // Remote percent is higher, but local turned a page later.
      expect(decide(remote(pct: 0.9, ts: 1000), lastTurn: 2000, backward: SyncStrategy.prompt).outcome,
          PullOutcome.askBackward);
    });

    test('silent strategies jump', () {
      expect(decide(remote(pct: 0.6), forward: SyncStrategy.silent).outcome, PullOutcome.jump);
      expect(decide(remote(pct: 0.1), backward: SyncStrategy.silent).outcome, PullOutcome.jump);
    });

    test('roundPercent floors to 4 decimals', () {
      expect(roundPercent(0.123456), 0.1234);
      expect(roundPercent(0.99999), 0.9999);
      expect(decide(remote(pct: 0.20004)).outcome, PullOutcome.alreadySynced);
    });
  });

  group('offline queue (KOSyncQueue)', () {
    String? stored;
    late DateTime now;
    KoSyncQueue queue() => KoSyncQueue(load: () async => stored, save: (t) async => stored = t, clock: () => now);
    ProgressUpdate u(String doc, [String xp = '/x']) =>
        ProgressUpdate(document: doc, progress: xp, percentage: 0.5, device: 'd', deviceId: 'i');

    setUp(() {
      stored = null;
      now = DateTime.utc(2026, 11, 9, 12);
    });

    test('same document on the same day is replaced', () async {
      final q = queue();
      await q.push(u('a', '/1'));
      await q.push(u('b'));
      await q.push(u('a', '/2'));
      final items = await q.items();
      expect(items.map((i) => '${i.update.document}${i.update.progress}'), ['b/x', 'a/2']);
    });

    test('a new day keeps the older item; items older than 4 weeks drop', () async {
      final q = queue();
      await q.push(u('a', '/1'));
      now = now.add(const Duration(days: 1));
      await q.push(u('a', '/2'));
      expect(await q.count(), 2);
      now = now.add(const Duration(days: 28));
      await q.push(u('c'));
      expect((await q.items()).map((i) => i.update.document), ['c']);
    });

    test('at most 200 items', () async {
      final q = queue();
      for (var i = 0; i < 205; i++) {
        await q.push(u('doc$i'));
      }
      final items = await q.items();
      expect(items.length, kQueueMaxEntries);
      expect(items.first.update.document, 'doc5');
    });

    test('drain sends in order and stops at the first failure', () async {
      final q = queue();
      await q.push(u('a'));
      await q.push(u('b'));
      await q.push(u('c'));
      final sent = <String>[];
      final n = await q.drain((x) async {
        if (x.document == 'b') throw KoSyncException('offline');
        sent.add(x.document);
      });
      expect(n, 1);
      expect(sent, ['a']);
      expect((await q.items()).map((i) => i.update.document), ['b', 'c']);
    });
  });

  test('device id has the KOReader format', () {
    for (var i = 0; i < 20; i++) {
      final id = newKoReaderDeviceId();
      expect(id, matches(RegExp(r'^[0-9A-F]{32}$')));
      expect(id[12], '4');
      expect('89AB'.contains(id[16]), isTrue);
    }
  });

  group('session with service', () {
    late AppDatabase db;
    late KoSyncService service;
    late DateTime now;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      now = DateTime.utc(2026, 11, 9, 12);
      server.users['anna'] = md5Hex('pw');
      service = KoSyncService(
        db: db,
        settings: ValueNotifier(KoSyncSettings(serverUrl: server.url, autoSync: true)),
        deviceId: 'P1',
        deviceModel: 'Pixel 6',
      );
      await service.login('anna', 'pw');
    });
    tearDown(() => db.close());

    const local = LocalProgress(xpointer: '/body/DocFragment[2]/body/p[1]/text().0', percent: 0.25);

    test('automatic push is debounced for 25 s, manual push is not', () async {
      final s = KoSyncSession(service: service, documentKey: 'doc', clock: () => now);
      expect((await s.push(local)).outcome, PushOutcome.pushed);
      now = now.add(const Duration(seconds: 10));
      expect((await s.push(local)).outcome, PushOutcome.skipped);
      expect((await s.push(local, interactive: true)).outcome, PushOutcome.pushed);
      now = now.add(const Duration(seconds: 26));
      expect((await s.push(local)).outcome, PushOutcome.pushed);
    });

    test('a failed push is queued and sent later', () async {
      final s = KoSyncSession(service: service, documentKey: 'doc', clock: () => now);
      server.down = true;
      expect((await s.push(local)).outcome, PushOutcome.failed);
      expect(await service.queue.count(), 1);
      server.down = false;
      expect(await service.drainQueue(), 1);
      expect(await service.queue.count(), 0);
      expect(server.progress['anna/doc']?['progress'], local.xpointer);
    });

    test('pull sees progress from another device', () async {
      server.progress['anna/doc'] = {
        'document': 'doc',
        'progress': '/body/DocFragment[9]/body/p[4]/text().0',
        'percentage': 0.6,
        'device': 'Kindle',
        'device_id': 'K1',
        'timestamp': 5000,
      };
      final s = KoSyncSession(service: service, documentKey: 'doc', clock: () => now);
      final r = await s.pull(local);
      expect(r.decision?.outcome, PullOutcome.askForward);
      expect(r.decision?.remote?.progress, '/body/DocFragment[9]/body/p[4]/text().0');
      expect(r.decision?.remotePercent, 60);
    });

    test('filename checksum method uses md5 of the file name', () async {
      await service.updateSettings(service.current.copyWith(checksumMethod: ChecksumMethod.filename));
      expect(service.documentKey(partialMd5: 'x', path: '/a/b/Book.epub'), md5Hex('Book.epub'));
    });
  });
}
