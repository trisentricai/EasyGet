import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// DESIGN §11.6 — Title 17/700 left, ghost "See all →" right. Never centered.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: const Key('section-header'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.productName(scheme.onSurface, size: 17)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            onTap: onSeeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.sm, vertical: AppSpace.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(seeAllLabel,
                      style: AppTypography.label(scheme.primary)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 16, color: scheme.primary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}