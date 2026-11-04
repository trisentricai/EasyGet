import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/custom_app_bar.dart';
import '../data/orders_repository.dart';
import '../../../models/order.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  const TrackOrderScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orderAsync = ref.watch(_orderDetailProvider(widget.id));
    final trackingAsync = ref.watch(_orderTrackingProvider(widget.id));

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: orderAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => _buildError(e.toString()),
        data: (order) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Track Order',
                showSearch: false,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusHero(
                      order: order,
                      tracking: trackingAsync,
                    ),
                    const SizedBox(height: 24),
                    if (trackingAsync.whenData((t) => t.driverName != null).value ?? false)
                      trackingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (t) => _RiderCard(tracking: t),
                      ),
                    const SizedBox(height: 24),
                    Text('Delivery Timeline', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    _Timeline(order: order, tracking: trackingAsync),
                    const SizedBox(height: 24),
                    Text('Items & Receipt', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    _ItemsReceipt(order: order),
                    const SizedBox(height: 24),
                    _Actions(order: order),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    return CustomScrollView(
      slivers: [
        SliverAppBar(pinned: true, expandedHeight: 200, flexibleSpace: Container(color: colors.sunken)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(height: 120, color: colors.sunken, margin: const EdgeInsets.only(bottom: 16)),
                Container(height: 100, color: colors.sunken, margin: const EdgeInsets.only(bottom: 16)),
                Container(height: 200, color: colors.sunken),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.danger),
              const SizedBox(height: 16),
              Text('Failed to load order', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(message, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => ref.invalidate(_orderDetailProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

final _orderDetailProvider = FutureProvider.family<Order, String>((ref, id) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getOrder(id);
});

final _orderTrackingProvider = FutureProvider.family<OrderTracking, String>((ref, id) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.trackOrder(id);
});

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.order, required this.tracking});

  final Order order;
  final AsyncValue<OrderTracking> tracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.status, style: AppTypography.displayHero(Colors.white).copyWith(fontSize: 22)),
                    const SizedBox(height: 8),
                    tracking.when(
                      loading: () => Text('Loading ETA...', style: AppTypography.tabularPrice(Colors.white, size: 28)),
                      error: (_, __) => Text('ETA unavailable', style: AppTypography.tabularPrice(Colors.white, size: 28)),
                      data: (t) {
                        final pendingEvents = t.events.where((e) => !e.completed).toList();
                        return Text(
                          pendingEvents.isNotEmpty ? pendingEvents.first.time : 'Delivered',
                          style: AppTypography.tabularPrice(Colors.white, size: 28),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.electric_bike, size: 32, color: Colors.white),
              ),
            ],
          ),
          if (order.driverName != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text('Driver: ${order.driverName}', style: AppTypography.body(Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderCard extends StatelessWidget {
  const _RiderCard({required this.tracking});

  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rider Details', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colors.primaryTint,
                child: Icon(Icons.person, size: 28, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tracking.driverName ?? '', style: AppTypography.productName(theme.colorScheme.onSurface, size: 16)),
                    Text(tracking.driverVehicle ?? '', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.call, color: colors.primary),
                    tooltip: 'Call driver',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline, color: colors.primary),
                    tooltip: 'Chat with driver',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order, required this.tracking});

  final Order order;
  final AsyncValue<OrderTracking> tracking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final events = [
      OrderEvent(status: 'Order Placed', time: order.date, description: 'Confirmed', completed: true, current: false),
      OrderEvent(status: 'Packed with Care', time: 'Est. in 3 mins', description: 'Dark store crew picking', completed: true, current: order.status == 'In Transit'),
      OrderEvent(status: 'Out for Delivery', time: 'Est. in 7 mins', description: 'Rider en route', completed: false, current: order.status == 'In Transit'),
      OrderEvent(status: 'Delivered', time: 'Est. in 12 mins', description: 'Contactless handover', completed: false, current: false),
    ];

    return Column(
      children: events.asMap().entries.map((entry) {
        final i = entry.key;
        final event = entry.value;
        final isLast = i == events.length - 1;
        final isCurrent = event.current;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isCurrent ? colors.primary : (event.completed ? colors.success : theme.colorScheme.outlineVariant),
                    shape: BoxShape.circle,
                    border: Border.all(color: isCurrent ? Colors.white : Colors.transparent, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(event.status, style: AppTypography.bodyMedium(
                          isCurrent ? colors.primary : (event.completed ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant),
                        )),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('LIVE', style: AppTypography.tabularSmall(Colors.white, size: 9)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(event.description, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(event.time, style: AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _ItemsReceipt extends StatelessWidget {
  const _ItemsReceipt({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(item.product.image, width: 56, height: 56, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: AppTypography.productName(theme.colorScheme.onSurface, size: 13)),
                      Text('${item.quantity} × ${item.product.weight}', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Text('₹${item.lineTotal}', style: AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 14)),
              ],
            ),
          )),
          Divider(color: theme.colorScheme.outlineVariant),
          _ReceiptRow('Subtotal', order.subtotal, theme),
          if (order.discount > 0) _ReceiptRow('Discount', -order.discount, theme, color: colors.success),
          _ReceiptRow('Delivery Fee', order.deliveryFee, theme),
          if (order.riderTip > 0) _ReceiptRow('Rider Tip', order.riderTip, theme),
          Divider(color: theme.colorScheme.outlineVariant),
          _ReceiptRow('Total Paid', order.total, theme, isTotal: true),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.amount, this.theme, {this.isTotal = false, this.color});

  final String label;
  final int amount;
  final ThemeData theme;
  final bool isTotal;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? AppTypography.bodyMedium(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700) : AppTypography.body(theme.colorScheme.onSurfaceVariant)),
          Text(amount >= 0 ? '₹$amount' : '-₹${-amount}', style: (isTotal ? AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 16) : AppTypography.tabularPrice(color ?? theme.colorScheme.onSurface, size: 14)).copyWith(fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Row(
      children: [
        if (order.status == 'In Transit')
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Order'),
              style: OutlinedButton.styleFrom(foregroundColor: colors.danger),
            ),
          ),
        if (order.status == 'Delivered') ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.star_outline),
              label: const Text('Rate'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.replay),
              label: const Text('Reorder'),
            ),
          ),
        ],
      ],
    );
  }
}
