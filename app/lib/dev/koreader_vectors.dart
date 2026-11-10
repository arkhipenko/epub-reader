// XPointers that KOReader itself produced, with the text KOReader expects
// at them. Source: koreader spec/unit/readerhighlight_spec.lua
// ("highlight for EPUB documents"), file juliet.epub from the KOReader
// test data. If this engine resolves each XPointer to the same text, its
// document model matches KOReader for EPUB.
import '../engine/cre_engine.dart';

class XPointerVector {
  const XPointerVector(this.xpointer, this.maxChars, this.expected, this.source);

  final String xpointer;
  final int maxChars;
  final String expected;
  final String source;
}

const String _p = '/body[1]/DocFragment[5]/body[1]/div[1]/div[1]/div[1]';

const List<XPointerVector> kJulietVectors = [
  // "should highlight word": pos0 .28 to pos1 .31 is 'thy'.
  XPointerVector('$_p/blockquote[19]/p[1]/text()[2].28', 3, 'thy', 'highlight word, pos0'),
  // "should highlight text": 'Montagues.\nSAMPSON' from text()[3].25 to strong text().7.
  XPointerVector('$_p/blockquote[19]/p[1]/text()[3].25', 10, 'Montagues.', 'highlight text, pos0'),
  XPointerVector('$_p/p[19]/strong[1]/text()[1].0', 7, 'SAMPSON', 'highlight text, up to pos1 (.7)'),
  // "should response on tap gesture": 'GREGORY\nHow! turn thy back and run?'.
  XPointerVector('$_p/p[20]/strong[1]/text()[1].0', 7, 'GREGORY', 'tap gesture, pos0'),
  XPointerVector(
    '$_p/blockquote[21]/p[1]/text()[1].0',
    27,
    'How! turn thy back and run?',
    'tap gesture, up to pos1 (.27)',
  ),
];

class VectorResult {
  const VectorResult(this.vector, this.actual);

  final XPointerVector vector;
  final String? actual;

  bool get passed => actual == vector.expected;
}

/// Runs the vectors against the open document (juliet.epub).
Future<List<VectorResult>> runJulietVectors(CreEngine engine) async {
  final results = <VectorResult>[];
  for (final v in kJulietVectors) {
    results.add(VectorResult(v, await engine.textAt(v.xpointer, maxChars: v.maxChars)));
  }
  return results;
}
