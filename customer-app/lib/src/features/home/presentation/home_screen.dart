import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/states.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../data/storefront_repository.dart';

final storefrontProvider = FutureProvider((ref) {
  return ref.watch(storefrontRepositoryProvider).load(AppConfig.storeSlug);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storefront = ref.watch(storefrontProvider);
    final user = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(storefront.value?.name ?? 'EasyGet'),
            Text(
              user == null
                  ? 'Quick commerce near you'
                  : 'Hi, ${user.displayName} 👋',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Account',
            onPressed: () => context.push('/account'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(storefrontProvider.future),
        child: storefront.when(
          loading: () => const LoadingList(),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(storefrontProvider),
          ),
          data: (sf) {
            if (sf.sections.isEmpty) {
              return EmptyState(
                icon: Icons.storefront_outlined,
                title: 'Store coming soon',
                text:
                    'This storefront has no sections yet. Ask the merchant to compose it in the dashboard designer.',
                actionLabel: 'Browse catalog',
                onAction: () => context.go('/browse'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: sf.sections.length,
              itemBuilder: (_, i) => _SectionView(
                section: sf.sections[i],
                accent: storePrimary(theme, sf.theme?.primary),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  const _SectionView({required this.section, required this.accent});

  final StoreSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    switch (section.type) {
      case 'HERO':
        return _HeroBanner(section: section, accent: accent);
      case 'BANNER':
        return _StripBanner(section: section, accent: accent);
      case 'CATEGORY_GRID':
        return _CategoryGrid(section: section);
      case 'PRODUCT_ROW':
        return _ProductRow(section: section);
      case 'IMAGE_GALLERY':
        return _Gallery(section: section);
      case 'RICH_TEXT':
        return _RichText(section: section);
      default:
        return _ProductRow(section: section);
    }
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.section, required this.accent});

  final StoreSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = section.items.isEmpty ? null : section.items.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [accent, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (AppConfig.mediaUrl(first?.image) case final heroUrl?
              when heroUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: heroUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  section.title.isEmpty ? 'Fresh essentials' : section.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (section.subtitle.isNotEmpty)
                  Text(
                    section.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StripBanner extends StatelessWidget {
  const _StripBanner({required this.section, required this.accent});

  final StoreSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_rounded, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (section.subtitle.isNotEmpty)
                  Text(
                    section.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.section});

  final StoreSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: section.title.isEmpty ? 'Shop by category' : section.title),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final item = section.items[i];
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: item.categorySlug == null
                    ? null
                    : () => context.go('/browse?category=${item.categorySlug}'),
                child: Container(
                  width: 88,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.grid_view_rounded,
                            color: theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.section});

  final StoreSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(_sectionProductsProvider(section));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: section.title.isEmpty ? 'Featured' : section.title,
          subtitle: section.subtitle.isEmpty ? null : section.subtitle,
          actionLabel: 'See all',
          onAction: () => context.go('/browse'),
        ),
        SizedBox(
          height: 248,
          child: products.when(
            loading: () => ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const SizedBox(
                width: 160,
                child: Card(child: SizedBox.expand()),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 160,
                  child: ProductCard(
                    product: items[i],
                    onTap: () => context.push('/product/${items[i].slug}'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Resolves a section's linked products (by slug) for the row preview.
final _sectionProductsProvider =
    FutureProvider.family<List<Product>, StoreSection>((ref, section) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final slugs =
      section.items.map((e) => e.productSlug).whereType<String>().take(10);
  final out = <Product>[];
  for (final slug in slugs) {
    try {
      out.add(await repo.product(slug));
    } catch (_) {
      // A removed product must not break the whole row.
    }
  }
  return out;
});

class _Gallery extends StatelessWidget {
  const _Gallery({required this.section});

  final StoreSection section;

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: section.title.isEmpty ? 'Gallery' : section.title),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: section.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final item = section.items[i];
              final url = AppConfig.mediaUrl(item.image);
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 220,
                  child: (url == null || url.isEmpty)
                      ? Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        )
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RichText extends StatelessWidget {
  const _RichText({required this.section});

  final StoreSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (section.title.isEmpty && section.subtitle.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.title.isNotEmpty)
                Text(
                  section.title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              if (section.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(section.subtitle, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
