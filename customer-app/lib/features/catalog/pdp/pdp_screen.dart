import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/price_block.dart'
    show PriceBlock, PriceSize;
import '../../../shared_widgets/rating_pill.dart';
import '../../../features/catalog/data/catalog_repository.dart';
import '../../../models/product.dart';

/// Product Detail Page (PDP).
class PdpScreen extends ConsumerStatefulWidget {
  const PdpScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PdpScreen> createState() => _PdpScreenState();
}

class _PdpScreenState extends ConsumerState<PdpScreen> {
  int _currentImage = 0;
  bool _wishlisted = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productAsync = ref.watch(_productProvider(widget.slug));

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: productAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => _buildError(e.toString()),
        data: (product) => _buildContent(product),
      ),
    );
  }

  Widget _buildSkeleton() {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          flexibleSpace: Container(color: colors.sunken),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 200, color: colors.sunken),
                const SizedBox(height: 12),
                Container(height: 16, width: 150, color: colors.sunken),
                const SizedBox(height: 8),
                Row(children: [
                  Container(height: 28, width: 80, decoration: BoxDecoration(color: colors.primaryTint, borderRadius: BorderRadius.circular(999))),
                  const SizedBox(width: 8),
                  Container(height: 20, width: 60, color: colors.sunken),
                ]),
                const SizedBox(height: 16),
                Container(height: 28, width: 120, color: colors.sunken),
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Container(height: 16, width: double.infinity, color: colors.sunken),
                const SizedBox(height: 8),
                Container(height: 16, width: 200, color: colors.sunken),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 64, color: colors.faint),
              const SizedBox(height: 16),
              Text('Item Not In Today\'s Harvest', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(message, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Fresh Market Storefront'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Product product) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return CustomScrollView(
      slivers: [
        // Gallery + wishlist + veg badge
        SliverAppBar(
          pinned: true,
          expandedHeight: MediaQuery.of(context).size.width,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  itemCount: product.gallery.isEmpty ? 1 : product.gallery.length,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) {
                    final url = product.gallery.isEmpty ? product.image : product.gallery[i];
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: colors.sunken),
                      errorWidget: (_, __, ___) => Container(
                        color: colors.sunken,
                        child: Icon(Icons.image_not_supported, color: colors.faint, size: 48),
                      ),
                    );
                  },
                ),
                // Veg badge top-left
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: product.isVeg
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('VEG', style: AppTypography.label(Colors.white, size: 11)),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                // Wishlist + share top-right
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: _wishlisted ? Icons.favorite : Icons.favorite_border,
                        color: _wishlisted ? colors.danger : Colors.white,
                        onTap: () => setState(() => _wishlisted = !_wishlisted),
                      ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: Icons.share,
                        color: Colors.white,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                // Page indicator dots
                if (product.gallery.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.gallery.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentImage ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin + shelf life
                if (product.origin.isNotEmpty || product.shelfLife.isNotEmpty)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      if (product.origin.isNotEmpty)
                        _ChipLabel(icon: Icons.location_on_outlined, label: product.origin),
                      if (product.shelfLife.isNotEmpty)
                        _ChipLabel(icon: Icons.schedule_outlined, label: product.shelfLife),
                    ],
                  ),
                const SizedBox(height: 8),
                // Name
                Text(
                  product.name,
                  style: AppTypography.productName(theme.colorScheme.onSurface, size: 20),
                ),
                const SizedBox(height: 8),
                // Variant line + Rating
                Row(
                  children: [
                    if (product.weight.isNotEmpty)
                      Text(
                        product.weight,
                        style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      ),
                    const Spacer(),
                    RatingPill(
                      rating: product.rating,
                      reviewCount: product.reviewCount,
                      size: RatingSize.md,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price block
                PriceBlock(
                  price: product.price,
                  mrp: product.mrp > product.price ? product.mrp : null,
                  savingsText: product.savingsText,
                  size: PriceSize.lg,
                ),
                const SizedBox(height: 16),
                // Variant selector (if multiple)
                if (product.nutrition.isNotEmpty) ...[
                  // This would show pack options in real app
                ],
                // Delivery row
                _DeliveryRow(pincode: '560102', onChange: () {}),
                const SizedBox(height: 24),
                // The Story block
                if (product.story.isNotEmpty) ...[
                  Text('The Story', style: AppTypography.sectionHeadline(theme.colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    product.story,
                    style: AppTypography.body(theme.colorScheme.onSurfaceVariant, size: 15),
                  ),
                  const SizedBox(height: 16),
                ],
                // Nutrition grid
                if (product.nutrition.isNotEmpty) ...[
                  Text('Nutrition (per 100g)', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  _NutritionGrid(nutrition: product.nutrition),
                  const SizedBox(height: 16),
                ],
                // Trust badges
                _TrustBadges(),
                const SizedBox(height: 100), // Space for sticky bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Product provider by slug.
final _productProvider = FutureProvider.family<Product, String>((ref, slug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProduct(slug);
});

/// Circle icon button.
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

/// Chip label for origin/shelf-life.
class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.muted),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant, size: 12)),
        ],
      ),
    );
  }
}

/// Delivery row with ETA pill + pincode.
class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({required this.pincode, required this.onChange});

  final String pincode;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.marigoldWash,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: colors.marigold),
              const SizedBox(width: 6),
              Text(
                '12-Minute Delivery',
                style: AppTypography.tabularNumber(colors.marigold, size: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: onChange,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: colors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Delivering to pincode $pincode',
                      style: AppTypography.caption(theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Change',
                    style: AppTypography.label(colors.marigold, size: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Nutrition grid.
class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.nutrition});

  final List<NutritionItem> nutrition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: nutrition.length,
      itemBuilder: (_, i) {
        final n = nutrition[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(n.label, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(n.value, style: AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 14)),
            ],
          ),
        );
      },
    );
  }
}

/// Trust badges row.
class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustBadge(icon: Icons.verified, label: '100% Traceable', color: colors.primary),
        _TrustBadge(icon: Icons.thermostat, label: 'Quality Checked at 4°C', color: colors.primary),
        _TrustBadge(icon: Icons.eco, label: 'Zero Preservatives', color: colors.primary),
      ],
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.label(color, size: 12)),
        ],
      ),
    );
  }
}