// OPDS HTTP client: feeds, OpenSearch and downloads, with HTTP Basic login.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'opds_feed.dart';

class OpdsException implements Exception {
  OpdsException(this.message, {this.status});

  final String message;
  final int? status;

  bool get needsLogin => status == 401;

  @override
  String toString() => message;
}

class OpdsClient {
  OpdsClient({this.username, this.password, HttpClient? http}) : _http = http ?? HttpClient();

  final String? username;
  final String? password;
  final HttpClient _http;

  static const Duration timeout = Duration(seconds: 20);

  /// HTTP Basic Authorization value, or null without a user name.
  static String? basicAuth(String? username, String? password) {
    final u = username ?? '';
    if (u.isEmpty) return null;
    return 'Basic ${base64Encode(utf8.encode('$u:${password ?? ''}'))}';
  }

  /// Headers for images loaded outside this client (covers, thumbnails).
  static Map<String, String> authHeaders(String? username, String? password) {
    final a = basicAuth(username, password);
    return {'Authorization': ?a};
  }

  String? get authorization => basicAuth(username, password);

  Future<HttpClientResponse> _get(String url, {String accept = '*/*'}) async {
    try {
      _http.connectionTimeout = timeout;
      final req = await _http.getUrl(Uri.parse(url)).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, accept);
      final auth = authorization;
      if (auth != null) req.headers.set(HttpHeaders.authorizationHeader, auth);
      final res = await req.close().timeout(timeout);
      if (res.statusCode == 401) {
        await res.drain<void>();
        throw OpdsException('The catalog needs a user name and password.', status: 401);
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        await res.drain<void>();
        throw OpdsException('The catalog server returned HTTP ${res.statusCode}.', status: res.statusCode);
      }
      return res;
    } on TimeoutException {
      throw OpdsException('The catalog server did not answer in time.');
    } on SocketException catch (e) {
      throw OpdsException('Cannot reach the catalog server: ${e.message}');
    } on HandshakeException catch (e) {
      throw OpdsException('Secure connection to the catalog failed: ${e.message}');
    } on FormatException {
      throw OpdsException('The catalog address is not valid.');
    }
  }

  Future<String> _getText(String url, {String accept = '*/*'}) async {
    final res = await _get(url, accept: accept);
    final bytes = await res.fold<List<int>>(<int>[], (a, b) => a..addAll(b)).timeout(timeout);
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<OpdsFeed> fetchFeed(String url) async {
    final xml = await _getText(url, accept: 'application/atom+xml;profile=opds-catalog, application/atom+xml, */*');
    try {
      return parseOpdsFeed(xml, url);
    } on OpdsParseException catch (e) {
      throw OpdsException(e.message);
    }
  }

  /// The search URL for [terms], from the feed template or its OpenSearch document.
  Future<String?> searchUrl(OpdsFeed feed, String terms) async {
    var template = feed.searchTemplate;
    if (template == null && feed.searchDescriptionHref != null) {
      final osd = await _getText(feed.searchDescriptionHref!,
          accept: 'application/opensearchdescription+xml, */*');
      template = parseOpenSearchTemplate(osd, feed.searchDescriptionHref!);
    }
    if (template == null) return null;
    return template
        .replaceAll('{searchTerms}', Uri.encodeComponent(terms))
        .replaceAll(RegExp(r'\{[^}]*\?\}'), ''); // optional OpenSearch parameters
  }

  /// Downloads [acq] into [folder]. Returns the file path. The name comes
  /// from Content-Disposition, or from [fallbackName] and the format.
  Future<String> download(
    OpdsAcquisition acq,
    String folder,
    String fallbackName, {
    void Function(int received, int? total)? onProgress,
  }) async {
    final res = await _get(acq.href);
    final name = _fileName(res.headers.value('content-disposition'), fallbackName, acq);
    await Directory(folder).create(recursive: true);
    final target = await _unique(File('$folder/$name'));
    final part = File('${target.path}.part');
    final sink = part.openWrite();
    var received = 0;
    final total = res.contentLength >= 0 ? res.contentLength : null;
    try {
      await for (final chunk in res.timeout(timeout)) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.close();
      await part.rename(target.path);
      return target.path;
    } on TimeoutException {
      await sink.close();
      if (await part.exists()) await part.delete();
      throw OpdsException('The download stopped.');
    } catch (_) {
      await sink.close();
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  static String _fileName(String? disposition, String fallback, OpdsAcquisition acq) {
    String? name;
    if (disposition != null) {
      final star = RegExp(r"filename\*\s*=\s*UTF-8''([^;]+)", caseSensitive: false).firstMatch(disposition);
      final plain = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false).firstMatch(disposition);
      if (star != null) {
        name = Uri.decodeComponent(star.group(1)!.trim());
      } else if (plain != null) {
        name = plain.group(1)!.trim();
      }
    }
    name ??= '$fallback${acq.extension}';
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
    if (name.isEmpty) name = 'book${acq.extension}';
    return name;
  }

  /// Adds " (2)", " (3)" ... when the file exists.
  static Future<File> _unique(File f) async {
    if (!await f.exists()) return f;
    final path = f.path;
    final dot = path.toLowerCase().endsWith('.fb2.zip') ? path.length - 8 : path.lastIndexOf('.');
    final stem = dot > path.lastIndexOf('/') ? path.substring(0, dot) : path;
    final ext = dot > path.lastIndexOf('/') ? path.substring(dot) : '';
    for (var i = 2;; i++) {
      final c = File('$stem ($i)$ext');
      if (!await c.exists()) return c;
    }
  }

  void close() => _http.close(force: true);
}
