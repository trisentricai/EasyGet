import 'package:flutter/material.dart';

import 'tokens.dart';

/// Breakpoint & responsive sizing helpers for phones, foldables, tablets,
/// and landscape viewports.
class AppResponsive {
  const AppResponsive._();

  static const double tabletBreakpoint = 600;
  static const double maxFlowWidth = 760;
  static const double maxDockWidth = 480;

  /// Adaptive grid column count based on available width.
  static int columns(
    double width, {
    double minCardWidth = 165,
    int min = 2,
    int max = 5,
  }) {
    if (width < 280) return 1;
    final raw = (width / minCardWidth).floor();
    return raw.clamp(min, max);
  }

  /// Item width for a grid inside [availableWidth] with [horizontalPadding].
  static double gridItemWidth(
    double availableWidth, {
    required int columns,
    double horizontalPadding = AppSpace.lg,
    double spacing = AppSpace.md,
  }) {
    final usable =
        (availableWidth - horizontalPadding * 2 - spacing * (columns - 1))
            .clamp(120.0, double.infinity);
    return usable / columns;
  }

  /// Horizontal page padding that breathes on tablets/desktop.
  static double pagePadding(double width) =>
      width >= tabletBreakpoint ? AppSpace.xxl : AppSpace.lg;

  /// Effective text scale factor (>= 1.0) for Dynamic Type sizing.
  static double textScale(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final factor = scaler.scale(14) / 14;
    return (factor.isFinite && factor > 1.0) ? factor : 1.0;
  }

  /// Extra bottom scroll clearance for tab screens rendered behind the
  /// flat [EasyGetBottomNav] (`extendBody: true`).
  static double bottomNavClearance(BuildContext context) =>
      88 + MediaQuery.paddingOf(context).bottom;
}

/// Centers single-column flows on wide screens (tablets/landscape) so lines
/// and cards stay at a comfortable reading width.
class ResponsiveConstrained extends StatelessWidget {
  const ResponsiveConstrained({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.maxFlowWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
