import 'package:flutter/material.dart';

/// Wraps [child] in an [AnimatedSwitcher] that slides horizontally when the key changes.
/// [slideForward] true = next month (slide in from right), false = previous month (slide in from left).
class MonthSlideTransition extends StatelessWidget {
  const MonthSlideTransition({
    super.key,
    required this.slideForward,
    required this.monthKey,
    required this.child,
  });

  final bool slideForward;
  final Key monthKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final begin = slideForward ? const Offset(1.0, 0) : const Offset(-1.0, 0);
        final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
        );
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: monthKey,
        child: child,
      ),
    );
  }
}
