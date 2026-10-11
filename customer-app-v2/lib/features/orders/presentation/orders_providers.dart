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