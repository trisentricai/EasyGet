import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/states.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if ((cart.value?.items.length ?? 0) > 0)
            TextButton(
              onPressed: () async {
                final err =
                    await ref.read(cartControllerProvider.notifier).clear();
                if (err != null && context.mounted) {
                  showSnack(context, err, error: true);
                }
              },
              child: const Text('Clear'),
            ),
        ],
      ),
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
              title: 'Your cart is empty',
              text: 'Add something fresh — delivery takes minutes.',
              actionLabel: 'Browse products',
              onAction: () => context.go('/browse'),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.read(cartControllerProvider.notifier).reload(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: c.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = c.items[i];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.delete_outline,
                              color: theme.colorScheme.onError),
                        ),
                        onDismissed: (_) => ref
                            .read(cartControllerProvider.notifier)
                            .remove(itemId: item.id),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product?.name ?? item.variant.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.variant.sku} · ${inr(item.variant.price)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme.colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        inr(item.lineTotal),
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity:
                                            VisualDensity.compact,
                                        onPressed: () => ref
                                            .read(cartControllerProvider
                                                .notifier)
                                            .setQuantity(
                                              itemId: item.id,
                                              quantity: item.quantity - 1,
                                            ),
                                        icon: const Icon(
                                            Icons.remove_rounded,
                                            size: 18),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800),
                                      ),
                                      IconButton(
                                        visualDensity:
                                            VisualDensity.compact,
                                        onPressed: () => ref
                                            .read(cartControllerProvider
                                                .notifier)
                                            .setQuantity(
                                              itemId: item.id,
                                              quantity: item.quantity + 1,
                                            ),
                                        icon: const Icon(Icons.add_rounded,
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color:
                            theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${c.totalItems} item${c.totalItems == 1 ? '' : 's'}',
                              style: theme.textTheme.bodyMedium),
                          Text(
                            inr(c.subtotal),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.push('/checkout'),
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
