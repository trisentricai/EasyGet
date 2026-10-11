import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import '../../models/address_model.dart';

/// DESIGN §11.4 — radio + label chip + two-line address + tabular phone +
/// default badge + delete affordance.
class AddressCard extends StatelessWidget {
  const AddressCard({
    super.key,
    required this.address,
    this.selected = false,
    this.onSelect,
    this.onDelete,
    this.onEdit,
  });

  final Address address;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    return GestureDetector(
      key: Key('address-card-${address.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(
            color: selected ? scheme.primary : colors.faint,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? scheme.primary : colors.faint,
                ),
                const SizedBox(width: AppSpace.sm),
                _labelChip(context, scheme),
                if (address.isDefault) ...[
                  const SizedBox(width: AppSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text('Default',
                        style: AppTypography.label(scheme.primary, size: 11)),
                  ),
                ],
                const Spacer(),
                if (onEdit != null)
                  IconButton(
                    key: ValueKey('address-edit-${address.id}'),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    // Zero padding + explicit 40px box: the row stays
                    // compact AND the radio/chips stay truly centered.
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                    color: scheme.onSurfaceVariant,
                  ),
                if (onDelete != null)
                  IconButton(
                    key: ValueKey('address-delete-${address.id}'),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                    color: scheme.error,
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              address.singleLine,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(scheme.onSurface),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              address.phone,
              style: AppTypography.tabularNumber(scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelChip(BuildContext context, ColorScheme scheme) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).freshColors.sunken,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(address.label,
          style: AppTypography.label(scheme.onSurface, size: 12)),
    );
  }
}