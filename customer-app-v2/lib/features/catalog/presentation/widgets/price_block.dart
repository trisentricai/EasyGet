import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// DESIGN §11.3 — price (Inter 700 tabular ink) + struck MRP (muted) + a real
/// save line (success). Never red, never "SALE".
class PriceBlock extends StatelessWidget {
  const PriceBlock({
    super.key,
    required this.price,
    this.mrp = 0,
    this.discountPercent = 0,
    this.priceSize = 16,
  });

  final double price;
  final double mrp;
  final int discountPercent;
  final double priceSize;

  bool get _hasMrp => mrp > price;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final saved = _hasMrp ? mrp - price : 0.0;
    final percent = _hasMrp && mrp > 0
        ? ((saved / mrp) * 100).round()
        : discountPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${_rupees(price)}',
              style: AppTypography.tabularPrice(scheme.onSurface,
                  size: priceSize),
            ),
            if (_hasMrp) ...[
              const SizedBox(width: AppSpace.sm),
              Text(
                '₹${_rupees(mrp)}',
                style: AppTypography.caption(scheme.onSurfaceVariant)
                    .copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ],
        ),
        if (_hasMrp && saved > 0) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            'Save ₹${_rupees(saved)} · $percent% off',
            style: AppTypography.label(colors.success, size: 12),
          ),
        ],
      ],
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);