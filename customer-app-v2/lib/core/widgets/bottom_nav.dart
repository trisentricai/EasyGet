import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/data/cart_repository.dart';
import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// Flat 5-tab bar for the noun routes: Home · Browse · Search · Cart · Orders.
///
/// Zepto's navigation is deliberately utilitarian — solid surface, hairline
/// top divider, compact labels and a pink selected state. There is intentionally
/// **no [BackdropFilter]**: Impeller on the target Android GPU leaks a nested
/// blur across the whole screen. The shell keeps the existing auto-hide motion,
/// so scrolling behaviour is unchanged while the material stays compatible.
class EasyGetBottomNav extends ConsumerWidget {
  const EasyGetBottomNav({
    super.key,
    required this.navigationShell,
    this.visible = true,
  });

  final StatefulNavigationShell navigationShell;
  final bool visible;

  static const _items = [
    (
      label: 'Home',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    (
      label: 'Browse',
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view,
    ),
    (
      label: 'Search',
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
    (
      label: 'Cart',
      icon: Icons.shopping_cart_outlined,
      selectedIcon: Icons.shopping_cart,
    ),
    (
      label: 'Orders',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider).value ?? 0;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.freshColors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final bar = Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavTabItem(
                    label: _items[i].label,
                    icon: _items[i].icon,
                    selectedIcon: _items[i].selectedIcon,
                    selected: navigationShell.currentIndex == i,
                    cartCount: i == 3 ? count : 0,
                    isCart: i == 3,
                    reduceMotion: reduceMotion,
                    onTap: () {
                      unawaited(HapticFeedback.lightImpact());
                      navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1.4),
        duration: reduceMotion ? Duration.zero : AppMotion.base,
        curve: AppMotion.curve,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: reduceMotion ? Duration.zero : AppMotion.micro,
          child: bar,
        ),
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.cartCount,
    required this.isCart,
    required this.reduceMotion,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final int cartCount;
  final bool isCart;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.freshColors;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    final iconWidget = isCart
        ? _CartIcon(count: cartCount, selected: selected)
        : Icon(selected ? selectedIcon : icon, size: 22, color: fg);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : AppMotion.micro,
          curve: AppMotion.curve,
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? colors.primaryTint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label(fg, size: 11).copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = (selected || count > 0)
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final icon = Icon(
      selected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
      size: 22,
      color: color,
    );
    if (count <= 0) return icon;
    return Badge(
      key: const Key('cart-badge'),
      backgroundColor: theme.colorScheme.primary,
      label: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.tabularSmall(Colors.white, size: 10),
      ),
      child: icon,
    );
  }
}
