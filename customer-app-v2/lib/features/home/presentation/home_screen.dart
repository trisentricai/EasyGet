import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../delivery/presentation/delivery_eta.dart';
import '../../engagement/presentation/notifications_providers.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/states.dart';
import '../../../models/catalog_models.dart';
import '../../../models/storefront_models.dart';
import '../../catalog/presentation/widgets/category_tile.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/quick_add.dart';
import 'home_providers.dart';

/// S4 · Home (`/home`, tab 1): offer ticker → banner carousel → category
/// grid → product rails → story block. Server-driven sections render from a
/// single `GET /storefront/platform/`; the category grid reads `categories()`.
/// Skeleton → populated / empty / error(+retry); pull-to-refresh re-fires all.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(homeStorefrontProvider)
      ..invalidate(homeCategoriesProvider);
    await ref.read(homeStorefrontProvider.future);
    await ref.read(homeCategoriesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storefront = ref.watch(homeStorefrontProvider);
    final categories = ref.watch(homeCategoriesProvider);

    return Scaffold(
      appBar: EasyGetAppBar(
        addressRow: const _HomeAddressRow(),
        etaPill: const KeyedSubtree(
          key: Key('home-eta-pill'),
          child: DeliveryEtaPill(),
        ),
        actions: [
          const _BellAction(),
          IconButton(
            key: const Key('home-account'),
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account',
          ),
        ],
        bottom: AppSearchBar(
          onMic: () => context.go('/search?listen=1'),
        ),
      ),
      body: _Body(
        storefront: storefront,
        categories: categories,
        onRefresh: () => _refresh(ref),
      ),
    );
  }
}

/// Bell with the unread-count badge → notifications inbox.
class _BellAction extends ConsumerWidget {
  const _BellAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread =
        ref.watch(unreadCountProvider).value ?? 0;
    final icon = IconButton(
      key: const Key('home-notifications'),
      onPressed: () => context.push('/notifications'),
      icon: const Icon(Icons.notifications_outlined),
      tooltip: 'Notifications',
    );
    if (unread <= 0) return icon;
    return Badge(
      key: const Key('notif-badge'),
      label: Text(unread > 99 ? '99+' : '$unread'),
      backgroundColor: Theme.of(context).freshColors.marigold,
      child: icon,
    );
  }
}

/// Home-tab delivery address row (chevron → address sheet in S13).
/// Delivery address row: the shopper's own default address (label · city),
/// or a "Set location" prompt when none exists. Taps open /addresses —
/// nothing here is hardcoded.
class _HomeAddressRow extends ConsumerWidget {
  const _HomeAddressRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final address = ref.watch(deliveryAddressProvider).value;
    final line = address == null
        ? 'Set location'
        : '${address.label} · ${address.city}';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: () => context.push('/addresses'),
      child: Row(
        key: const Key('home-address-row'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 20, color: scheme.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Deliver to',
                    style: AppTypography.caption(scheme.onSurfaceVariant)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(scheme.onSurface)),
                    ),
                    Icon(Icons.keyboard_arrow_down,
                        size: 18, color: scheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.storefront,
    required this.categories,
    required this.onRefresh,
  });

  final AsyncValue<StorefrontRender> storefront;
  final AsyncValue<List<Category>> categories;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (storefront.isLoading || categories.isLoading) {
      return const _HomeSkeleton();
    }
    if (storefront.hasError || categories.hasError) {
      return ErrorState(
        body: 'We could not load the store.',
        onRetry: () => onRefresh(),
      );
    }

    final render = storefront.value!;
    final cats = categories.value!;
    if (render.sections.isEmpty && cats.isEmpty) {
      return const EmptyState(
        title: 'Nothing here yet',
        body: 'Check back soon for fresh picks.',
      );
    }

    return _HomeContent(render: render, categories: cats, onRefresh: onRefresh);
  }
}

