import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/order_models.dart';
import '../data/orders_repository.dart';
import 'cancel_order_sheet.dart';
import 'orders_providers.dart';

/// S10 · Orders (`/orders`, tab 5): Active/Past segmented tabs → order cards
/// (tabular id, StatusPill, total) → detail. Cancel (danger ghost + confirm
/// sheet with reason) only on PENDING/CONFIRMED.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: const EasyGetAppBar(title: 'Your orders'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.sm),
            child: Row(
              children: [
                AppChip(
                  label: 'Active',
                  selected: !_showPast,
                  onTap: () => setState(() => _showPast = false),
                ),
                const SizedBox(width: AppSpace.sm),
                AppChip(
                  label: 'Past',
                  selected: _showPast,
                  onTap: () => setState(() => _showPast = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(AppSpace.lg),
                  child: Column(
                    children: [
                      SkeletonLine(),
                      SizedBox(height: AppSpace.sm),
                      SkeletonLine(),
                      SizedBox(height: AppSpace.sm),
                      SkeletonLine(width: 200),
                    ],
                  ),
                ),
              ),
              error: (_, _) => ErrorState(
                body: 'We could not load your orders.',
                onRetry: () =>
                    ref.invalidate(ordersListProvider),
              ),
              data: (rows) {
                final visible =
                    _showPast ? pastOrders(rows) : activeOrders(rows);
                if (visible.isEmpty) {
                  return EmptyState(
                    title: _showPast
                        ? 'No past orders'
                        : 'No active orders',
                    body: _showPast
                        ? 'Delivered and cancelled orders land here.'
                        : 'Your ongoing orders will show up here.',
                    actionLabel: 'Browse products',
                    onAction: () => context.go('/browse'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(ordersListProvider.future).then((_) {}),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg,
                        AppSpace.xs, AppSpace.lg, AppSpace.xxl),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (_, i) =>
                        _OrderCard(order: visible[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return InkWell(
      key: Key('order-card-${order.id}'),
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () => context.go('/order/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: colors.faint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber.isEmpty
                        ? 'Order #${order.id}'
                        : order.orderNumber,
                    style: AppTypography.tabularNumber(
                        scheme.onSurface,
                        size: 15),
                  ),
                ),
                StatusPill(status: order.status, compact: true),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              '${order.itemCount} item${order.itemCount == 1 ? '' : 's'} · ₹${_rupees(order.total)}',
              style: AppTypography.body(scheme.onSurfaceVariant),
            ),
            if (isCancellable(order.status)) ...[
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: Key('order-cancel-${order.id}'),
                  onPressed: () => _confirmCancel(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.error,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancel order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final reason = await CancelOrderSheet.show(context, order.id);
    if (reason == null || !context.mounted) return;
    try {
      await ref.read(ordersRepositoryProvider).cancel(order.id, reason);
      ref.invalidate(ordersListProvider);
      if (context.mounted) {
        showAppSnackbar(context, 'Order cancelled.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackbar(
            context,
            e is ApiException
                ? e.message
                : 'Could not cancel the order.');
      }
    }
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);