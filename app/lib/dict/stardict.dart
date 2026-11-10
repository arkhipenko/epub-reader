// StarDict dictionary reader (the format KOReader uses through sdcv).
//
// Files of one dictionary, same base name:
//   .ifo       text: "StarDict's dict ifo file", then key=value lines
//   .idx       entries: word (UTF-8, NUL-terminated), offset (32 or 64 bit
//              big-endian, per idxoffsetbits), size (32 bit big-endian).
//              May be gzipped (.idx.gz). Sorted by ASCII-case-insensitive
//              compare, then byte compare.
//   .syn       optional: word (NUL-terminated), index into .idx (32 bit BE)
//   .dict      article data, or .dict.dz (dictzip: gzip with an "RA" extra
//              field that lists independently inflatable chunks)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class StarDictInfo {
  const StarDictInfo({required this.ifoPath, required this.name, required this.wordCount, this.sameTypeSequence});

  final String ifoPath;
  final String name;
  final int wordCount;
  final String? sameTypeSequence;

  String get basePath => ifoPath.substring(0, ifoPath.length - 4);

  static StarDictInfo? read(String ifoPath) {
    final List<String> lines;
    try {
      lines = const LineSplitter().convert(utf8.decode(File(ifoPath).readAsBytesSync(), allowMalformed: true));
    } on FileSystemException {
      return null;
    }
    if (lines.isEmpty || !lines.first.startsWith("StarDict's dict ifo file")) return null;
    final kv = <String, String>{};
    for (final l in lines.skip(1)) {
      final i = l.indexOf('=');
      if (i > 0) kv[l.substring(0, i).trim()] = l.substring(i + 1).trim();
    }
    final name = kv['bookname'];
    if (name == null || name.isEmpty) return null; // sdcv also skips these
    return StarDictInfo(
      ifoPath: ifoPath,
      name: name,
      wordCount: int.tryParse(kv['wordcount'] ?? '') ?? 0,
      sameTypeSequence: kv['sametypesequence'],
    );
  }
}

/// One article part: a type letter and its text (or null for binary data).
class ArticlePart {
  const ArticlePart(this.type, this.text);

  final String type;
  final String? text;
}

class DictEntry {
  const DictEntry(this.word, this.parts);

  final String word;
  final List<ArticlePart> parts;

  /// Plain text of the article: markup removed, phonetic in [brackets].
  String get plainText {
    final out = <String>[];
    for (final p in parts) {
      final t = p.text;
      if (t == null) continue;
      switch (p.type) {
        case 't':
          out.add('[$t]');
        case 'h':
        case 'g':
        case 'x':
        case 'k':
          out.add(markupToText(t));
        default:
          out.add(t.trim());
      }
    }
    return out.where((s) => s.isNotEmpty).join('\n');
  }
}

/// Text from HTML, Pango or XDXF markup (enough for a dictionary popup).
String markupToText(String s) => s
    .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'</(p|div|li|tr|h\d)>', caseSensitive: false), '\n')
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&')
    .replaceAll(RegExp(r'[ \t]+\n'), '\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

int _asciiLower(int c) => (c >= 0x41 && c <= 0x5A) ? c + 32 : c;

/// StarDict order: ASCII-case-insensitive compare, then exact compare.
int stardictCompare(String a, String b) {
  final r = asciiCaseCompare(a, b);
  return r != 0 ? r : a.compareTo(b);
}

int asciiCaseCompare(String a, String b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    final d = _asciiLower(a.codeUnitAt(i)) - _asciiLower(b.codeUnitAt(i));
    if (d != 0) return d;
  }
  return a.length - b.length;
}

class StarDict {
  StarDict._(this.info, this._words, this._offsets, this._sizes, this._synWords, this._synIndex, this._data);

  final StarDictInfo info;
  final List<String> _words;
  final List<int> _offsets;
  final List<int> _sizes;
  final List<String> _synWords;
  final List<int> _synIndex;
  final _DictData _data;

  int get length => _words.length;

