import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// DESIGN §11.4 — marigold star + tabular rating + muted `(count)`.
/// Taps open reviews on the PDP; decorative elsewhere (omit [onTap]).
class RatingPill extends StatelessWidget {
  const RatingPill({
    super.key,
    required this.rating,
    this.count = 0,
    this.onTap,
    this.compact = false,
  });

  final double rating;
  final int count;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final body = Container(
      key: const Key('rating-pill'),
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
          Icon(Icons.star_rounded, size: compact ? 14 : 16, color: colors.marigold),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: AppTypography.tabularNumber(scheme.onSurface, size: 12),
          ),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Text(
              '($count)',
              style: AppTypography.tabularSmall(scheme.onSurfaceVariant, size: 11),
            ),
          ],
        ],
      ),
    );

    final pill = onTap == null
        ? body
        : InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: onTap,
            child: body,
          );

    return Semantics(
      label: 'Rated ${rating.toStringAsFixed(1)} out of 5'
          '${count > 0 ? ' from $count reviews' : ''}',
      button: onTap != null,
      child: pill,
    );
  }
}