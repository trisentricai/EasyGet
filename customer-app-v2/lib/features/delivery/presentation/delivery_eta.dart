import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../addresses/data/address_repository.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../../models/address_model.dart';

/// Delivery ETA resolved from the shopper's own default address:
/// default (or first) address postal code → `GET /pincode/:code/` → ETA days.
/// Null when there is no address or the lookup fails — callers HIDE the pill
/// instead of showing a hardcoded promise.
class DeliveryEta {
  const DeliveryEta({
    required this.label,
    required this.sublabel,
    required this.freeOver,
  });

  /// Short pill text, e.g. "2 days".
  final String label;

  /// Longer line, e.g. "Delivery to 560001 · Bengaluru".
  final String sublabel;

  final double freeOver;
}

final deliveryAddressProvider = FutureProvider<Address?>((ref) async {
  try {
    final rows = await ref.watch(addressRepositoryProvider).list();
    if (rows.isEmpty) return null;
    for (final address in rows) {
      if (address.isDefault) return address;
    }
    return rows.first;
  } catch (_) {
    return null;
  }
});

final deliveryEtaProvider = FutureProvider<DeliveryEta?>((ref) async {
  final address = await ref.watch(deliveryAddressProvider.future);
  if (address == null || address.postalCode.isEmpty) return null;
  try {
    final info = await ref
        .watch(catalogRepositoryProvider)
        .pincode(address.postalCode);
    if (!info.valid) return null;
    final days = info.etaDays <= 0 ? 1 : info.etaDays;
    return DeliveryEta(
      label: '$days day${days == 1 ? '' : 's'}',
      sublabel:
          'Delivery to ${info.pincode} · ${info.city.isEmpty ? address.city : info.city}',
      freeOver: info.freeDeliveryOver,
    );
  } catch (_) {
    return null;
  }
});

/// Marigold ETA pill fed by [deliveryEtaProvider]. Renders nothing while
/// unknown — a missing promise beats a hardcoded one.
class DeliveryEtaPill extends ConsumerWidget {
  const DeliveryEtaPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eta = ref.watch(deliveryEtaProvider).value;
    if (eta == null) return const SizedBox.shrink();
    final colors = Theme.of(context).freshColors;
    return Container(
      key: const Key('delivery-eta-pill'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: colors.marigoldWash,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              size: 16, color: colors.marigold),
          const SizedBox(width: 4),
          Text(eta.label,
              style: AppTypography.tabularSmall(colors.marigold,
                  size: 12)),
        ],
      ),
    );
  }
}
