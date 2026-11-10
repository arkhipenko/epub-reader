import 'dart:io';

import 'package:epub_reader/sync/partial_md5.dart';
import 'package:flutter_test/flutter_test.dart';

// Expected values are from KOReader spec/unit/util_spec.lua (partialMD5()),
// for the same files from the KOReader test data.
void main() {
  test('offsets match KOReader util.partialMD5()', () {
    expect(partialMd5Offsets().take(4), [0, 1024, 4096, 16384]);
    expect(partialMd5Offsets().last, 1024 << 20);
  });

  test('leaves.epub', () async {
    expect(await partialMd5OfFile('test/fixtures/leaves.epub'), '59d481d168cca6267322f150c5f6a2a3');
  });

  test('tall.pdf', () async {
    expect(await partialMd5OfFile('test/fixtures/tall.pdf'), '41cce710f34e5ec21315e19c99821415');
  });

  test('file and byte versions agree', () async {
    final bytes = await File('test/fixtures/leaves.epub').readAsBytes();
    expect(partialMd5OfBytes(bytes), '59d481d168cca6267322f150c5f6a2a3');
  });
}
