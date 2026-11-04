import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/custom_app_bar.dart';
import '../data/orders_repository.dart';
import '../../../models/order.dart';

/// Orders history screen (Tab 5).
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersListProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Orders',
                showSearch: false,
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: colors.primary,
                labelColor: colors.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OrdersList(statusFilter: 'In Transit'),
                  _OrdersList(statusFilter: 'Delivered'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({required this.statusFilter});

  final String statusFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final ordersAsync = ref.watch(ordersListProvider);

    return ordersAsync.when(
      loading: () => Center(child: CircularProgressIndicator(color: colors.primary)),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.danger),
              const SizedBox(height: 16),
              Text('Failed to load orders', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(e.toString(), style: AppTypography.caption(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => ref.invalidate(ordersListProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
      data: (orders) {
        final filtered = orders.where((o) => o.status == statusFilter).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: colors.faint),
                const SizedBox(height: 16),
                Text('No ${statusFilter.toLowerCase()} orders', style: AppTypography.bodyMedium(theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _OrderCard(order: filtered[i]),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    Color statusColor;
    switch (order.status) {
      case 'In Transit':
        statusColor = colors.marigold;
        break;
      case 'Delivered':
        statusColor = colors.success;
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
    }

    return InkWell(
      onTap: () => context.push('/order/${order.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
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
                      Text(
                        order.id,
                        style: AppTypography.tabularNumber(theme.colorScheme.onSurface, size: 14, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.date,
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status,
                    style: AppTypography.label(statusColor, size: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (order.items.isNotEmpty)
              Row(
                children: [
                  ...order.items.take(3).map((item) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(item.product.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )),
                  if (order.items.length > 3)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '+${order.items.length - 3}',
                          style: AppTypography.tabularNumber(colors.primary, size: 12),
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${order.total}',
                  style: AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 16),
                ),
                if (order.status == 'In Transit')
                  FilledButton.tonal(
                    onPressed: () => context.push('/order/${order.id}'),
                    child: const Text('Track'),
                  )
                else if (order.status == 'Delivered')
                  OutlinedButton(
                    onPressed: () => context.push('/order/${order.id}'),
                    child: const Text('Reorder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Orders list provider.
final ordersListProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  return repo.getOrders();
});