  /// Loads the index (and synonyms) into memory. Throws [FormatException]
  /// or [FileSystemException] for a broken dictionary.
  static StarDict open(StarDictInfo info) {
    final base = info.basePath;
    final ifo = File(info.ifoPath).readAsStringSync();
    final offsetBits = RegExp(r'^idxoffsetbits=(\d+)', multiLine: true).firstMatch(ifo)?.group(1) == '64' ? 64 : 32;

    Uint8List idx;
    if (File('$base.idx').existsSync()) {
      idx = File('$base.idx').readAsBytesSync();
    } else if (File('$base.idx.gz').existsSync()) {
      idx = Uint8List.fromList(gzip.decode(File('$base.idx.gz').readAsBytesSync()));
    } else {
      throw const FormatException('index file (.idx) not found');
    }
    final words = <String>[];
    final offsets = <int>[];
    final sizes = <int>[];
    final bd = ByteData.sublistView(idx);
    var p = 0;
    while (p < idx.length) {
      final end = idx.indexOf(0, p);
      if (end < 0) break;
      words.add(utf8.decode(Uint8List.sublistView(idx, p, end), allowMalformed: true));
      p = end + 1;
      if (offsetBits == 64) {
        offsets.add(bd.getUint32(p) * 0x100000000 + bd.getUint32(p + 4));
        p += 8;
      } else {
        offsets.add(bd.getUint32(p));
        p += 4;
      }
      sizes.add(bd.getUint32(p));
      p += 4;
    }

    final synWords = <String>[];
    final synIndex = <int>[];
    final syn = File('$base.syn');
    if (syn.existsSync()) {
      final s = syn.readAsBytesSync();
      final sd = ByteData.sublistView(s);
      var q = 0;
      while (q < s.length) {
        final end = s.indexOf(0, q);
        if (end < 0 || end + 5 > s.length) break;
        synWords.add(utf8.decode(Uint8List.sublistView(s, q, end), allowMalformed: true));
        synIndex.add(sd.getUint32(end + 1));
        q = end + 5;
      }
    }

    final _DictData data;
    if (File('$base.dict.dz').existsSync()) {
      data = _DictZipData.open('$base.dict.dz');
    } else if (File('$base.dict').existsSync()) {
      data = _PlainData(File('$base.dict').openSync());
    } else {
      throw const FormatException('article file (.dict or .dict.dz) not found');
    }
    return StarDict._(info, words, offsets, sizes, synWords, synIndex, data);
  }

