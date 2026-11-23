import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';

/// A physical bottom-sheet shell for the app's existing sheet contents.
///
/// It deliberately owns **only** the chrome: a grab handle, an optional
/// header that joins the drag zone, 1:1 pointer tracking, a velocity-aware
/// dismiss/snap decision and an interruptible spring. The wrapped [child]
/// keeps all of its state, callbacks and scroll behaviour — the sheet body
/// is never a drag zone, so scrollable content keeps its own gestures.
///
/// Adoption is a two-line change for a caller:
///
/// ```dart
/// FluidSheet(
///   header: /* the sheet's existing title row */,
///   child: /* the sheet's existing body */,
/// )
/// ```
///
/// and `enableDrag: false` on the enclosing `showModalBottomSheet` so the
/// Material route does not run a second, competing drag recognizer.
///
/// With `MediaQuery.disableAnimations` on (OS reduce-motion), the sheet does
/// not translate at all and a dismiss ends in an immediate pop.
class FluidSheet extends StatefulWidget {
  const FluidSheet({
    super.key,
    required this.child,
    this.header,
    this.onDismiss,
    this.handleColor,
  });

  /// The existing sheet content. Its business logic is untouched.
  final Widget child;

  /// Optional title row. Rendered inside the drag zone (below the handle)
  /// so the grab target is generous without swallowing scroll gestures.
  final Widget? header;

  /// Called just before the route is popped after a drag dismiss.
  final VoidCallback? onDismiss;

  /// Overrides the handle colour (defaults to the muted token).
  final Color? handleColor;

  @override
  State<FluidSheet> createState() => _FluidSheetState();
}

class _FluidSheetState extends State<FluidSheet> with TickerProviderStateMixin {
  /// A small allowance above/below rest so rubber-band overscroll is not
  /// clipped when the settling spring is created.
  static const double _liftAllowance = 64;

  AnimationController? _spring;
  final List<_Sample> _samples = [];

  double _offset = 0;
  double _startY = 0;
  bool _dragging = false;

  @override
  void dispose() {
    _spring
      ?..stop()
      ..dispose();
    super.dispose();
  }

  void _stopSpring() {
    final spring = _spring;
    if (spring != null && spring.isAnimating) spring.stop();
  }

  void _onPointerDown(PointerEvent event) {
    // A pointer-down is the "grab" moment: give immediate haptic feedback,
    // interrupt any running spring and start sampling for velocity.
    _stopSpring();
    _dragging = true;
    _startY = event.position.dy;
    _samples
      ..clear()
      ..add(_Sample(event.position.dy, event.timeStamp.inMicroseconds));
    unawaited(HapticFeedback.selectionClick());
  }

  void _onPointerMove(PointerEvent event) {
    if (!_dragging) return;
    final height = context.size?.height ?? 600;
    var delta = event.position.dy - _startY;
    if (delta < 0) {
      delta = _rubberband(delta, height);
    } else if (delta > height) {
      delta = height + _rubberband(delta - height, height);
    }

    // Reduce-motion: keep the sheet pinned, but still track the gesture so
    // the release can dismiss immediately.
    if (MediaQuery.disableAnimationsOf(context)) {
      if (_offset != 0) setState(() => _offset = 0);
    } else if (_offset != delta) {
      setState(() => _offset = delta);
    }

    _samples.add(_Sample(event.position.dy, event.timeStamp.inMicroseconds));
  }

  void _onPointerEnd(PointerEvent event) {
    if (!_dragging) return;
    _dragging = false;

    final now = event.timeStamp.inMicroseconds;
    _samples.add(_Sample(event.position.dy, now));
    final window = _velocityWindow(now);
    final first = window.first;
    final last = window.last;
    final elapsed = (last.time - first.time) / 1000000.0;
    final velocity = elapsed > 0 ? (last.y - first.y) / elapsed : 0.0;
    final projected = _offset + _projectedDistance(velocity);
    final height = context.size?.height ?? 600;

    final shouldDismiss =
        projected > 130 ||
        (velocity > 900 && _offset > 20) ||
        _offset > height * 0.5;

    if (shouldDismiss) {
      unawaited(HapticFeedback.lightImpact());
      _settle(target: height, velocity: velocity, dismiss: true);
    } else {
      _settle(target: 0, velocity: velocity, dismiss: false);
    }
  }

  /// Only the last ~120ms of movement counts as "current" velocity; if the
  /// user paused before releasing, fall back to the last two samples so a
  /// long hold does not read as a flick.
  List<_Sample> _velocityWindow(int now) {
    final recent = _samples.where((s) => now - s.time <= 120000).toList();
    if (recent.length >= 2) return recent;
    if (_samples.length >= 2) {
      return _samples.sublist(_samples.length - 2);
    }
    return _samples;
  }

  void _settle({
    required double target,
    required double velocity,
    required bool dismiss,
  }) {
    if (MediaQuery.disableAnimationsOf(context)) {
      if (dismiss) _finishDismiss();
      return;
    }

    _stopSpring();
    _spring?.dispose();
    final height = context.size?.height ?? 600;
    // Bounds cover both the current offset (which may be rubber-banded past
    // either edge) and the target, so animateWith can start without a jump.
    final controller = AnimationController(
      vsync: this,
      lowerBound: (_offset < 0 ? _offset : 0) - _liftAllowance,
      upperBound: (_offset > height ? _offset : height) + _liftAllowance,
      value: _offset,
    );
    final spring = SpringSimulation(
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: 320,
        // Slight bounce on snap-back, critically damped on exit (so the
        // sheet never springs back up past the screen bottom).
        ratio: dismiss ? 1 : 0.86,
      ),
      _offset,
      target,
      velocity,
    );
    controller.addListener(() {
      if (mounted) setState(() => _offset = controller.value);
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && dismiss && mounted) {
        _finishDismiss();
      }
    });
    _spring = controller;
    controller.animateWith(spring);
  }

  void _finishDismiss() {
    widget.onDismiss?.call();
    Navigator.of(context).maybePop();
  }

  /// Apple's exponential projection: `v / 1000 * decay / (1 - decay)`.
  /// With `decay = 0.998` this resolves to ~0.499s of projected travel and
  /// keeps the flick decision tied to a named physical model instead of a
  /// magic `0.5`.
  static double _projectedDistance(double velocity) {
    const decay = 0.998;
    final clamped = velocity.clamp(-2000.0, 2000.0);
    return clamped * (decay / (1 - decay)) / 1000;
  }

  /// Apple-style resistance past the resting point.
  double _rubberband(double overshoot, double dimension) =>
      (overshoot * dimension * 0.55) / (dimension + 0.55 * overshoot.abs());

  Widget _dragZone(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerEnd,
      onPointerCancel: _onPointerEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              height: 28,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.handleColor ?? colors.faint,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
            ),
          ),
          if (widget.header != null) widget.header!,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Transform.translate(
        offset: Offset(0, _offset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dragZone(context),
            // Loose flex: bounded sheets cap the body to the remaining height
            // (so a scrollable body scrolls instead of overflowing), while
            // unbounded hosts still let it size to its content.
            Flexible(child: widget.child),
          ],
        ),
      ),
    );
  }
}

class _Sample {
  const _Sample(this.y, this.time);

  final double y;

  /// Microseconds from [PointerEvent.timeStamp].
  final int time;
}
