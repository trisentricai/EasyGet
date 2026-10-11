import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/eta_pill.dart';
import '../../../core/widgets/search_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/states.dart';
import '../../../models/catalog_models.dart';
import '../../../models/storefront_models.dart';
import '../../catalog/presentation/widgets/product_card.dart';
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
          child: EtaPill(minutes: 12),
        ),
        actions: [
          IconButton(
            key: const Key('home-account'),
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Account',
          ),
        ],
        bottom: const AppSearchBar(),
      ),
      body: _Body(
        storefront: storefront,
        categories: categories,
        onRefresh: () => _refresh(ref),
      ),
    );
  }
}

/// Home-tab delivery address row (chevron → address sheet in S13).
class _HomeAddressRow extends StatelessWidget {
  const _HomeAddressRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
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
                    child: Text('Home · Bengaluru',
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (render.ticker != null && render.ticker!.items.isNotEmpty)
              _TickerLine(text: render.ticker!.items.first),
            for (final section in render.sections)
              if (section.type == 'BANNER' || section.type == 'HERO')
                _BannerCarousel(section: section),
            if (categories.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
                child: SectionHeader(
                  title: 'Shop by category',
                  onSeeAll: () => context.go('/browse'),
                ),
              ),
              _CategoryGrid(categories: categories),
            ],
            for (final section in render.sections)
              if (section.type == 'PRODUCT_ROW') _ProductRail(section: section),
            for (final section in render.sections)
              if (section.type == 'RICH_TEXT') _StoryBlock(section: section),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
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

/// Banner carousel: 16:7, edge-to-edge with gutter, dots.
class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({required this.section});

  final StorefrontSection section;

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
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: GestureDetector(
                  onTap: item.link == null
                      ? null
                      : () => context.go(item.link!),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.sunken,
                      borderRadius:
                          BorderRadius.circular(AppRadii.image),
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
                ),
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

/// "Shop by category": 4 columns, first 8 tiles (+ See all in the header).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final tiles = categories.take(8).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpace.md,
        crossAxisSpacing: AppSpace.sm,
        childAspectRatio: 0.8,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) => _CategoryTile(category: tiles[i]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return InkWell(
      key: Key('category-tile-${category.slug}'),
      borderRadius: BorderRadius.circular(AppRadii.image),
      onTap: () => context.go('/browse?category=${category.slug}'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.sunken,
              borderRadius: BorderRadius.circular(AppRadii.image),
            ),
            clipBehavior: Clip.antiAlias,
            child: (category.image ?? '').isEmpty
                ? Icon(Icons.grid_view_outlined,
                    color: colors.faint)
                : CachedNetworkImage(
                    imageUrl: category.image!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.grid_view_outlined,
                      color: colors.faint,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.caption(scheme.onSurface),
          ),
        ],
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
              return ProductCard(
                product: CatalogProduct(
                  id: item.id,
                  name: item.caption ?? '',
                  slug: item.productSlug!,
                  mrp: item.productPrice,
                  basePrice: item.productPrice,
                  primaryImage: item.image,
                ),
                density: ProductDensity.rail,
                width: 148,
                onTap: () => context.push('/product/${item.productSlug}'),
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