  /// First index in [list] whose word is not less than [key] (ASCII case
  /// ignored), so that all case variants of [key] follow from there.
  static int _lowerBound(List<String> list, String key) {
    var lo = 0;
    var hi = list.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (asciiCaseCompare(list[mid], key) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Entries for [word]: exact headwords (ASCII case ignored, as sdcv) and
  /// synonyms. Returns an empty list when there is none.
  List<DictEntry> lookup(String word) {
    final found = <int>{};
    for (var i = _lowerBound(_words, word); i < _words.length && asciiCaseCompare(_words[i], word) == 0; i++) {
      found.add(i);
    }
    for (var i = _lowerBound(_synWords, word); i < _synWords.length && asciiCaseCompare(_synWords[i], word) == 0; i++) {
      final target = _synIndex[i];
      if (target < _words.length) found.add(target);
    }
    final ordered = found.toList()..sort();
    return [for (final i in ordered) DictEntry(_words[i], _parse(_data.read(_offsets[i], _sizes[i])))];
  }

  List<ArticlePart> _parse(Uint8List raw) {
    final parts = <ArticlePart>[];
    final seq = info.sameTypeSequence;
    var p = 0;
    String? text(int start, int end) => utf8.decode(Uint8List.sublistView(raw, start, end), allowMalformed: true);
    if (seq != null && seq.isNotEmpty) {
      for (var t = 0; t < seq.length && p <= raw.length; t++) {
        final type = seq[t];
        final last = t == seq.length - 1;
        final isText = type.toLowerCase() == type;
        if (last) {
          parts.add(ArticlePart(type, isText ? text(p, raw.length) : null));
          break;
        }
        if (isText) {
          final end = raw.indexOf(0, p);
          final e = end < 0 ? raw.length : end;
          parts.add(ArticlePart(type, text(p, e)));
          p = e + 1;
        } else {
          final size = ByteData.sublistView(raw).getUint32(p);
          parts.add(ArticlePart(type, null));
          p += 4 + size;
        }
      }
    } else {
      while (p < raw.length) {
        final type = String.fromCharCode(raw[p]);
        p++;
        if (type.toLowerCase() == type) {
          final end = raw.indexOf(0, p);
          final e = end < 0 ? raw.length : end;
          parts.add(ArticlePart(type, text(p, e)));
          p = e + 1;
        } else {
          if (p + 4 > raw.length) break;
          final size = ByteData.sublistView(raw).getUint32(p);
          parts.add(ArticlePart(type, null));
          p += 4 + size;
        }
      }
    }
    return parts;
  }

  void close() => _data.close();
}

abstract class _DictData {
  Uint8List read(int offset, int size);
  void close();
}

class _PlainData implements _DictData {
  _PlainData(this._f);

  final RandomAccessFile _f;

  @override
  Uint8List read(int offset, int size) {
    _f.setPositionSync(offset);
    return _f.readSync(size);
  }

  @override
  void close() => _f.closeSync();
}

/// dictzip: random access to a gzip file through its chunk table.
class _DictZipData implements _DictData {
  _DictZipData._(this._f, this._chunkLen, this._chunkStarts, this._chunkSizes, this._whole);

  final RandomAccessFile? _f;
  final int _chunkLen;
  final List<int> _chunkStarts;
  final List<int> _chunkSizes;

  /// Fallback for a plain gzip file without a chunk table: all of it, inflated.
  final Uint8List? _whole;
  final Map<int, Uint8List> _cache = {};

  static _DictZipData open(String path) {
    final f = File(path).openSync();
    final head = f.readSync(12);
    if (head.length < 10 || head[0] != 0x1f || head[1] != 0x8b) {
      f.closeSync();
      throw const FormatException('.dict.dz is not a gzip file');
    }
    final flags = head[3];
    var pos = 10;
    int? chunkLen;
    final sizes = <int>[];
    if (flags & 0x04 != 0) {
      final xlen = head[10] | (head[11] << 8);
      final extra = f.readSync(xlen);
      pos = 12 + xlen;
      var q = 0;
      while (q + 4 <= extra.length) {
        final si1 = extra[q], si2 = extra[q + 1];
        final len = extra[q + 2] | (extra[q + 3] << 8);
        if (si1 == 0x52 && si2 == 0x41 && len >= 6) {
          // "RA": version, chunk length, chunk count, chunk sizes.
          chunkLen = extra[q + 6] | (extra[q + 7] << 8);
          final count = extra[q + 8] | (extra[q + 9] << 8);
          for (var i = 0; i < count; i++) {
            final o = q + 10 + i * 2;
            sizes.add(extra[o] | (extra[o + 1] << 8));
          }
        }
        q += 4 + len;
      }
    }
    // Skip the optional name, comment and header CRC.
    f.setPositionSync(pos);
    if (flags & 0x08 != 0) pos = _skipZeroTerminated(f, pos);
    if (flags & 0x10 != 0) pos = _skipZeroTerminated(f, pos);
    if (flags & 0x02 != 0) pos += 2;

    if (chunkLen == null || sizes.isEmpty) {
      f.closeSync();
      final whole = Uint8List.fromList(gzip.decode(File(path).readAsBytesSync()));
      return _DictZipData._(null, 0, const [], const [], whole);
    }
    final starts = <int>[];
    var s = pos;
    for (final size in sizes) {
      starts.add(s);
      s += size;
    }
    return _DictZipData._(f, chunkLen, starts, sizes, null);
  }

  static int _skipZeroTerminated(RandomAccessFile f, int pos) {
    f.setPositionSync(pos);
    while (true) {
      final b = f.readByteSync();
      pos++;
      if (b <= 0) return pos;
    }
  }

  Uint8List _chunk(int i) {
    final cached = _cache[i];
    if (cached != null) return cached;
    final f = _f!;
    f.setPositionSync(_chunkStarts[i]);
    final compressed = f.readSync(_chunkSizes[i]);
    // Each chunk ends at a full flush, so it inflates on its own.
    final filter = RawZLibFilter.inflateFilter(raw: true);
    filter.process(compressed, 0, compressed.length);
    final out = BytesBuilder(copy: false);
    while (true) {
      final part = filter.processed(flush: false);
      if (part == null) break;
      out.add(part);
    }
    final bytes = out.takeBytes();
    if (_cache.length > 32) _cache.clear();
    _cache[i] = bytes;
    return bytes;
  }

  @override
  Uint8List read(int offset, int size) {
    final whole = _whole;
    if (whole != null) {
      final end = offset + size > whole.length ? whole.length : offset + size;
      return Uint8List.sublistView(whole, offset, end);
    }
    final out = BytesBuilder(copy: false);
    var remaining = size;
    var pos = offset;
    while (remaining > 0) {
      final i = pos ~/ _chunkLen;
      if (i >= _chunkStarts.length) break;
      final chunk = _chunk(i);
      final inChunk = pos - i * _chunkLen;
      if (inChunk >= chunk.length) break;
      final take = (chunk.length - inChunk) < remaining ? chunk.length - inChunk : remaining;
      out.add(Uint8List.sublistView(chunk, inChunk, inChunk + take));
      remaining -= take;
      pos += take;
    }
    return out.takeBytes();
  }

  @override
  void close() => _f?.closeSync();
}
