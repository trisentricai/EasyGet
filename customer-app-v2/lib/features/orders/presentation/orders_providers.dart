import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order_models.dart';
import '../data/orders_repository.dart';

/// S10 · Orders list. Active/Past split is client-side: anything not
/// delivered/cancelled/refunded counts as active.
final ordersListProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(ordersRepositoryProvider).list(),
);

const _pastStatuses = {'DELIVERED', 'CANCELLED', 'REFUNDED'};

bool isPastOrder(String status) => _pastStatuses.contains(status);

bool isCancellable(String status) =>
    status == 'PENDING' || status == 'CONFIRMED';

List<Order> activeOrders(List<Order> orders) =>
    orders.where((o) => !isPastOrder(o.status)).toList();

List<Order> pastOrders(List<Order> orders) =>
    orders.where((o) => isPastOrder(o.status)).toList();

/// S11 · Order detail state: the full order plus one-shot loading/error.
class OrderDetailState {
  const OrderDetailState({
    this.detail,
    this.loading = true,
    this.error,
  });

  final OrderDetail? detail;
  final bool loading;
  final Object? error;
}

/// Detail controller with a 30s tracking poll: after every fetch it arms a
/// one-shot timer that re-fetches while the status is active, and stops on
/// DELIVERED/CANCELLED/REFUNDED (no socket yet).
class OrderDetailController extends Notifier<OrderDetailState> {
  OrderDetailController(this.id);

  final int id;

  static const pollInterval = Duration(seconds: 30);
  Timer? _timer;

  @override
  OrderDetailState build() {
    ref.onDispose(() => _timer?.cancel());
    _fetch();
    return const OrderDetailState(loading: true);
  }

  Future<void> _fetch() async {
    try {
      final detail = await ref.read(ordersRepositoryProvider).detail(id);
      if (!ref.mounted) return;
      state = OrderDetailState(detail: detail, loading: false);
      _arm(detail.status);
    } catch (e) {
      if (!ref.mounted) return;
      state = OrderDetailState(loading: false, error: e);
    }
  }

  void _arm(String status) {
    _timer?.cancel();
    if (isPastOrder(status)) return;
    _timer = Timer(pollInterval, () {
      if (ref.mounted) _fetch();
    });
  }

  Future<void> refresh() => _fetch();

  Future<void> cancelOrder(String reason) async {
    await ref.read(ordersRepositoryProvider).cancel(id, reason);
    ref.invalidate(ordersListProvider);
    await _fetch();
  }
}

final orderDetailControllerProvider = NotifierProvider.family<
    OrderDetailController, OrderDetailState, int>(
  (id) => OrderDetailController(id),
);