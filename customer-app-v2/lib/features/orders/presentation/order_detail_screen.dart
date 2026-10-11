import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/order_timeline.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/order_models.dart';
import 'cancel_order_sheet.dart';
import 'orders_providers.dart';

/// S11 · Order detail + Track (`/order/:id`, auth): status hero → vertical
/// timeline (`status_history[]`) → items → bill → Cancel (if allowed).
/// Tracking polls `detail()` every 30s while active and stops on terminal
/// statuses. Reorder is omitted v1 (order items carry no variant id, so
/// re-adding the exact variants is impossible).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailControllerProvider(orderId));

    return Scaffold(
      appBar: EasyGetAppBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'Order #${state.detail?.orderNumber ?? orderId}',
      ),
      body: _Body(orderId: orderId, state: state),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.orderId, required this.state});

  final int orderId;
  final OrderDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              SkeletonLine(height: 120, radius: AppRadii.card),
              SizedBox(height: AppSpace.lg),
              SkeletonLine(),
              SizedBox(height: AppSpace.sm),
              SkeletonLine(width: 200),
            ],
          ),
        ),
      );
    }
    if (state.error != null || state.detail == null) {
      return ErrorState(
        body: 'We could not load this order.',
        onRetry: () => ref
            .read(orderDetailControllerProvider(orderId).notifier)
            .refresh(),
      );
    }

    final detail = state.detail!;
    return RefreshIndicator(
      onRefresh: () => ref
          .read(orderDetailControllerProvider(orderId).notifier)
          .refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(detail: detail),
            if (detail.statusHistory.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
                child: SectionHeader(title: 'Tracking'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
                child: OrderTimeline(events: detail.statusHistory),
              ),
            ],
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
              child: SectionHeader(title: 'Items'),
            ),
            for (final item in detail.items)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.xs, AppSpace.lg, 0),
                child: _ItemRow(item: item),
              ),
            _BillBlock(detail: detail),
            if (detail.cancellationReason != null &&
                detail.cancellationReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
                child: Text(
                  'Cancel reason: ${detail.cancellationReason}',
                  style: AppTypography.caption(Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant),
                ),
              ),
            if (isCancellable(detail.status))
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('order-detail-cancel'),
                    onPressed: () =>
                        _cancel(context, ref, detail.id),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Cancel order'),
                  ),
                ),
              ),
            SizedBox(
                height: AppSpace.xxl +
                    MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, int id) async {
    final reason = await CancelOrderSheet.show(context, id);
    if (reason == null || !context.mounted) return;
    await ref
        .read(orderDetailControllerProvider(orderId).notifier)
        .cancelOrder(reason);
    if (context.mounted) {
      showAppSnackbar(context, 'Order cancelled.');
    }
  }
}

/// Status hero: brand wash, big status icon, pill, tabular id + total.
class _Hero extends StatelessWidget {
  const _Hero({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final icon = switch (detail.status) {
      'DELIVERED' => Icons.check_circle,
      'CANCELLED' || 'REFUNDED' => Icons.cancel,
      'OUT_FOR_DELIVERY' => Icons.delivery_dining,
      _ => Icons.receipt_long,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: scheme.primary),
          const SizedBox(height: AppSpace.sm),
          StatusPill(status: detail.status),
          const SizedBox(height: AppSpace.sm),
          Text(
            detail.orderNumber.isEmpty
                ? 'Order #${detail.id}'
                : detail.orderNumber,
            style: AppTypography.tabularPrice(scheme.onSurface,
                size: 18),
          ),
          const SizedBox(height: 2),
          Text(
            '${detail.itemCount} item${detail.itemCount == 1 ? '' : 's'} · ₹${_rupees(detail.total)}',
            style: AppTypography.body(scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.variantName} × ${item.quantity}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(scheme.onSurface),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Text('₹${_rupees(item.lineTotal)}',
              style: AppTypography.tabularNumber(scheme.onSurface)),
        ],
      ),
    );
  }
}

class _BillBlock extends StatelessWidget {
  const _BillBlock({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.faint),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', '₹${_rupees(detail.subtotal)}',
              scheme.onSurface),
          if (detail.discount > 0) ...[
            const SizedBox(height: AppSpace.xs),
            _row(context, 'Discount', '−₹${_rupees(detail.discount)}',
                colors.success,
                strong: true),
          ],
          const SizedBox(height: AppSpace.xs),
          _row(context, 'Delivery',
              '₹${_rupees(detail.deliveryFee)}', scheme.onSurface),
          const Divider(height: AppSpace.lg),
          _row(context, 'Total', '₹${_rupees(detail.total)}',
              scheme.onSurface,
              strong: true, size: 16),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color,
      {bool strong = false, double size = 14}) {
    final style = strong
        ? AppTypography.tabularPrice(color, size: size)
        : AppTypography.tabularNumber(color, size: size);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.body(
                Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: style),
      ],
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);