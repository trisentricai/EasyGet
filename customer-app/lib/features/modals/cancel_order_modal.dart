import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Structured Cancellation modal.
class CancelOrderModal extends ConsumerStatefulWidget {
  const CancelOrderModal({super.key, required this.orderTotal});

  final int orderTotal;

  @override
  ConsumerState<CancelOrderModal> createState() => _CancelOrderModalState();
}

class _CancelOrderModalState extends ConsumerState<CancelOrderModal> {
  String _selectedReason = 'Placed order by mistake';

  final _reasons = [
    'Placed order by mistake',
    'Delivery time is higher than expected',
    'Want to change delivery address or slot',
    'Found better price elsewhere',
    'Items no longer needed',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Cancel Order', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: colors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('100% Refund Guaranteed', style: AppTypography.bodyMedium(colors.success)),
                        Text(
                          '₹${widget.orderTotal} will be credited back to original source in 5 minutes',
                          style: AppTypography.body(colors.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Reason', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedReason,
            onChanged: (v) => setState(() => _selectedReason = v!),
            child: Column(
              children: [
                ..._reasons.map((r) => RadioListTile<String>(
                  title: Text(r, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  value: r,
                  activeColor: colors.primary,
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Don\'t Cancel (Keep Order)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.danger,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Confirm Cancellation & Refund'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}