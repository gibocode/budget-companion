import 'package:flutter/material.dart';

/// Wraps a tile with a staggered slide-up + fade animation.
/// [delay] postpones the start of the animation for staggered list effects.
class AnimatedSlideTile extends StatefulWidget {
  const AnimatedSlideTile({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.duration = const Duration(milliseconds: 350),
  });

  final Widget child;
  final Duration delay;
  final Curve curve;
  final Duration duration;

  @override
  State<AnimatedSlideTile> createState() => _AnimatedSlideTileState();
}

class _AnimatedSlideTileState extends State<AnimatedSlideTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
