import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/states.dart';
import '../../cart/presentation/cart_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/checkout_repository.dart';

final _addressesProvider = FutureProvider((ref) {
  return ref.watch(checkoutRepositoryProvider).addresses();
});

final _storesProvider = FutureProvider((ref) {
  return ref.watch(catalogRepositoryProvider).stores();
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  dynamic _addressId;
  int? _storeId;
  final _instructions = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _place(CartSnapshot snap) async {
    final repo = ref.read(checkoutRepositoryProvider);
    final addresses = await ref.read(_addressesProvider.future);
    if (!mounted) return;
    final address = addresses.where((a) => a.id == _addressId).firstOrNull ??
        (addresses.isNotEmpty ? addresses.first : null);
    if (address == null) {
      showSnack(context, 'Add a delivery address first', error: true);
      return;
    }
    final store = _storeId ?? snap.cartStore;
    if (store == null) {
      showSnack(context, 'No store available for this cart', error: true);
      return;
    }
    setState(() => _placing = true);
    try {
      await repo.placeOrder(
        cartId: snap.cartId,
        store: store,
        address: address.toOrderPayload(),
        instructions: _instructions.text,
      );
      await ref.read(cartControllerProvider.notifier).reload();
      if (!mounted) return;
      showSnack(context, 'Order placed 🎉');
      context.go('/orders');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider);
    final addresses = ref.watch(_addressesProvider);
    final stores = ref.watch(_storesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cart.when(
        loading: () => const LoadingList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(cartControllerProvider),
        ),
        data: (c) {
          if (c == null || c.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Nothing to check out',
              text: 'Your cart is empty.',
              actionLabel: 'Browse products',
              onAction: () => context.go('/browse'),
            );
          }
          _addressId ??= addresses.value
              ?.where((a) => a.isDefault)
              .firstOrNull
              ?.id;
          _storeId ??= c.store;
          final storeList = stores.value ?? [];
          _storeId ??= storeList.isNotEmpty
              ? (storeList.first['id'] as num).toInt()
              : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            children: [
              if (c.store == null && storeList.length > 1) ...[
                Text('Store',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _storeId,
                  items: storeList
                      .map((s) => DropdownMenuItem<int>(
                            value: (s['id'] as num).toInt(),
                            child: Text((s['name'] ?? 'Store').toString(),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _storeId = v),
                ),
                const SizedBox(height: 20),
              ],
              Text('Delivery address',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              RadioGroup<dynamic>(
                groupValue: _addressId,
                onChanged: (v) => setState(() => _addressId = v),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...?addresses.value?.map(
                      (a) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: RadioListTile<dynamic>(
                          value: a.id,
                          title: Text(a.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          subtitle: Text(a.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          secondary: a.isDefault
                              ? const Icon(Icons.star_rounded, size: 20)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/addresses'),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('Manage addresses'),
              ),
              const SizedBox(height: 20),
              Text('Instructions (optional)',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(
                controller: _instructions,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ring the bell twice…',
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Items', '${c.totalItems}'),
                      _row('Subtotal', inr(c.subtotal)),
                      _row('Delivery', 'Calculated at confirmation'),
                      const Divider(height: 24),
                      _row('Total today', inr(c.subtotal), bold: true),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: cart.maybeWhen(
        data: (c) {
          if (c == null || c.isEmpty) return const SizedBox.shrink();
          final snap = CartSnapshot(cartId: c.id, cartStore: c.store);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.surface),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _placing ? null : () => _place(snap),
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text('Place order · ${inr(c.subtotal)}'),
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class CartSnapshot {
  CartSnapshot({required this.cartId, required this.cartStore});

  final String cartId;
  final int? cartStore;
}
