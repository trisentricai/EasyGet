import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/eta_pill.dart';
import '../../../core/widgets/nav.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/catalog_models.dart';
import '../../../models/review_model.dart';
import '../../cart/data/cart_repository.dart';
import '../../catalog/presentation/widgets/price_block.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/widgets/qty_stepper.dart';
import '../../catalog/presentation/widgets/rating_pill.dart';
import '../../catalog/presentation/widgets/variant_sheet.dart';
import '../../reviews/data/review_repository.dart';
import '../../search/data/search_repository.dart';
import '../../wishlist/presentation/card_heart.dart';
import 'product_providers.dart';

/// S7 · PDP (`/product/:slug`, auth): gallery + heart → name + rating →
/// PriceBlock → variant selector (inline ≤3, else VariantSheet) → delivery
/// row (ETA + quiet pincode check) → sticky PriceBlock + stepper → story →
/// reviews (list + post, 409 → already-reviewed) → related rail.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  int _variantIndex = 0;
  int _galleryIndex = 0;

  bool _showReviewForm = false;
  int _rating = 5;
  bool _posting = false;
  String? _reviewError;
  final _reviewTitle = TextEditingController();
  final _reviewBody = TextEditingController();
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pdpCartControllerProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _reviewTitle.dispose();
    _reviewBody.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.slug;
    ref.listen(productDetailProvider(slug), (_, next) {
      final detail = next.value;
      if (detail == null) return;
      ref.read(recentlyViewedProvider.notifier).viewed(
            CatalogProduct(
              id: detail.id,
              name: detail.name,
              slug: detail.slug,
              brand: detail.brand,
              mrp: detail.mrp,
              basePrice: detail.basePrice,
              discountPercent: detail.discountPercent,
              ratingAvg: detail.ratingAvg,
              ratingCount: detail.ratingCount,
              primaryImage: detail.primaryImage,
            ),
          );
    });

    final detail = ref.watch(productDetailProvider(slug));
    return detail.when(
      loading: () => const Scaffold(body: _PdpSkeleton()),
      error: (e, _) => Scaffold(
        appBar: EasyGetAppBar(
          showBack: true,
          onBack: () => popOrHome(context),
          title: 'Product',
        ),
        body: ErrorState(
          body: 'We could not load this product.',
          onRetry: () => ref.invalidate(productDetailProvider(slug)),
        ),
      ),
      data: _buildDetail,
    );
  }

  Widget _buildDetail(ProductDetail detail) {
    final variants = detail.variants;
    final selected = variants.isEmpty
        ? null
        : variants[_variantIndex.clamp(0, variants.length - 1)];
    final price = selected?.price ?? detail.basePrice;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Gallery(
              detail: detail,
              index: _galleryIndex,
              onPage: (i) => setState(() => _galleryIndex = i),
              onBack: () => popOrHome(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((detail.brand ?? '').isNotEmpty)
                    Text(detail.brand!,
                        style: AppTypography.label(
                            Theme.of(context).colorScheme.primary,
                            size: 12)),
                  const SizedBox(height: 4),
                  Text(detail.name,
                      style: AppTypography.screenTitle(
                          Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (selected != null)
                        Text(selected.name,
                            style: AppTypography.body(
                                Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      if (selected != null) const SizedBox(width: AppSpace.sm),
                      _RatingSummary(
                        rating: detail.ratingAvg,
                        count: detail.ratingCount,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  PriceBlock(
                    price: price,
                    mrp: detail.mrp,
                    discountPercent: detail.discountPercent,
                    priceSize: 18,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _VariantSelector(
                    variants: variants,
                    selectedIndex: selected == null ? 0 : _variantIndex,
                    onSelect: (i) => setState(() => _variantIndex = i),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _DeliveryRow(detail: detail),
                ],
              ),
            ),
            if (detail.description.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
                child: SectionHeader(title: 'The Story'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
                child: Text(detail.description,
                    style: AppTypography.body(Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
              ),
            ],
            _ReviewsBlock(
              slug: widget.slug,
              ratingAvg: detail.ratingAvg,
              ratingCount: detail.ratingCount,
              showForm: _showReviewForm,
              rating: _rating,
              posting: _posting,
              reviewError: _reviewError,
              titleController: _reviewTitle,
              bodyController: _reviewBody,
              onToggleForm: () => setState(() {
                _showReviewForm = !_showReviewForm;
                _reviewError = null;
              }),
              onRating: (r) => setState(() => _rating = r),
              onPost: () => _postReview(widget.slug),
            ),
            _RelatedRail(slug: widget.slug),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
      bottomNavigationBar: _StickyBar(
        // Keyed per variant so a pending selection never leaks across
        // variant switches.
        key: ValueKey('sticky-${selected?.id}'),
        price: price,
        mrp: detail.mrp,
        discountPercent: detail.discountPercent,
        variantId: selected?.id,
      ),
    );
  }

  Future<void> _postReview(String slug) async {
    if (_reviewBody.text.trim().isEmpty) {
      setState(() => _reviewError = 'Tell us a little more.');
      return;
    }
    setState(() {
      _posting = true;
      _reviewError = null;
    });
    try {
      await ref.read(reviewRepositoryProvider).create(
            slug,
            rating: _rating,
            title: _reviewTitle.text.trim(),
            body: _reviewBody.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _posting = false;
        _showReviewForm = false;
        _reviewTitle.clear();
        _reviewBody.clear();
        _rating = 5;
      });
      ref.invalidate(productReviewsProvider(slug));
      showAppSnackbar(context, 'Thanks — your review is posted.');
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : '$e';
      setState(() {
        _posting = false;
        _reviewError = message.toLowerCase().contains('already')
            ? 'You have already reviewed this product.'
            : message;
      });
    }
  }
}

class _PdpSkeleton extends StatelessWidget {
  const _PdpSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SkeletonLine(height: 320, radius: 0),
          Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 200),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(width: 140, height: 10),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1:1 gallery with dots, back chevron and wishlist heart overlaid.
class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.detail,
    required this.index,
    required this.onPage,
    required this.onBack,
  });

  final ProductDetail detail;
  final int index;
  final ValueChanged<int> onPage;
  final VoidCallback onBack;

  List<String> get _urls {
    if (detail.images.isNotEmpty) {
      return detail.images.map((i) => i.url).toList();
    }
    if ((detail.primaryImage ?? '').isNotEmpty) return [detail.primaryImage!];
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final urls = _urls;

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: colors.sunken,
            child: urls.isEmpty
                ? Icon(Icons.image_outlined, size: 64, color: colors.faint)
                : PageView.builder(
                    itemCount: urls.length,
                    onPageChanged: onPage,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      key: const Key('pdp-image'),
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        Icons.image_not_supported_outlined,
                        size: 64,
                        color: colors.faint,
                      ),
                    ),
                  ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: AppSpace.sm,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < urls.length; i++)
                    Container(
                      key: Key('pdp-dot-$i'),
                      width: i == index ? 24 : 8,
                      height: 8,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == index
                            ? scheme.primary
                            : colors.faint,
                        borderRadius:
                            BorderRadius.circular(AppRadii.pill),
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            top: AppSpace.sm,
            left: AppSpace.lg,
            child: SafeArea(
              bottom: false,
              child: _RoundButton(
                icon: Icons.arrow_back,
                onTap: onBack,
              ),
            ),
          ),
          Positioned(
            top: AppSpace.sm,
            right: AppSpace.lg,
            child: SafeArea(
              bottom: false,
              child: CardHeart(
                key: const Key('pdp-heart'),
                slug: detail.slug,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// Inline radio rows for ≤3 variants, otherwise a sheet opener.
class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<Variant> variants;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    if (variants.length > 3) {
      final selected = variants[selectedIndex.clamp(0, variants.length - 1)];
      return OutlinedButton(
        key: const Key('pdp-variant-open'),
        onPressed: () async {
          final picked = await VariantSheet.show(
            context,
            options: [
              for (final v in variants)
                VariantOption(id: v.id, name: v.name, price: v.price),
            ],
            initialIndex: selectedIndex,
          );
          if (picked != null) {
            final at =
                variants.indexWhere((v) => v.id == picked.id);
            if (at >= 0) onSelect(at);
          }
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: colors.faint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('${selected.name} · ₹${_rupees(selected.price)}',
                  style: AppTypography.bodyMedium(scheme.onSurface)),
            ),
            Icon(Icons.keyboard_arrow_down, color: scheme.onSurfaceVariant),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < variants.length; i++)
          InkWell(
            key: Key('pdp-variant-${variants[i].id}'),
            borderRadius: BorderRadius.circular(AppRadii.input),
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(i);
            },
            child: SizedBox(
              height: 52,
              child: Row(
                children: [
                  Icon(
                    i == selectedIndex
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: i == selectedIndex
                        ? scheme.primary
                        : colors.faint,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(variants[i].name,
                        style: AppTypography.bodyMedium(
                            scheme.onSurface)),
                  ),
                  Text('₹${_rupees(variants[i].price)}',
                      style: AppTypography.tabularNumber(
                          scheme.onSurface)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// ETA pill + quiet inline pincode check (no celebration).
class _DeliveryRow extends ConsumerStatefulWidget {
  const _DeliveryRow({required this.detail});

  final ProductDetail detail;

  @override
  ConsumerState<_DeliveryRow> createState() => _DeliveryRowState();
}

class _DeliveryRowState extends ConsumerState<_DeliveryRow> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final pin = ref.watch(pincodeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtaPill(minutes: 12),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  key: const Key('pdp-pincode'),
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (_) {},
                  style: AppTypography.body(scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Delivery pincode',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.input),
                      borderSide: BorderSide(color: colors.faint),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              width: 96,
              height: 48,
              child: OutlinedButton(
                key: const Key('pdp-pincode-check'),
                onPressed: pin.checking
                    ? null
                    : () => ref
                        .read(pincodeControllerProvider.notifier)
                        .check(_pin.text),
                child: pin.checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check'),
              ),
            ),
          ],
        ),
        if (pin.info != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              'Delivery to ${pin.code} · ${pin.info!.city} in ${pin.info!.etaDays} days',
              style:
                  AppTypography.caption(colors.success),
            ),
          ),
        if (pin.error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              _cleanError(pin.error!),
              style: AppTypography.caption(scheme.error),
            ),
          ),
      ],
    );
  }
}

/// Rating summary that never shows a "0.0" pill: unrated products get a
/// quiet label instead.
class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Text(
        'No ratings yet',
        style: AppTypography.caption(
            Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return RatingPill(rating: rating, count: count);
  }
}

/// Reviews: summary + list + collapsible post form (409 → already-reviewed).
class _ReviewsBlock extends ConsumerWidget {
  const _ReviewsBlock({
    required this.slug,
    required this.ratingAvg,
    required this.ratingCount,
    required this.showForm,
    required this.rating,
    required this.posting,
    required this.reviewError,
    required this.titleController,
    required this.bodyController,
    required this.onToggleForm,
    required this.onRating,
    required this.onPost,
  });

  final String slug;
  final double ratingAvg;
  final int ratingCount;
  final bool showForm;
  final int rating;
  final bool posting;
  final String? reviewError;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final VoidCallback onToggleForm;
  final ValueChanged<int> onRating;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final reviews = ref.watch(productReviewsProvider(slug));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reviews',
                  style: AppTypography.productName(scheme.onSurface,
                          size: 17)
                      .copyWith(fontWeight: FontWeight.w700)),
              _RatingSummary(rating: ratingAvg, count: ratingCount),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          reviews.when(
            loading: () => const Column(
              children: [
                SkeletonLine(),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(width: 220),
              ],
            ),
            error: (_, _) => Text('Could not load reviews.',
                style: AppTypography.caption(scheme.onSurfaceVariant)),
            data: (rows) => rows.isEmpty
                ? Text('No reviews yet — be the first.',
                    style: AppTypography.body(
                        scheme.onSurfaceVariant))
                : Column(
                    children: [
                      for (final review in rows)
                        _ReviewCard(review: review),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(
            key: const Key('review-write'),
            onPressed: onToggleForm,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: colors.faint),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppRadii.input),
              ),
            ),
            child: const Text('Write a review'),
          ),
          if (showForm) ...[
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: Key('review-star-$i'),
                    onPressed: () => onRating(i),
                    icon: Icon(
                      i <= rating
                          ? Icons.star
                          : Icons.star_border,
                      color: colors.marigold,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            TextField(
              key: const Key('review-title'),
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'Headline (optional)'),
            ),
            const SizedBox(height: AppSpace.sm),
            TextField(
              key: const Key('review-body'),
              controller: bodyController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'What did you like?'),
            ),
            if (reviewError != null) ...[
              const SizedBox(height: AppSpace.xs),
              Text(reviewError!,
                  key: const Key('review-error'),
                  style: AppTypography.caption(scheme.error)),
            ],
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                key: const Key('review-submit'),
                onPressed: posting ? null : onPost,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadii.button),
                  ),
                ),
                child: posting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      )
                    : const Text('Post review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName.isEmpty
                      ? 'Verified buyer'
                      : review.userName,
                  style: AppTypography.label(scheme.onSurface),
                ),
              ),
              if (review.verified)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primaryTint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text('Verified',
                      style: AppTypography.label(scheme.primary,
                          size: 11)),
                ),
              const SizedBox(width: AppSpace.sm),
              Icon(Icons.star, size: 14, color: colors.marigold),
              const SizedBox(width: 2),
              Text('${review.rating}',
                  style: AppTypography.tabularSmall(
                      scheme.onSurfaceVariant)),
            ],
          ),
          if (review.title.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(review.title,
                style:
                    AppTypography.bodyMedium(scheme.onSurface)),
          ],
          if (review.body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(review.body,
                style: AppTypography.body(
                    scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Featured-products rail excluding the current product.
class _RelatedRail extends ConsumerWidget {
  const _RelatedRail({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedProductsProvider(slug));
    return related.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.xl, AppSpace.lg, 0),
              child: SectionHeader(title: 'You may also like'),
            ),
            const SizedBox(height: AppSpace.sm),
            SizedBox(
              height: 336,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg),
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpace.md),
                itemBuilder: (_, i) => ProductCard(
                  product: rows[i],
                  density: ProductDensity.rail,
                  width: 148,
                  onTap: () =>
                      context.push('/product/${rows[i].slug}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sticky thumb-zone bar: server PriceBlock + a confirm-before-add pipeline.
/// First tap opens a pending stepper (nothing hits the server); the confirm
/// CTA commits the chosen units at once. Once units live in the cart, the
/// stepper edits them live (+ → addItem, − → PATCH-by-rewrite).
class _StickyBar extends ConsumerStatefulWidget {
  const _StickyBar({
    super.key,
    required this.price,
    required this.mrp,
    required this.discountPercent,
    required this.variantId,
  });

  final double price;
  final double mrp;
  final int discountPercent;
  final int? variantId;

  @override
  ConsumerState<_StickyBar> createState() => _StickyBarState();
}

class _StickyBarState extends ConsumerState<_StickyBar> {
  bool _selecting = false;
  int _pending = 1;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final variantId = widget.variantId;
    final qty = variantId == null
        ? 0
        : (ref.watch(pdpCartControllerProvider).qtyByVariant[variantId] ??
            0);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
            top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: PriceBlock(
                  price: widget.price,
                  mrp: widget.mrp,
                  discountPercent: widget.discountPercent),
            ),
            if (variantId == null)
              Text('Unavailable',
                  style: AppTypography.label(
                      scheme.onSurfaceVariant))
            else
              KeyedSubtree(
                key: const Key('pdp-sticky-stepper'),
                child: _control(context, variantId, qty),
              ),
          ],
        ),
      ),
    );
  }

  Widget _control(BuildContext context, int variantId, int qty) {
    if (qty == 0 && !_selecting) return _addPill(context);
    if (_selecting && qty == 0) return _pendingPicker(context, variantId);
    return QtyStepper(
      quantity: qty,
      onChanged: (next) {
        if (next > qty) {
          ref.read(pdpCartControllerProvider.notifier).increment(variantId);
        } else {
          ref.read(pdpCartControllerProvider.notifier).decrement(variantId);
        }
      },
    );
  }

  /// Phase 1 — nothing in the cart yet: an Add pill that only OPENS the
  /// pending picker. No server call happens here.
  Widget _addPill(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: const ValueKey('phase-add'),
      child: SizedBox(
        height: 40,
        child: OutlinedButton(
          key: const Key('pdp-add'),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selecting = true;
              _pending = 1;
            });
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(72, 40),
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            side: BorderSide(color: scheme.primary),
            foregroundColor: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            textStyle: AppTypography.label(scheme.primary),
          ),
          child: const Text('Add'),
        ),
      ),
    );
  }

  /// Phase 2 — pending picker: local stepper + a confirm CTA that commits
  /// the chosen units in ONE addItem call. Backing to 0 cancels.
  Widget _pendingPicker(BuildContext context, int variantId) {
    final scheme = Theme.of(context).colorScheme;
    return KeyedSubtree(
      key: const ValueKey('phase-select'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          QtyStepper(
            key: const ValueKey('pending'),
            quantity: _pending,
            onChanged: (next) {
              if (next <= 0) {
                setState(() => _selecting = false);
              } else {
                setState(() => _pending = next);
              }
            },
          ),
          const SizedBox(height: AppSpace.xs),
          SizedBox(
            width: 176,
            height: 44,
            child: FilledButton(
              key: const Key('pdp-confirm'),
              onPressed: _confirming ? null : () => _confirm(variantId),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: _confirming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Add $_pending · ₹${_rupees(widget.price * _pending)}',
                      style: AppTypography.label(scheme.onPrimary),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(int variantId) async {
    setState(() => _confirming = true);
    try {
      await ref
          .read(cartRepositoryProvider)
          .addItem(variantId: variantId, quantity: _pending);
      await ref.read(pdpCartControllerProvider.notifier).refresh();
      if (!mounted) return;
      setState(() {
        _confirming = false;
        _selecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      showAppSnackbar(context, 'Could not add to cart.');
    }
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

String _cleanError(Object e) =>
    e is ApiException ? e.message : 'Something went wrong.';