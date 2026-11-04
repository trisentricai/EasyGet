import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// PriceBlock: tabular price + MRP strike + green savings.
/// Mirrors React PriceBlock component exactly.
class PriceBlock extends StatelessWidget {
  const PriceBlock({
    super.key,
    required this.price,
    this.mrp,
    this.savingsText,
    this.size = PriceSize.md,
    this.stacked = false,
    this.color,
  });

  final int price;
  final int? mrp;
  final String? savingsText;
  final PriceSize size;
  final bool stacked;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = color ?? theme.colorScheme.onSurface;

    TextStyle priceStyle;
    TextStyle mrpStyle;
    switch (size) {
      case PriceSize.sm:
        priceStyle = AppTypography.tabularPrice(ink, size: 13, weight: FontWeight.w700);
        mrpStyle = AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant);
        break;
      case PriceSize.md:
        priceStyle = AppTypography.tabularPrice(ink, size: 16, weight: FontWeight.w700);
        mrpStyle = AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant);
        break;
      case PriceSize.lg:
        priceStyle = AppTypography.tabularPrice(ink, size: 20, weight: FontWeight.w700);
        mrpStyle = AppTypography.tabularPrice(theme.colorScheme.onSurfaceVariant, size: 14);
        break;
    }

    final children = <Widget>[
      Text('₹$price', style: priceStyle),
      if (mrp != null && mrp! > price) ...[
        const SizedBox(width: 8),
        Text('₹$mrp', style: mrpStyle.copyWith(decoration: TextDecoration.lineThrough)),
      ],
    ];

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: children),
          if (savingsText != null) ...[
            const SizedBox(height: 4),
            Text(
              savingsText!,
              style: AppTypography.tabularSmall(theme.freshColors.success),
            ),
          ],
        ],
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        ...children,
        if (savingsText != null)
          Text(
            savingsText!,
            style: AppTypography.tabularSmall(theme.freshColors.success),
          ),
      ],
    );
  }
}

enum PriceSize { sm, md, lg }