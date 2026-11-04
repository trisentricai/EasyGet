import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import 'price_block.dart';
import 'rating_pill.dart';

/// ProductCard — 3 densities, one Add system.
/// Rail (148dp), Grid (2-col 4:5), Line (cart/order 76dp).
/// Mirrors React ProductCard component exactly.
class ProductCard extends ConsumerWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.variant = ProductVariant.grid,
    this.quantity = 0,
    this.onRemove,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider).state;
    final cartItem = cart.items.firstWhere(
      (i) => i.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );
    final currentQty = quantity > 0 ? quantity : cartItem.quantity;

    // Navigate to PDP
    void handleOpenPdp() {
      // Navigate using go_router
    }

    switch (variant) {
      case ProductVariant.line:
        return _LineCard(
          product: product,
          currentQty: currentQty,
          onRemove: onRemove,
          onTap: handleOpenPdp,
          onQuantityChanged: (delta) {
            ref.read(cartProvider.notifier).addToCart(product, delta);
          },
        );
      case ProductVariant.rail:
        return _RailCard(
          product: product,
          currentQty: currentQty,
          onTap: handleOpenPdp,
          onQuantityChanged: (delta) {
            ref.read(cartProvider.notifier).addToCart(product, delta);
          },
        );
      case ProductVariant.grid:
        return _GridCard(
          product: product,
          currentQty: currentQty,
          onTap: handleOpenPdp,
          onQuantityChanged: (delta) {
            ref.read(cartProvider.notifier).addToCart(product, delta);
          },
        );
    }
  }
}

enum ProductVariant { rail, grid, line }

/// Line card for cart/order items (76dp thumb).
class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.product,
    required this.currentQty,
    required this.onRemove,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final Product product;
  final int currentQty;
  final VoidCallback? onRemove;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            // 76dp thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: colors.sunken),
                  errorWidget: (_, __, ___) => Container(
                    color: colors.sunken,
                    child: Icon(Icons.image_not_supported, color: colors.faint),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.productName(theme.colorScheme.onSurface, size: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.weight,
                    style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  PriceBlock(
                    price: product.price,
                    mrp: product.mrp > product.price ? product.mrp : null,
                    savingsText: product.savingsText,
                    size: PriceSize.sm,
                  ),
                ],
              ),
            ),
            // Stepper
            _QtyStepper(
              quantity: currentQty,
              maxQty: product.stockQty,
              onChanged: onQuantityChanged,
              onRemove: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rail card for home rails (148dp wide, 1:1 image).
class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.product,
    required this.currentQty,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final Product product;
  final int currentQty;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 148,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1:1 Image well
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: product.image,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: colors.sunken),
                        errorWidget: (_, __, ___) => Container(
                          color: colors.sunken,
                          child: Icon(Icons.image_not_supported, color: colors.faint),
                        ),
                      ),
                      // Rating pill top-left
                      Positioned(
                        top: 6,
                        left: 6,
                        child: RatingPill(rating: product.rating, size: RatingSize.sm),
                      ),
                      // Wishlist top-right (placeholder)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                          child: Icon(Icons.favorite_border, size: 16, color: theme.colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Veg dot + weight
              Row(
                children: [
                  if (product.isVeg) ...[
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade600),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      product.weight,
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, size: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Name
              Text(
                product.name,
                style: AppTypography.productName(theme.colorScheme.onSurface, size: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Price block
              PriceBlock(
                price: product.price,
                mrp: product.mrp > product.price ? product.mrp : null,
                savingsText: product.savingsText,
                size: PriceSize.sm,
                stacked: true,
              ),
              const SizedBox(height: 8),
              // Add stepper morph
              _AddStepperMorph(
                quantity: currentQty,
                maxQty: product.stockQty,
                onChanged: onQuantityChanged,
                isRail: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid card for browse/search PLP (2-col, 4:5 image).
class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.product,
    required this.currentQty,
    required this.onTap,
    required this.onQuantityChanged,
  });

  final Product product;
  final int currentQty;
  final VoidCallback onTap;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4:5 Image well
            AspectRatio(
              aspectRatio: 4 / 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: colors.sunken),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.sunken,
                        child: Icon(Icons.image_not_supported, color: colors.faint),
                      ),
                    ),
                    // Rating top-left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: RatingPill(
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                        size: RatingSize.sm,
                      ),
                    ),
                    // Wishlist top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
                        child: Icon(
                          Icons.favorite_border,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Veg dot + weight
            Row(
              children: [
                if (product.isVeg) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green.shade600),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    product.weight,
                    style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              product.name,
              style: AppTypography.productName(theme.colorScheme.onSurface, size: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            // Divider + bottom block
            Divider(color: theme.colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 8),
            // Price
            PriceBlock(
              price: product.price,
              mrp: product.mrp > product.price ? product.mrp : null,
              savingsText: product.savingsText,
              size: PriceSize.md,
              stacked: true,
            ),
            const SizedBox(height: 10),
            // Stepper morph
            _AddStepperMorph(
              quantity: currentQty,
              maxQty: product.stockQty,
              onChanged: onQuantityChanged,
              isRail: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// Add stepper morph: "Add" pill → "− qty +" stepper.
class _AddStepperMorph extends StatelessWidget {
  const _AddStepperMorph({
    required this.quantity,
    required this.maxQty,
    required this.onChanged,
    required this.isRail,
  });

  final int quantity;
  final int maxQty;
  final ValueChanged<int> onChanged;
  final bool isRail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    final isSmall = isRail;

    if (quantity == 0) {
      return SizedBox(
        width: double.infinity,
        height: isSmall ? 36 : 40,
        child: OutlinedButton.icon(
          onPressed: () => onChanged(1),
          icon: Icon(Icons.add, size: isSmall ? 16 : 18, color: colors.primary),
          label: Text(
            'ADD',
            style: AppTypography.label(colors.primary, size: isSmall ? 11 : 12),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colors.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      );
    }

    return Container(
      height: isSmall ? 36 : 40,
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(isSmall ? 14 : 16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => onChanged(-1),
            icon: Icon(Icons.remove, size: isSmall ? 16 : 18, color: colors.primary),
            constraints: BoxConstraints(minWidth: isSmall ? 36 : 40, minHeight: isSmall ? 36 : 40),
            padding: EdgeInsets.zero,
          ),
          Text(
            '$quantity',
            style: AppTypography.tabularPrice(colors.brand, size: isSmall ? 13 : 14),
          ),
          IconButton(
            onPressed: quantity >= maxQty ? null : () => onChanged(1),
            icon: Icon(Icons.add, size: isSmall ? 16 : 18, color: colors.primary),
            constraints: BoxConstraints(minWidth: isSmall ? 36 : 40, minHeight: isSmall ? 36 : 40),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// Qty stepper for line cards (cart, orders).
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.quantity,
    required this.maxQty,
    required this.onChanged,
    this.onRemove,
  });

  final int quantity;
  final int maxQty;
  final ValueChanged<int> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: quantity == 1 && onRemove != null
                ? onRemove
                : () => onChanged(-1),
            icon: Icon(Icons.remove, size: 16, color: colors.primary),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Text(
            '$quantity',
            style: AppTypography.tabularPrice(colors.brand, size: 13),
          ),
          IconButton(
            onPressed: quantity >= maxQty ? null : () => onChanged(1),
            icon: Icon(Icons.add, size: 16, color: colors.primary),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}