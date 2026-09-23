import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/states.dart';
import '../../cart/presentation/cart_controller.dart';
import '../data/catalog_repository.dart';

final _productProvider =
    FutureProvider.family<Product, String>((ref, slug) {
  return ref.watch(catalogRepositoryProvider).product(slug);
});

class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _variantIndex = 0;
  int _qty = 1;
  int _page = 0;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = ref.watch(_productProvider(widget.slug));

    return Scaffold(
      body: product.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const LoadingList(),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(_productProvider(widget.slug)),
          ),
        ),
        data: (p) {
          final variants = p.variants.where((v) => v.active).toList();
          final variant = variants.isEmpty
              ? null
              : variants[_variantIndex.clamp(0, variants.length - 1)];
          final images = p.images.isEmpty
              ? [
                  if ((p.primaryImage ?? '').isNotEmpty)
                    ProductImage(
                        url: p.primaryImage!, caption: p.name)
                ]
              : p.images;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                actions: [
                  IconButton(
                    tooltip: 'Cart',
                    onPressed: () => context.go('/cart'),
                    icon: const Icon(Icons.shopping_cart_outlined),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_outlined,
                            size: 72,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) =>
                                  setState(() => _page = i),
                              itemBuilder: (_, i) => CachedNetworkImage(
                                imageUrl: images[i].url,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: theme.colorScheme
                                      .surfaceContainerHighest,
                                ),
                              ),
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width: _page == i ? 22 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _page == i
                                            ? Colors.white
                                            : Colors.white
                                                .withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (p.discountPercent > 0)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '-${p.discountPercent}%',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onError,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.brand.isNotEmpty)
                        Text(
                          p.brand.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        p.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            inr(variant?.price ??
                                p.basePrice ??
                                p.mrp ??
                                '0'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (p.mrp != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              inr(p.mrp),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (variants.length > 1) ...[
                        const SizedBox(height: 20),
                        Text('Pack size',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: List.generate(variants.length, (i) {
                            final v = variants[i];
                            final selected = i ==
                                _variantIndex.clamp(0, variants.length - 1);
                            return ChoiceChip(
                              label: Text(
                                  '${v.name.isEmpty ? v.sku : v.name} · ${inr(v.price)}'),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _variantIndex = i),
                            );
                          }),
                        ),
                      ],
                      if (p.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('About',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(p.description,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: product.maybeWhen(
        data: (p) {
          final variants = p.variants.where((v) => v.active).toList();
          if (variants.isEmpty) return const SizedBox.shrink();
          final theme = Theme.of(context);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _qty > 1
                              ? () => setState(() => _qty -= 1)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$_qty',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: _qty < 99
                              ? () => setState(() => _qty += 1)
                              : null,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _adding
                          ? null
                          : () async {
                              setState(() => _adding = true);
                              final v = variants[_variantIndex
                                  .clamp(0, variants.length - 1)];
                              final err = await ref
                                  .read(cartControllerProvider.notifier)
                                  .add(variantId: v.id, quantity: _qty);
                              if (!context.mounted) return;
                              setState(() => _adding = false);
                              if (err != null) {
                                showSnack(context, err, error: true);
                              } else {
                                showSnack(context,
                                    '${p.name} × $_qty added to cart');
                              }
                            },
                      icon: _adding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart_rounded),
                      label: const Text('Add to cart'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
