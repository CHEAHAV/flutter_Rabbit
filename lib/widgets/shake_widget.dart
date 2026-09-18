import 'dart:math';

import 'package:flutter/material.dart';

/// Wraps [child] and exposes [shake] (via a [GlobalKey]) to trigger a
/// short, decaying horizontal tremble — used to signal a wrong answer.
class ShakeWidget extends StatefulWidget {
  final Widget child;
  const ShakeWidget({super.key, required this.child});

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  /// Replays the tremble from the start — safe to call repeatedly.
  void shake() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 7) * 9 * decay;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