/// Section-kind inference: the live backend ships sections with an empty
/// `type`, so the renderer reads the CONTENT (product/category slugs,
/// images, titles) instead of trusting the label. Unknown shapes render as
/// a promo strip rather than vanishing.
String sectionKind(StorefrontSection section) {
  final declared = section.type.trim().toUpperCase();
  if (declared == 'HERO' ||
      declared == 'BANNER' ||
      declared == 'PRODUCT_ROW' ||
      declared == 'CATEGORY_GRID' ||
      declared == 'RICH_TEXT' ||
      declared == 'IMAGE_GALLERY') {
    return declared;
  }
  final items = section.items;
  if (items.any((i) => (i.productSlug ?? '').isNotEmpty)) {
    return 'PRODUCT_ROW';
  }
  if (items.any((i) => (i.categorySlug ?? '').isNotEmpty)) {
    return 'CATEGORY_GRID';
  }
  if (items.any((i) => (i.image ?? '').isNotEmpty)) return 'BANNER';
  if ((section.title ?? '').isNotEmpty ||
      (section.subtitle ?? '').isNotEmpty) {
    return 'PROMO';
  }
  if ((section.image ?? '').isNotEmpty) return 'BANNER';
  return 'SKIP';
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.render,
    required this.categories,
    required this.onRefresh,
  });

  final StorefrontRender render;
  final List<Category> categories;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasProductRows =
        render.sections.any((s) => sectionKind(s) == 'PRODUCT_ROW');
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (render.ticker != null && render.ticker!.items.isNotEmpty)
              _TickerLine(text: render.ticker!.items.first),
            for (final entry in render.sections.asMap().entries) ...[
              if (entry.key > 0)
                const SizedBox(height: AppSpace.md),
              _SectionBody(section: entry.value),
            ],
            if (categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
                child: SectionHeader(
                  title: 'Shop by category',
                  onSeeAll: () => context.push('/browse/all'),
                ),
              ),
              _CategoryGrid(categories: categories),
            ],
            // The storefront carries no product rows on this backend: fall
            // back to catalog rails so Home always shows products.
            if (!hasProductRows) ...[
              _FallbackRail(
                title: 'Hot sales',
                provider: hotSalesProvider,
              ),
              _FallbackRail(
                title: 'Top rated',
                provider: topRatedProvider,
              ),
              _FallbackRail(
                title: 'New arrivals',
                provider: newArrivalsProvider,
              ),
            ],
            const _AllProducts(),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
    );
  }
}

/// Dispatches one section to its renderer. CATEGORY_GRID sections defer to
/// the API-driven category track above (never duplicated).
class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.section});

  final StorefrontSection section;

  @override
  Widget build(BuildContext context) {
    switch (sectionKind(section)) {
      case 'HERO':
        return _BannerCarousel(
          key: ValueKey('carousel-${section.id}'),
          section: section,
          hero: true,
        );
      case 'BANNER':
      case 'IMAGE_GALLERY':
        return _BannerCarousel(
          key: ValueKey('carousel-${section.id}'),
          section: section,
        );
      case 'PRODUCT_ROW':
        return _ProductRail(section: section);
      case 'RICH_TEXT':
        return _StoryBlock(section: section);
      case 'PROMO':
        return _PromoStrip(section: section);
      case 'CATEGORY_GRID':
      case 'SKIP':
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Title-led promo strip for typeless sale sections (e.g. DIWALI SALE).
class _PromoStrip extends StatelessWidget {
  const _PromoStrip({required this.section});

  final StorefrontSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    String caption = section.subtitle ?? '';
    if (caption.isEmpty) {
      for (final item in section.items) {
        if ((item.caption ?? '').isNotEmpty) {
          caption = item.caption!;
          break;
        }
      }
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title ?? '',
              style: AppTypography.sectionHeadline(scheme.onSurface)),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(caption,
                style: AppTypography.label(colors.marigold, size: 14)),
          ],
        ],
      ),
    );
  }
}

/// Catalog-driven rail used only when the storefront has no product rows.
/// Loading → skeleton, error/empty → hidden (never an error wall on Home).
class _FallbackRail extends ConsumerWidget {
  const _FallbackRail({required this.title, required this.provider});

  final String title;
  final FutureProvider<CatalogPage> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(provider);
    return page.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
            child: SkeletonRail(count: 4),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.results.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
              child: SectionHeader(title: title),
            ),
            SizedBox(
              height: 336,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                itemCount: rows.results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpace.md),
                itemBuilder: (_, i) {
                  final product = rows.results[i];
                  return ProductCard(
                    product: product,
                    density: ProductDensity.rail,
                    width: 148,
                    onTap: () =>
                        context.push('/product/${product.slug}'),
                    onQuickAdd: () =>
                        quickAddFromCard(context, product),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "All products" (Amazon-style): the whole catalog as a paged 2-col grid
/// with an explicit Show-more footer. Always rendered, rails or not.
class _AllProducts extends ConsumerWidget {
  const _AllProducts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(allProductsProvider);
    final notifier = ref.read(allProductsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget footer() {
      if (state.loadingMore) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (state.hasMore) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              key: const Key('all-products-more'),
              onPressed: notifier.loadMore,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: Theme.of(context).freshColors.faint),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: Text(
                'Show more · ${state.items.length} shown',
                style: AppTypography.label(scheme.primary, size: 14),
              ),
            ),
          ),
        );
      }
      if (state.items.length > AllProductsController.serverPageSize) {
        return Padding(
          padding: const EdgeInsets.only(top: AppSpace.md),
          child: Center(
            child: Text(
              'You have seen all ${state.items.length} products',
              style: AppTypography.caption(scheme.onSurfaceVariant),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final width =
        (MediaQuery.sizeOf(context).width - AppSpace.lg * 2 - AppSpace.md) / 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
          child: SectionHeader(title: 'All products'),
        ),
        if (state.loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SkeletonGrid(count: 4),
          )
        else if (state.error != null)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: OutlinedButton(
              onPressed: notifier.refresh,
              child: const Text('Retry'),
            ),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg),
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpace.md,
              crossAxisSpacing: AppSpace.md,
              childAspectRatio: ProductCard.gridAspect(width),
            ),
            itemCount: state.items.length,
            itemBuilder: (_, i) {
              final product = state.items[i];
              return ProductCard(
                product: product,
                density: ProductDensity.grid,
                width: width,
                onTap: () =>
                    context.push('/product/${product.slug}'),
                onQuickAdd: () =>
                    quickAddFromCard(context, product),
              );
            },
          ),
          footer(),
        ],
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: SkeletonLine(width: 220),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: SkeletonLine(height: 120, radius: AppRadii.image),
          ),
          SizedBox(height: AppSpace.lg),
          SkeletonRail(count: 4),
        ],
      ),
    );
  }
}

