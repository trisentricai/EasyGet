import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Pointer-down scale response (Apple HIG / WWDC *Designing Fluid Interfaces*).
///
/// Gives cards and tiles immediate tactile acknowledgement on pointer-down
/// rather than waiting for tap release. Respects OS Reduced Motion
/// (`MediaQuery.disableAnimationsOf`) by skipping the scale transform while
/// keeping [onTap] intact.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final HitTestBehavior behavior;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scale = (!reduceMotion && _pressed) ? widget.pressedScale : 1.0;

    return Listener(
      behavior: widget.behavior,
      onPointerDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: GestureDetector(
        behavior: widget.behavior,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: reduceMotion ? Duration.zero : AppMotion.micro,
          curve: AppMotion.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
