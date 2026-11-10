// kosync HTTP client. Follows koreader/plugins/kosync.koplugin
// (KOSyncClient.lua and api.json):
//   POST /users/create          register    -> 201
//   GET  /users/auth            authorize   -> 200
//   PUT  /syncs/progress        update      -> 200
//   GET  /syncs/progress/:doc   get         -> 200
// Every request sends "accept: application/vnd.koreader.v1+json".
// Authenticated requests send x-auth-user and x-auth-key (md5 of the password).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The public KOReader sync server (api.json base_url).
const String kOfficialSyncServer = 'https://sync.koreader.rocks:443/';

const String _accept = 'application/vnd.koreader.v1+json';

class KoSyncException implements Exception {
  KoSyncException(this.message, {this.status});

  final String message;

  /// HTTP status, or null for a network error.
  final int? status;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => status == null ? message : '$message (HTTP $status)';
}

/// A reading position stored on the server.
class RemoteProgress {
  const RemoteProgress({
    required this.document,
    required this.progress,
    required this.percentage,
    required this.device,
    required this.deviceId,
    this.timestamp,
  });

  final String document;

  /// XPointer (reflowable documents) or page number as text.
  final String progress;

  /// 0 to 1.
  final double percentage;
  final String device;
  final String deviceId;

  /// Server time of the update, seconds since the epoch. Older servers do
  /// not send it.
  final int? timestamp;
}

/// Data of one progress update (PUT /syncs/progress).
class ProgressUpdate {
  const ProgressUpdate({
    required this.document,
    required this.progress,
    required this.percentage,
    required this.device,
    required this.deviceId,
    this.metadata,
  });

  final String document;
  final String progress;
  final double percentage;
  final String device;
  final String deviceId;

  /// Optional {filename, title, authors}. The official server ignores it.
  final Map<String, String>? metadata;

  Map<String, Object?> toJson() => {
    'document': document,
    if (metadata != null) 'metadata': metadata,
    'progress': progress,
    'percentage': percentage,
    'device': device,
    'device_id': deviceId,
  };

  static ProgressUpdate fromJson(Map<String, Object?> j) => ProgressUpdate(
    document: j['document'] as String,
    progress: j['progress'] as String,
    percentage: (j['percentage'] as num).toDouble(),
    device: j['device'] as String,
    deviceId: j['device_id'] as String,
    metadata: (j['metadata'] as Map?)?.cast<String, String>(),
  );
}

class _Response {
  _Response(this.status, this.body);

  final int status;
  final Object? body;

  String message(String fallback) {
    final b = body;
    if (b is Map && b['message'] is String) return b['message'] as String;
    return fallback;
  }
}

class KoSyncClient {
  KoSyncClient(String serverUrl, {HttpClient? httpClient})
    : _base = Uri.parse(serverUrl.endsWith('/') ? serverUrl : '$serverUrl/'),
      _http = httpClient ?? HttpClient();

  final Uri _base;
  final HttpClient _http;

  // KOReader uses 2 s / 5 s for progress and 5 s / 10 s for auth (block /
  // total). Phones on mobile data need more, so these are longer.
  static const Duration progressTimeout = Duration(seconds: 10);
  static const Duration authTimeout = Duration(seconds: 15);

  Future<_Response> _send(
    String method,
    String path, {
    Object? body,
    String? user,
    String? key,
    required Duration timeout,
  }) async {
    final uri = _base.resolve(path);
    try {
      _http.connectionTimeout = timeout;
      final req = await _http.openUrl(method, uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, _accept);
      if (user != null && key != null) {
        req.headers.set('x-auth-user', user);
        req.headers.set('x-auth-key', key);
      }
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.add(utf8.encode(jsonEncode(body)));
      }
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      Object? json;
      if (text.isNotEmpty) {
        try {
          json = jsonDecode(text);
        } on FormatException {
          json = null;
        }
      }
      return _Response(res.statusCode, json);
    } on TimeoutException {
      throw KoSyncException('The sync server did not answer in time.');
    } on SocketException catch (e) {
      throw KoSyncException('Cannot reach the sync server: ${e.message}');
    } on HttpException catch (e) {
      throw KoSyncException('Sync server error: ${e.message}');
    } on HandshakeException catch (e) {
      throw KoSyncException('Secure connection to the sync server failed: ${e.message}');
    }
  }

  /// Registers a new user. [userkey] is md5 of the password.
  Future<void> register(String username, String userkey) async {
    final r = await _send(
      'POST',
      'users/create',
      body: {'username': username, 'password': userkey},
      timeout: authTimeout,
    );
    if (r.status != 201) throw KoSyncException(r.message('Registration failed.'), status: r.status);
  }

  /// Checks the user name and key.
  Future<void> authorize(String username, String userkey) async {
    final r = await _send('GET', 'users/auth', user: username, key: userkey, timeout: authTimeout);
    if (r.status != 200) throw KoSyncException(r.message('Login failed.'), status: r.status);
  }

  Future<void> updateProgress(String username, String userkey, ProgressUpdate update) async {
    final r = await _send(
      'PUT',
      'syncs/progress',
      body: update.toJson(),
      user: username,
      key: userkey,
      timeout: progressTimeout,
    );
    if (r.status != 200) throw KoSyncException(r.message('Progress update failed.'), status: r.status);
  }

  /// Returns null when the server has no progress for [document].
  Future<RemoteProgress?> getProgress(String username, String userkey, String document) async {
    final r = await _send(
      'GET',
      'syncs/progress/${Uri.encodeComponent(document)}',
      user: username,
      key: userkey,
      timeout: progressTimeout,
    );
    if (r.status != 200) throw KoSyncException(r.message('Progress request failed.'), status: r.status);
    final b = r.body;
    if (b is! Map || b['percentage'] == null) return null;
    final pct = b['percentage'];
    return RemoteProgress(
      document: (b['document'] ?? document).toString(),
      progress: (b['progress'] ?? '').toString(),
      percentage: pct is num ? pct.toDouble() : double.tryParse(pct.toString()) ?? 0,
      device: (b['device'] ?? '').toString(),
      deviceId: (b['device_id'] ?? '').toString(),
      timestamp: b['timestamp'] is num ? (b['timestamp'] as num).toInt() : null,
    );
  }

  void close() => _http.close(force: true);
}
