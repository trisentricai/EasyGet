import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/catalog_models.dart';
import '../../../product/presentation/product_providers.dart';
import '../../../wishlist/presentation/card_heart.dart';
import '../quick_add.dart';
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

class ProductCard extends ConsumerWidget {
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
    this.onQuickAdd,
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

  /// Card Add pipeline (MNC workflow): when set, grid/rail cards show a
  /// single-shot Add pill that runs the pipeline instead of a decorative
  /// stepper. Null keeps the legacy controlled stepper.
  final Future<void> Function()? onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live cart qty for the "✓ N in cart" badge (0 = not added this
    // session). Server truth; the badge is display-only.
    final variantId =
        ref.watch(cardAdditionsProvider)[product.slug];
    final inCartQty = variantId == null
        ? 0
        : (ref.watch(pdpCartControllerProvider).qtyByVariant[variantId] ??
            0);
    final child = switch (density) {
      ProductDensity.rail => _rail(context, inCartQty),
      ProductDensity.grid => _grid(context, inCartQty),
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

  Widget _image(BuildContext context,
      {required double aspect, int inCartQty = 0}) {
    final colors = Theme.of(context).freshColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      child: AspectRatio(
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
            if (product.ratingCount > 0 ||
                product.discountPercent > 0)
              Positioned(
                top: AppSpace.sm,
                left: AppSpace.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.ratingCount > 0)
                      RatingPill(
                        rating: product.ratingAvg,
                        count: product.ratingCount,
                        compact: true,
                      ),
                    if (product.ratingCount > 0 &&
                        product.discountPercent > 0)
                      const SizedBox(width: 6),
                    if (product.discountPercent > 0)
                      _GlassPill(
                        key: Key(
                            'card-discount-${product.slug}'),
                        label: '−${product.discountPercent}%',
                      ),
                  ],
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
            // "✓ N in cart" badge (grid/rail only): the stepper below says
            // the number, the badge says what it MEANS. Zero layout impact
            // (overlay), aligned with the top-left pill row.
            if (density != ProductDensity.line &&
                product.slug.isNotEmpty &&
                inCartQty > 0)
              Positioned(
                left: AppSpace.sm,
                bottom: AppSpace.sm,
                child: _GlassPill(
                  key: Key('card-incart-${product.slug}'),
                  label: '✓ $inCartQty in cart',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _addControl() => QtyStepper(
        quantity: quantity,
        maxQty: maxQty,
        compact: true,
        onChanged: onChanged ?? (_) {},
      );

  /// Single-shot Add pill for the quick-add pipeline (grid/rail only; the
  /// line density keeps its controlled stepper via [trailing]).
  /// Grid cards render it in obsidian (Champagne Minimalist law).
  Widget _quickAddControl({bool obsidian = false}) {
    final quickAdd = onQuickAdd;
    if (quickAdd == null) return _addControl();
    return _CardAddControl(
      product: product,
      obsidian: obsidian,
      onQuickAdd: quickAdd,
    );
  }

  Widget _grid(BuildContext context, int inCartQty) {
    final colors = Theme.of(context).freshColors;
    return GestureDetector(
      key: const Key('product-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: colors.champagne,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: colors.champagneDeep, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _image(context, aspect: 4 / 5, inCartQty: inCartQty),
              const SizedBox(height: AppSpace.md),
              _nameSlot(context),
              _brandSlot(context),
              const SizedBox(height: AppSpace.sm),
              _priceSlot(),
              const SizedBox(height: AppSpace.md),
              _quickAddControl(obsidian: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rail(BuildContext context, int inCartQty) {
    final colors = Theme.of(context).freshColors;
    return GestureDetector(
      key: const Key('product-card'),
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: colors.champagne,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: colors.champagneDeep, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _image(context, aspect: 1, inCartQty: inCartQty),
              const SizedBox(height: AppSpace.md),
              _nameSlot(context),
              _brandSlot(context),
              const SizedBox(height: AppSpace.sm),
              _priceSlot(),
              const SizedBox(height: AppSpace.md),
              _quickAddControl(),
            ],
          ),
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

/// Card add zone: an Add pill until the product's variant is known this
/// session, then an explicit added bar ("✓ N added" + Add-more) bound to the
/// server cart (+ → addItem, − → decrement). The bar says what the state
/// MEANS instead of showing a bare number — same 40dp footprint as the pill,
/// so rows never jump.
class _CardAddControl extends ConsumerWidget {
  const _CardAddControl({
    required this.product,
    required this.obsidian,
    required this.onQuickAdd,
  });

  final CatalogProduct product;
  final bool obsidian;
  final Future<void> Function() onQuickAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variantId =
        ref.watch(cardAdditionsProvider)[product.slug];
    final qty = variantId == null
        ? 0
        : (ref.watch(pdpCartControllerProvider).qtyByVariant[variantId] ??
            0);
    if (variantId != null && qty > 0) {
      return _AddedBar(
        quantity: qty,
        onDecrement: () => ref
            .read(pdpCartControllerProvider.notifier)
            .decrement(variantId),
        onIncrement: () => ref
            .read(pdpCartControllerProvider.notifier)
            .increment(variantId),
      );
    }
    return _QuickAddPill(onAdd: onQuickAdd, obsidian: obsidian);
  }
}

/// Explicit added bar: "−  ✓ N added  +" in one 40dp pill (primaryTint fill).
/// The middle says the state out loud; the + control is the "Add more"
/// affordance (tooltip + semantics). Same footprint as the Add pill, full
/// card-inner width, tabular figures so the width barely moves as N grows.
class _AddedBar extends StatelessWidget {
  const _AddedBar({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Semantics(
      label: '$quantity added in cart',
      explicitChildNodes: true,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: colors.primaryTint,
          borderRadius: BorderRadius.circular(AppRadii.button),
        ),
        child: Row(
          children: [
            IconButton(
              key: const Key('qty-minus'),
              tooltip: 'Remove one',
              onPressed: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
              icon: const Icon(Icons.remove),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              color: scheme.primary,
              constraints:
                  const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
            ),
            Expanded(
              child: Text(
                '✓ $quantity added',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.tabularNumber(scheme.onSurface,
                    size: 14),
              ),
            ),
            IconButton(
              key: const Key('qty-plus'),
              tooltip: 'Add more',
              onPressed: () {
                HapticFeedback.lightImpact();
                onIncrement();
              },
              icon: const Icon(Icons.add),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
              color: scheme.primary,
              constraints:
                  const BoxConstraints.tightFor(width: 40, height: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-shot Add pill (40dp — same footprint as the stepper's Add state
/// so rows never jump). Primary outline, or obsidian fill on champagne
/// cards. Shows a spinner while the pipeline runs.
class _QuickAddPill extends StatefulWidget {
  const _QuickAddPill({required this.onAdd, this.obsidian = false});

  final Future<void> Function() onAdd;
  final bool obsidian;

  @override
  State<_QuickAddPill> createState() => _QuickAddPillState();
}

class _QuickAddPillState extends State<_QuickAddPill> {
  bool _busy = false;

  Future<void> _tap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAdd();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final fill = widget.obsidian ? colors.obsidian : null;
    final ink =
        widget.obsidian ? colors.champagneInk : scheme.primary;
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: _busy ? null : _tap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(72, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          backgroundColor: fill,
          side: BorderSide(
              color: widget.obsidian ? colors.obsidian : scheme.primary),
          foregroundColor: ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          textStyle: AppTypography.label(ink),
        ),
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Add'),
      ),
    );
  }
}

/// Obsidian Glass pill: frosted dark chip for badges over imagery.
class _GlassPill extends StatelessWidget {
  const _GlassPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm, vertical: 3),
          color: colors.obsidianGlass,
          child: Text(
            label,
            style: AppTypography.tabularSmall(colors.champagneInk,
                size: 11),
          ),
        ),
      ),
    );
  }
}