// Places to go back to after a followed link or a slider jump. The undo
// button and Android back use it. Page turns do not change the places: they
// stay until the user goes back, forgets them with a long press on the undo
// button, or closes the book.

/// A place to go back to: the reading position, and whether the view was
/// shifted by lines (it starts at that position) or a fixed page.
class BackPlace {
  const BackPlace(this.xpointer, {this.shifted = false});

  final String xpointer;
  final bool shifted;
}

class BackStack {
  final List<BackPlace> _places = [];

  bool get isEmpty => _places.isEmpty;
  bool get isNotEmpty => _places.isNotEmpty;

  /// Saves the place (an XPointer) before a link or a jump. [shifted]: the
  /// view on screen was a shifted view that starts at the XPointer.
  void push(String xpointer, {bool shifted = false}) => _places.add(BackPlace(xpointer, shifted: shifted));

  /// The last saved place, removed. Null when there is none.
  BackPlace? pop() => _places.isEmpty ? null : _places.removeLast();

  /// Forgets all saved places.
  void clear() => _places.clear();
}
