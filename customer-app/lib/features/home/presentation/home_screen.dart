import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/product_card.dart';
import '../../../shared_widgets/custom_app_bar.dart';
import '../../../features/catalog/data/catalog_repository.dart';
import '../../../features/home/data/storefront_repository.dart';
import '../../../models/product.dart';
import '../../../models/category.dart';
import '../../../models/banner.dart';

/// Home storefront screen (Tab 1).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final bannersAsync = ref.watch(bannersProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(storefrontProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(activeCouponsProvider);
          ref.invalidate(categoryListProvider);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App bar with address + ETA + notifications
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                address: 'HSR Layout Sector 4',
                etaMinutes: 12,
                showSearch: true,
                onSearchTap: () => context.push('/search'),
                onAddressTap: () => _showGpsModal(),
                onNotificationTap: () => _showNotifications(),
                notificationCount: 3,
              ),
            ),
            // Offer ticker
            SliverToBoxAdapter(
              child: Container(
                color: colors.brand.withValues(alpha: 0.05),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        size: 16, color: colors.marigold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Today\'s Fresh Code: Use FRESH20 for ₹50 off on farm orders',
                        style:
                            AppTypography.caption(theme.colorScheme.onSurface),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('View',
                          style: AppTypography.label(colors.primary, size: 12)),
                    ),
                  ],
                ),
              ),
            ),
            // Banner carousel
            SliverToBoxAdapter(
              child: _BannerCarousel(bannersAsync: bannersAsync),
            ),
            // Shop by Aisle
            SliverToBoxAdapter(
              child: _CategoryGrid(categoriesAsync: categoriesAsync),
            ),
            // Product rails
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Fresh Picks at Dawn',
                productsAsync: ref.watch(_freshPicksProvider),
                emptyMessage: 'No fresh picks today',
              ),
            ),
            SliverToBoxAdapter(
              child: _ProductRail(
                title: 'Heritage & Cold Pressed',
                productsAsync: ref.watch(_heritageRailProvider),
                emptyMessage: 'No heritage items today',
              ),
            ),
            // Store story block
            SliverToBoxAdapter(
              child: _StoreStoryBlock(),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  void _showGpsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GpsLocationModal(),
    );
  }

  void _showNotifications() {
    // Show notification drawer
  }
}

/// Provider for home storefront data.
final storefrontProvider = FutureProvider((ref) async {
  final repo = ref.watch(storefrontRepositoryProvider);
  return repo.getStorefront();
});

/// Provider for banners.
final bannersProvider = FutureProvider((ref) async {
  final repo = ref.watch(storefrontRepositoryProvider);
  return repo.getBanners();
});

/// Provider for active coupons.
final activeCouponsProvider = FutureProvider((ref) async {
  final repo = ref.watch(storefrontRepositoryProvider);
  return repo.getActiveCoupons();
});

/// Provider for category list.
final categoryListProvider = FutureProvider((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

/// Fresh picks rail provider.
final _freshPicksProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProducts(category: 'produce', sort: 'newest', page: 1);
});

/// Heritage rail provider.
final _heritageRailProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getProducts(category: 'dairy', sort: 'rating', page: 1);
});

/// Banner carousel widget.
class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({required this.bannersAsync});

  final AsyncValue<List<Banner>> bannersAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return bannersAsync.when(
      loading: () => SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 320,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: banners.length,
            itemBuilder: (_, i) {
              final banner = banners[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(banner.image),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Category grid widget.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categoriesAsync});

  final AsyncValue<List<Category>> categoriesAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return categoriesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        final display = categories.take(6).toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Shop by Aisle',
                      style: AppTypography.screenTitle(
                          theme.colorScheme.onSurface)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/browse'),
                    child: Text('See all',
                        style: AppTypography.label(colors.marigold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: display.length,
                itemBuilder: (_, i) {
                  final cat = display[i];
                  return InkWell(
                    onTap: () => context.push('/browse?category=${cat.slug}'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: cat.image != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(cat.image!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: colors.sunken,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: AppTypography.productName(
                                        Colors.white,
                                        size: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${cat.itemCount} items',
                                    style: AppTypography.tabularSmall(
                                        Colors.white.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Product rail widget.
class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.title,
    required this.productsAsync,
    required this.emptyMessage,
  });

  final String title;
  final AsyncValue<List<Product>> productsAsync;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return productsAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 3,
                itemBuilder: (_, __) => Container(
                  width: 148,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: colors.sunken,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title,
                      style: AppTypography.screenTitle(
                          theme.colorScheme.onSurface)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: Text('See all',
                        style: AppTypography.label(colors.marigold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(
                        right: i == products.length - 1 ? 0 : 12),
                    child: ProductCard(
                      product: products[i],
                      variant: ProductVariant.rail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Store story block.
class _StoreStoryBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.primaryTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"We harvest in the pre-dawn mist so your breakfast table tastes like the orchard."',
                    style: AppTypography.displayHero(colors.brand)
                        .copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TrustBadge(
                          icon: Icons.verified, label: '100% Traceable'),
                      _TrustBadge(
                          icon: Icons.thermostat,
                          label: 'Quality Checked at 4°C'),
                      _TrustBadge(icon: Icons.eco, label: 'Zero Preservatives'),
                    ],
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                imageUrl:
                    'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600&auto=format&fit=crop&q=80',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: colors.sunken),
                errorWidget: (_, __, ___) => Container(color: colors.sunken),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

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
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.label(colors.primary, size: 11)),
        ],
      ),
    );
  }
}

/// GPS Location Modal (placeholder).
class _GpsLocationModal extends StatelessWidget {
  const _GpsLocationModal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Set Delivery Location',
                    style:
                        AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: colors.faint),
                  const SizedBox(height: 16),
                  Text('Map picker coming soon',
                      style: AppTypography.body(
                          theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Update location
                    },
                    child: const Text('Confirm Delivery Location'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
