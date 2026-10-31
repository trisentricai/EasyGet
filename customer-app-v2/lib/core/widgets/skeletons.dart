import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Shimmer-free pulse skeleton (DESIGN §11 global law — token-only motion;
/// no shimmer dependency). Fades between 0.4 and 1.0 opacity.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _opacity =
      Tween<double>(begin: 0.4, end: 1).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadii.image,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    return _Pulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.sunken,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 4, this.itemWidth = 160});

  final int count;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.md,
      runSpacing: AppSpace.lg,
      children: [
        for (var i = 0; i < count; i++)
          SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(height: 120),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(width: 120),
                SizedBox(height: AppSpace.xs),
                SkeletonLine(width: 80, height: 10),
              ],
            ),
          ),
      ],
    );
  }
}

class SkeletonRail extends StatelessWidget {
  const SkeletonRail({super.key, this.count = 4, this.itemWidth = 148});

  final int count;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('skeleton-rail'),
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
        itemBuilder: (_, _) => SizedBox(
          width: itemWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(height: itemWidth),
              const SizedBox(height: AppSpace.sm),
              const SkeletonLine(width: 100),
              const SizedBox(height: AppSpace.xs),
              const SkeletonLine(width: 60, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}