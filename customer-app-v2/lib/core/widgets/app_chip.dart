import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// DESIGN §11.6 — rounded 999, `sunken` rest → `primaryTint` + `primary`
/// selected, 44dp minimum touch height.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        key: const Key('chip'),
        duration: AppMotion.micro,
        curve: AppMotion.curve,
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primaryTint : colors.sunken,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.label(
                selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.tabularSmall(
                  selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}