import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// DESIGN §11.6 — marigold wash pill with a timer icon and tabular minutes.
class EtaPill extends StatelessWidget {
  const EtaPill({super.key, required this.minutes, this.compact = false});

  final int minutes;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    return Container(
      key: const Key('eta-pill'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.sm : AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: colors.marigoldWash,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: compact ? 14 : 16, color: colors.marigold),
          const SizedBox(width: 4),
          Text('$minutes min',
              style: AppTypography.tabularSmall(colors.marigold, size: 12)),
        ],
      ),
    );
  }
}