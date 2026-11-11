// Places to go back to after a followed link or a slider jump. The undo
// button and Android back use it. After a few page turns the user has moved
// on, so the places are forgotten and the undo button hides.

class BackStack {
  BackStack({this.forgetAfterTurns = defaultForgetAfterTurns});

  /// Page turns after the last link, jump or back, after which the places
  /// are forgotten.
  static const int defaultForgetAfterTurns = 3;

  final int forgetAfterTurns;
  final List<String> _places = [];
  int _turns = 0;

  bool get isEmpty => _places.isEmpty;
  bool get isNotEmpty => _places.isNotEmpty;

  /// Saves the place (an XPointer) before a link or a jump.
  void push(String xpointer) {
    _places.add(xpointer);
    _turns = 0;
  }

  /// The last saved place, removed. Null when there is none.
  String? pop() {
    if (_places.isEmpty) return null;
    _turns = 0;
    return _places.removeLast();
  }

  /// Counts a page turn. Returns true when this turn forgot the places.
  bool pageTurned() {
    if (_places.isEmpty) return false;
    _turns++;
    if (_turns < forgetAfterTurns) return false;
    _places.clear();
    _turns = 0;
    return true;
  }
}