/// Offer ticker: a single quiet line (no animation wars).
class _TickerLine extends StatelessWidget {
  const _TickerLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Container(
      key: const Key('home-ticker'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg, vertical: AppSpace.sm),
      child: Row(
        children: [
          Icon(Icons.local_offer_outlined, size: 16, color: colors.marigold),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label(scheme.onSurface, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner carousel: 16:7 with dots. HERO sections render full-bleed
/// (edge-to-edge, square corners); BANNER sections render as gutter cards.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({super.key, required this.section, this.hero = false});

  final StorefrontSection section;
  final bool hero;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).freshColors;
    final items =
        widget.section.items.where((i) => (i.image ?? '').isNotEmpty).toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 7,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final item = items[i];
              final hero = widget.hero;
              final slide = GestureDetector(
                onTap:
                    item.link == null ? null : () => context.go(item.link!),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.sunken,
                    borderRadius: BorderRadius.circular(
                        hero ? 0 : AppRadii.image),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: item.image!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: colors.sunken),
                    errorWidget: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.faint,
                    ),
                  ),
                ),
              );
              if (hero) return slide;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: slide,
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: AppSpace.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  key: Key('carousel-dot-$i'),
                  width: i == _index ? 24 : 8,
                  height: 8,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : colors.faint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Shop by category": a strictly horizontal, non-wrapping track of image
/// tiles (first 8 + See all in the header, which pushes the Browse tab).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final tiles = categories.take(8).toList();
    return SizedBox(
      key: const Key('home-category-track'),
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        itemCount: tiles.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: AppSpace.md),
        itemBuilder: (_, i) => CategoryTile(
          category: tiles[i],
          size: 72,
          onTap: () =>
              context.go('/browse?category=${tiles[i].slug}'),
        ),
      ),
    );
  }
}

/// Product rail: horizontal 148dp cards from section items.
class _ProductRail extends StatelessWidget {
  const _ProductRail({required this.section});

  final StorefrontSection section;

  @override
  Widget build(BuildContext context) {
    final items = section.items
        .where((i) => (i.productSlug ?? '').isNotEmpty)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.sm),
          child: SectionHeader(title: section.title ?? 'For you'),
        ),
        SizedBox(
          height: 336,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpace.md),
              itemBuilder: (_, i) {
                final item = items[i];
                final product = CatalogProduct(
                  id: item.id,
                  name: item.caption ?? '',
                  slug: item.productSlug!,
                  mrp: item.productPrice,
                  basePrice: item.productPrice,
                  primaryImage: item.image,
                );
                return ProductCard(
                  product: product,
                  density: ProductDensity.rail,
                  width: 148,
                  onTap: () =>
                      context.push('/product/${item.productSlug}'),
                  onQuickAdd: () =>
                      quickAddFromCard(context, product),
                );
              },
          ),
        ),
      ],
    );
  }
}

/// Story block: image + Fraunces line + body.
class _StoryBlock extends StatelessWidget {
  const _StoryBlock({required this.section});

  final StorefrontSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((section.image ?? '').isNotEmpty)
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: colors.sunken,
                borderRadius:
                    BorderRadius.circular(AppRadii.image),
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: section.image!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorWidget: (_, _, _) => Icon(
                  Icons.image_not_supported_outlined,
                  color: colors.faint,
                ),
              ),
            ),
          if (section.title != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(section.title!,
                style: AppTypography.sectionHeadline(scheme.onSurface)),
          ],
          if (section.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(section.subtitle!,
                style: AppTypography.body(scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
