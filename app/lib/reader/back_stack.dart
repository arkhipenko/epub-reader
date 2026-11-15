// Places to go back to after a followed link or a slider jump. The undo
// button and Android back use it. Page turns do not change the places: they
// stay until the user goes back, forgets them with a long press on the undo
// button, or closes the book.

class BackStack {
  final List<String> _places = [];

  bool get isEmpty => _places.isEmpty;
  bool get isNotEmpty => _places.isNotEmpty;

  /// Saves the place (an XPointer) before a link or a jump.
  void push(String xpointer) => _places.add(xpointer);

  /// The last saved place, removed. Null when there is none.
  String? pop() => _places.isEmpty ? null : _places.removeLast();

  /// Forgets all saved places.
  void clear() => _places.clear();
}
