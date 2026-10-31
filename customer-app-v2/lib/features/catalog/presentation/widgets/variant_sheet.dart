import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// A selectable buyable variant for [VariantSheet].
class VariantOption {
  const VariantOption({
    required this.id,
    required this.name,
    required this.price,
    this.thumbUrl,
  });

  final int id;
  final String name;
  final double price;
  final String? thumbUrl;
}

/// DESIGN §11.4 — bottom sheet (radius 24 top): 56dp option rows with radio
/// semantics, checked ring on the selection, price delta (tabular) right, and
/// a footer primary CTA with the live price ("Add · ₹240").
class VariantSheet extends StatefulWidget {
  const VariantSheet({
    super.key,
    required this.options,
    this.initialIndex = 0,
    this.onAdd,
  });

  final List<VariantOption> options;
  final int initialIndex;
  final ValueChanged<VariantOption>? onAdd;

  static Future<VariantOption?> show(
    BuildContext context, {
    required List<VariantOption> options,
    int initialIndex = 0,
  }) {
    return showModalBottomSheet<VariantOption>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => VariantSheet(options: options, initialIndex: initialIndex),
    );
  }

  @override
  State<VariantSheet> createState() => _VariantSheetState();
}

class _VariantSheetState extends State<VariantSheet> {
  late int _selected = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final cheapest = widget.options
        .map((o) => o.price)
        .reduce((a, b) => a < b ? a : b);
    final selected = widget.options[_selected];

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpace.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.faint,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
            child: Text('Choose a size',
                style: AppTypography.screenTitle(scheme.onSurface)),
          ),
          for (var i = 0; i < widget.options.length; i++)
            _row(context, i, widget.options[i], cheapest),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: SizedBox(
              height: 54,
              child: FilledButton(
                key: const Key('variant-cta'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onAdd?.call(selected);
                  Navigator.of(context).maybePop(selected);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                ),
                child: Text(
                  'Add · ₹${_rupees(selected.price)}',
                  style: AppTypography.label(scheme.onPrimary, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    int index,
    VariantOption option,
    double cheapest,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final isSelected = index == _selected;
    final delta = option.price - cheapest;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      button: true,
      label: '${option.name}, ₹${_rupees(option.price)}',
      child: InkWell(
        key: Key('variant-option-$index'),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selected = index);
        },
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.sunken,
                    borderRadius: BorderRadius.circular(AppRadii.image),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: option.thumbUrl == null
                      ? Icon(Icons.inventory_2_outlined,
                          size: 20, color: colors.faint)
                      : CachedNetworkImage(
                          imageUrl: option.thumbUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(
                              Icons.image_not_supported_outlined,
                              size: 20,
                              color: colors.faint),
                        ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name,
                          style: AppTypography.bodyMedium(scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text('₹${_rupees(option.price)}',
                          style: AppTypography.tabularNumber(
                              scheme.onSurfaceVariant,
                              size: 12)),
                    ],
                  ),
                ),
                if (delta > 0)
                  Text('+₹${_rupees(delta)}',
                      style: AppTypography.tabularSmall(
                          scheme.onSurfaceVariant, size: 12)),
                const SizedBox(width: AppSpace.sm),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  key: isSelected ? Key('variant-check-$index') : null,
                  color: isSelected ? scheme.primary : colors.faint,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);