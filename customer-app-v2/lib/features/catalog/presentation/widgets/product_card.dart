import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/catalog_models.dart';
import '../../../wishlist/presentation/card_heart.dart';
import 'price_block.dart';
import 'qty_stepper.dart';
import 'rating_pill.dart';

/// DESIGN §11.2 — one card, three densities, one Add system.
///
/// Rail/grid cards use FIXED internal slots (name 38 + brand line 18 +
/// price 48 + gaps) so every card in a row/rail measures identically no
/// matter how long the product name is — rows can never stagger or overflow.
/// [gridSlotsHeight] is the fixed trailing height; [gridAspect] derives the
/// GridView childAspectRatio for any column width.
enum ProductDensity { rail, grid, line }

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.density = ProductDensity.grid,
    this.width = 180,
    this.quantity = 0,
    this.maxQty = 99,
    this.variantCount = 1,
    this.onChanged,
    this.onTap,
    this.onOpenVariants,
    this.trailing,
    this.onHearted,
  });

  static const double imageAspect = 1.25; // 4:5
  static const double nameSlotHeight = 38;
  static const double brandSlotHeight = 18;
  static const double priceSlotHeight = 64;
  static const double gridSlotsHeight = 180;

  static double gridAspect(double itemWidth) =>
      itemWidth / (itemWidth * imageAspect + gridSlotsHeight);

  final CatalogProduct product;
  final ProductDensity density;
  final double width;
  final int quantity;
  final int maxQty;
  final int variantCount;
  final ValueChanged<int>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onOpenVariants;
  final Widget? trailing;

  /// Fires with the new heart state after a successful card-heart toggle.
  final ValueChanged<bool>? onHearted;

  @override
  Widget build(BuildContext context) {
    final child = switch (density) {
      ProductDensity.rail => _rail(context),
      ProductDensity.grid => _grid(context),
      ProductDensity.line => _line(context),
    };
    return Semantics(
      button: true,
      label: '${product.name}, ₹${_rupees(product.basePrice)}',
      child: child,
    );
  }

  void _handleTap() {
    if (variantCount > 1 && onOpenVariants != null) {
      onOpenVariants!();
    } else {
      onTap?.call();
    }
  }

  Widget _image(BuildContext context, {required double aspect}) {
    final colors = Theme.of(context).freshColors;
    return AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            key: const Key('product-image'),
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(AppRadii.image),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.primaryImage == null
                ? Icon(Icons.image_outlined, color: colors.faint)
                : CachedNetworkImage(
                    imageUrl: product.primaryImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: colors.sunken),
                    errorWidget: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.faint,
                    ),
                  ),
          ),
          if (product.ratingCount > 0)
            Positioned(
              top: AppSpace.sm,
              left: AppSpace.sm,
              child: RatingPill(
                rating: product.ratingAvg,
                count: product.ratingCount,
                compact: true,
              ),
            ),
          // Hearts on browsable cards (rail/grid). Line cards (cart) and
          // slug-less items never show one.
          if (density != ProductDensity.line &&
              product.slug.isNotEmpty)
            Positioned(
              top: AppSpace.sm,
              right: AppSpace.sm,
              child: CardHeart(
                key: Key('card-heart-${product.slug}'),
                slug: product.slug,
                onToggled: onHearted,
              ),
            ),
        ],
      ),
    );
  }

  Widget _addControl() => QtyStepper(
        quantity: quantity,
        maxQty: maxQty,
        compact: true,
        onChanged: onChanged ?? (_) {},
      );

  Widget _grid(BuildContext context) {
    return GestureDetector(
      key: const Key('product-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _image(context, aspect: 4 / 5),
            const SizedBox(height: AppSpace.sm),
            _nameSlot(context),
            _brandSlot(context),
            const SizedBox(height: AppSpace.xs),
            _priceSlot(),
            const SizedBox(height: AppSpace.sm),
            _addControl(),
          ],
        ),
      ),
    );
  }

  Widget _rail(BuildContext context) {
    return GestureDetector(
      key: const Key('product-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _image(context, aspect: 1),
            const SizedBox(height: AppSpace.sm),
            _nameSlot(context),
            _brandSlot(context),
            const SizedBox(height: AppSpace.xs),
            _priceSlot(),
            const SizedBox(height: AppSpace.sm),
            _addControl(),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return GestureDetector(
      key: const Key('product-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            key: const Key('product-image'),
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(AppRadii.image),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.primaryImage == null
                ? Icon(Icons.image_outlined, color: colors.faint)
                : CachedNetworkImage(
                    imageUrl: product.primaryImage!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.faint,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _name(context),
                _subtitle(context, scheme),
                const SizedBox(height: AppSpace.xs),
                PriceBlock(
                    price: product.basePrice, mrp: product.mrp, priceSize: 14),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          trailing ?? _addControl(),
        ],
      ),
    );
  }

  /// Fixed 2-line name slot (38dp): short names leave air, long names clamp —
  /// either way the card below starts at the same offset.
  Widget _nameSlot(BuildContext context) {
    return SizedBox(
      height: nameSlotHeight,
      child: Align(
        alignment: Alignment.topLeft,
        child: _name(context),
      ),
    );
  }

  /// Fixed brand slot (18dp): always reserved so the price block aligns even
  /// when a product has no brand line.
  Widget _brandSlot(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = product.brand;
    if (line == null || line.isEmpty) {
      return const SizedBox(height: brandSlotHeight);
    }
    return SizedBox(
      height: brandSlotHeight,
      child: Text(
        line,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption(scheme.onSurfaceVariant),
      ),
    );
  }

  /// Fixed price slot (48dp): reserves the save line so discounted and
  /// full-price cards measure identically.
  Widget _priceSlot() {
    return SizedBox(
      height: priceSlotHeight,
      child: Align(
        alignment: Alignment.topLeft,
        child: PriceBlock(
          price: product.basePrice,
          mrp: product.mrp,
          discountPercent: product.discountPercent,
        ),
      ),
    );
  }

  Widget _name(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      product.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.productName(scheme.onSurface,
          size: density == ProductDensity.line ? 15 : 14),
    );
  }

  Widget _subtitle(BuildContext context, ColorScheme scheme) {
    final line = product.brand;
    if (line == null || line.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        line,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption(scheme.onSurfaceVariant),
      ),
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);