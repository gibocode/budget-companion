import 'package:flutter/material.dart';

/// Detects horizontal swipes and invokes [onSwipeNext] (right→left / swipe left) or [onSwipePrevious] (left→right / swipe right).
class MonthSwipeDetector extends StatelessWidget {
  const MonthSwipeDetector({
    super.key,
    required this.onSwipeNext,
    required this.onSwipePrevious,
    required this.child,
    this.velocityThreshold = 200,
  });

  final VoidCallback onSwipeNext;
  final VoidCallback onSwipePrevious;
  final Widget child;
  final double velocityThreshold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.velocity.pixelsPerSecond.dx;
        // Swipe left (negative velocity) → next month; swipe right (positive) → previous month
        if (v < -velocityThreshold) {
          onSwipeNext();
        } else if (v > velocityThreshold) {
          onSwipePrevious();
        }
      },
      child: child,
    );
  }
}
