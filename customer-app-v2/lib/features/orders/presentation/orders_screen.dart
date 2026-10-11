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
                  onPressed: () =>
                      _CancelSheet.show(context, ref, order.id),
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
}

/// Cancel confirm sheet with an editable reason (the API requires one).
class _CancelSheet extends ConsumerStatefulWidget {
  const _CancelSheet({required this.orderId});

  final int orderId;

  static Future<void> show(
      BuildContext context, WidgetRef ref, int orderId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => _CancelSheet(orderId: orderId),
    );
  }

  @override
  ConsumerState<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends ConsumerState<_CancelSheet> {
  late final TextEditingController _reason =
      TextEditingController(text: 'Changed my mind');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(ordersRepositoryProvider)
          .cancel(widget.orderId, _reason.text.trim());
      ref.invalidate(ordersListProvider);
      if (!mounted) return;
      // Snackbar first (the sheet context is still valid), then pop to
      // reveal the refreshed list.
      showAppSnackbar(context, 'Order cancelled.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is ApiException ? e.message : 'Could not cancel.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.faint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Cancel this order?',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.xs),
              Text('This cannot be undone.',
                  style: AppTypography.body(
                      scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 52,
                child: TextField(
                  key: const Key('cancel-reason'),
                  controller: _reason,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style: AppTypography.body(scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Reason',
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.input),
                      borderSide:
                          BorderSide(color: colors.faint),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(_error!,
                    style:
                        AppTypography.caption(scheme.error)),
              ],
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  key: const Key('cancel-confirm'),
                  onPressed: _busy ? null : _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Text('Confirm cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);