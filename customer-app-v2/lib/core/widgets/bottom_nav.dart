import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cart/data/cart_repository.dart';
import '../theme/app_typography.dart';
import '../theme/storefront_appearance.dart';
import '../theme/tokens.dart';

/// Floating Apple-style glassmorphic dock for the 5 noun tabs (DESIGN §11.5):
/// Home · Browse · Search · Cart · Orders.
///
/// Sits above the bottom safe-area inset as a pill-shaped translucent bar
/// with a real [BackdropFilter] blur (when [StorefrontAppearance.enableGlassmorphism]
/// is enabled), specular hairline border, and soft layered shadow. Selected
/// items highlight with a stadium pill in [FreshMarketColorTokens.primaryTint].
class EasyGetBottomNav extends ConsumerWidget {
  const EasyGetBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

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
    final appearance = ref.watch(storefrontAppearanceProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.freshColors;
    final isDark = theme.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final blur = appearance.glassBlurIntensity.clamp(8.0, 32.0).toDouble();
    final radius = BorderRadius.circular(AppRadii.pill);

    final fillColor = appearance.enableGlassmorphism
        ? scheme.surfaceContainerLowest.withValues(alpha: isDark ? 0.72 : 0.78)
        : colors.glassSurface;

    Widget bar = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: radius,
        border: Border.all(
          color: colors.glassBorder.withValues(alpha: isDark ? 0.55 : 0.7),
          width: 1,
        ),
      ),
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
    );

    if (appearance.enableGlassmorphism) {
      bar = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: bar,
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: bar,
          ),
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
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? colors.primaryTint.withValues(alpha: 0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
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
      backgroundColor: theme.freshColors.marigold,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
