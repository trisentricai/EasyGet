import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/data/cart_repository.dart';
import '../theme/tokens.dart';

/// Exactly 5 noun tabs (DESIGN §11.5): Home · Browse · Search · Cart · Orders.
/// Selected = primaryTint indicator pill + brand-ink icon; cart badge reads
/// `cartCountProvider` (marigold, tabular, 99+ cap). Light haptic on switch.
class EasyGetBottomNav extends ConsumerWidget {
  const EasyGetBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider).value ?? 0;
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        HapticFeedback.lightImpact();
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view),
          label: 'Browse',
        ),
        const NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: _CartIcon(count: count),
          label: 'Cart',
        ),
        const NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ],
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Icon(
      Icons.shopping_cart_outlined,
      color: count > 0 ? theme.colorScheme.primary : null,
    );
    if (count <= 0) return icon;
    return Badge(
      key: const Key('cart-badge'),
      backgroundColor: theme.freshColors.marigold,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}