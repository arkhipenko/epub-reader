import 'package:flutter/material.dart';

/// The undo button at the bottom left of the page. A tap returns to the last
/// saved place. A long press forgets all saved places, with the standard
/// long-press vibration and no message.
///
/// The button has no tooltip: a tooltip opens on a long press, and the long
/// press is used here.
class BackPlaceButton extends StatelessWidget {
  const BackPlaceButton({super.key, required this.onBack, required this.onClear});

  /// Screen-reader label (in place of the tooltip).
  static const String label = 'Back to the previous place. Long press to hide.';

  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: label,
        child: GestureDetector(
          // A long press wins over the button's tap, so the tap does not
          // also go back.
          onLongPress: () {
            Feedback.forLongPress(context);
            onClear();
          },
          child: FloatingActionButton.small(heroTag: null, onPressed: onBack, child: const Icon(Icons.undo)),
        ),
      ),
    );
  }
}
