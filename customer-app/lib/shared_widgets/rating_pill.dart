import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// RatingPill: marigold star + tabular rating + review count.
/// Mirrors React RatingPill component exactly.
class RatingPill extends StatelessWidget {
  const RatingPill({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = RatingSize.sm,
    this.onTap,
  });

  final double rating;
  final int? reviewCount;
  final RatingSize size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    final isSmall = size == RatingSize.sm;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 10,
          vertical: isSmall ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: isSmall ? 12 : 14,
              color: colors.marigold,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: AppTypography.tabularNumber(
                theme.colorScheme.onSurface,
                size: isSmall ? 11 : 12,
                weight: FontWeight.w700,
              ),
            ),
            if (reviewCount != null) ...[
              const SizedBox(width: 4),
              Text(
                '($reviewCount)',
                style: AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum RatingSize { sm, md }