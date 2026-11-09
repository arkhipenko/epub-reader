// KOReader document fingerprint ("partial MD5"), as in
// koreader/frontend/util.lua util.partialMD5(). kosync uses it as the
// document key.
//
// The digest covers 1024-byte samples at offsets 0 and 1024 * 4^i for
// i = 0..10. Sampling stops at the first offset at or past the end of the file.
// (In LuaJIT, lshift(1024, -2) wraps to 0, which gives the first offset.)
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const int _step = 1024;
const int _size = 1024;

/// Offsets that the digest samples, in order.
List<int> partialMd5Offsets() => [0, for (var i = 0; i <= 10; i++) _step << (2 * i)];

/// Digest of [bytes] (the whole file content).
String partialMd5OfBytes(Uint8List bytes) {
  final builder = BytesBuilder(copy: false);
  for (final offset in partialMd5Offsets()) {
    if (offset >= bytes.length) break;
    final end = offset + _size > bytes.length ? bytes.length : offset + _size;
    builder.add(Uint8List.sublistView(bytes, offset, end));
  }
  return md5.convert(builder.takeBytes()).toString();
}

/// Digest of the file at [path]. Reads only the sampled parts.
Future<String> partialMd5OfFile(String path) async {
  final raf = await File(path).open();
  try {
    final length = await raf.length();
    final builder = BytesBuilder(copy: false);
    for (final offset in partialMd5Offsets()) {
      if (offset >= length) break;
      await raf.setPosition(offset);
      builder.add(await raf.read(_size));
    }
    return md5.convert(builder.takeBytes()).toString();
  } finally {
    await raf.close();
  }
}

/// Same as [partialMd5OfFile], synchronous (for use in a background isolate).
String partialMd5OfFileSync(String path) {
  final raf = File(path).openSync();
  try {
    final length = raf.lengthSync();
    final builder = BytesBuilder(copy: false);
    for (final offset in partialMd5Offsets()) {
      if (offset >= length) break;
      raf.setPositionSync(offset);
      builder.add(raf.readSync(_size));
    }
    return md5.convert(builder.takeBytes()).toString();
  } finally {
    raf.closeSync();
  }
}
