import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/data/cart_repository.dart';
import '../theme/tokens.dart';

/// Exactly 5 noun tabs (DESIGN §11.5): Home · Browse · Search · Cart · Orders.
/// Selected = primaryTint indicator pill + brand-ink icon; cart badge reads
/// `cartCountProvider` (marigold, tabular, 99+ cap). Light haptic on switch.
/// The bar itself is frosted translucent chrome over the scrolling body.
class EasyGetBottomNav extends ConsumerWidget {
  const EasyGetBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider).value ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.86),
              border: Border(
                top: BorderSide(color: colors.glassBorder, width: 1),
              ),
            ),
          ),
        ),
        NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: colors.primaryTint,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colors.primaryTint.withValues(alpha: 0.7);
            }
            return null;
          }),
          onDestinationSelected: (index) {
            unawaited(HapticFeedback.lightImpact());
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
