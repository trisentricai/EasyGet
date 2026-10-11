import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/product/presentation/product_screen.dart';
import 'package:easyget/features/reviews/data/review_repository.dart';
import 'package:easyget/features/wishlist/data/wishlist_repository.dart';
import 'package:easyget/models/cart_models.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/review_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

ProductDetail _detail(String slug) {
  final variantCount = slug == 'atta-5kg' ? 4 : 2;
  return ProductDetail(
      id: 1,
      name: slug == 'related-1' ? 'Related Product' : 'Amul Butter',
      slug: slug,
      brand: 'Amul',
      mrp: 349,
      basePrice: 289,
      discountPercent: 17,
      ratingAvg: 4.3,
      ratingCount: 212,
      description: 'Creamy farm butter.',
      images: const [
        ProductImage(url: 'https://example.com/b1.jpg', isPrimary: true),
        ProductImage(url: 'https://example.com/b2.jpg'),
      ],
      variants: [
        for (var i = 0; i < variantCount; i++)
          Variant(
              id: 11 + i, name: '${(i + 1) * 100} g', price: 199.0 + i * 45),
      ],
    );
}

class _FakeCatalogRepo implements CatalogRepository {
  final List<String> pincodeCalls = [];

  @override
  Future<ProductDetail> product(String slug) async => _detail(slug);

  @override
  Future<CatalogPage> products({
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    double? minDiscount,
    bool? isFeatured,
    String? sort,
    int? page,
  }) async =>
      CatalogPage(
        results: [
          const CatalogProduct(
              id: 2,
              name: 'Related Product',
              slug: 'related-1',
              brand: 'Acme',
              mrp: 120,
              basePrice: 99,
              primaryImage: 'https://example.com/r.jpg'),
          const CatalogProduct(
              id: 1,
              name: 'Amul Butter',
              slug: 'amul-butter',
              brand: 'Amul',
              mrp: 349,
              basePrice: 289),
        ],
        total: 2,
        page: 1,
        pageSize: 10,
      );

  @override
  Future<PincodeInfo> pincode(String code) async {
    pincodeCalls.add(code);
    if (code == '000000') {
      throw ApiException('Delivery is not available for 000000.');
    }
    return const PincodeInfo(
        valid: true,
        pincode: '560001',
        city: 'Bengaluru',
        state: 'KA',
        etaDays: 2,
        deliveryFee: 30);
  }

  @override
  Future<List<Category>> categories() async => const [];
  @override
  Future<List<Brand>> brands() => throw UnimplementedError();
  @override
  Future<CatalogPage> search(String query,
          {String? sort,
          int page = 1,
          String? category,
          double? minPrice,
          double? maxPrice,
          bool? isFeatured}) =>
      throw UnimplementedError();
  @override
  Future<StorefrontRender> platformStorefront() =>
      throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

class _FakeReviewsRepo implements ReviewRepository {
  final List<Review> rows = [
    const Review(
        id: 1,
        rating: 5,
        title: 'Superb',
        body: 'Melts perfectly.',
        userName: 'Meera',
        verified: true),
  ];
  bool failDuplicate = false;
  final List<int> postedRatings = [];

  @override
  Future<List<Review>> list(String slug) async => List.of(rows);

  @override
  Future<Review> create(String slug,
      {required int rating, String title = '', String body = ''}) async {
    if (failDuplicate) throw ApiException('already reviewed');
    postedRatings.add(rating);
    final review = Review(
        id: rows.length + 1,
        rating: rating,
        title: title,
        body: body,
        userName: 'You');
    rows.add(review);
    return review;
  }
}

class _FakeWishlistRepo implements WishlistRepository {
  final hearts = <String>{};
  final List<Map<String, Object?>> toggles = [];

  @override
  Future<List<String>> fetch() async => hearts.toList();

  @override
  Future<WishlistToggle> toggle(String slug, {bool hearted = false}) async {
    toggles.add({'slug': slug, 'hearted': hearted});
    if (hearted) {
      hearts.remove(slug);
    } else {
      hearts.add(slug);
    }
    return WishlistToggle(added: !hearted, slug: slug);
  }
}

class _FakeCartRepo implements CartRepository {
  final lines = <CartItem>[];
  int _nextId = 1;
  final List<String> calls = [];

  Cart _cart() => Cart(
        id: 1,
        items: List.of(lines),
        totalItems: lines.fold(0, (a, e) => a + e.quantity),
        subtotal: lines.fold(0.0, (a, e) => a + e.lineTotal),
      );

  @override
  Future<Cart> fetchCart() async => _cart();

  @override
  Future<void> addItem({required int variantId, int quantity = 1}) async {
    calls.add('add $variantId x$quantity');
    final at = lines.indexWhere((e) => e.variantId == variantId);
    if (at >= 0) {
      final line = lines[at];
      lines[at] = CartItem(
          id: line.id,
          variantId: line.variantId,
          variantLabel: line.variantLabel,
          variantName: line.variantName,
          price: line.price,
          quantity: line.quantity + quantity,
          lineTotal: line.price * (line.quantity + quantity));
    } else {
      lines.add(CartItem(
          id: _nextId++,
          variantId: variantId,
          variantLabel: 'v$variantId',
          variantName: 'Variant $variantId',
          price: 199,
          quantity: quantity,
          lineTotal: 199.0 * quantity));
    }
  }

  @override
  Future<void> updateQty(int itemId, int quantity) async {
    calls.add('update $itemId x$quantity');
    final at = lines.indexWhere((e) => e.id == itemId);
    final line = lines[at];
    lines[at] = CartItem(
        id: line.id,
        variantId: line.variantId,
        variantLabel: line.variantLabel,
        variantName: line.variantName,
        price: line.price,
        quantity: quantity,
        lineTotal: line.price * quantity);
  }

  @override
  Future<void> remove(int itemId) async {
    calls.add('remove $itemId');
    lines.removeWhere((e) => e.id == itemId);
  }

  @override
  Future<void> clear() async => lines.clear();
}

Future<void> _pumpPdp(
  WidgetTester tester, {
  required _FakeCatalogRepo catalog,
  required _FakeReviewsRepo reviews,
  required _FakeWishlistRepo wishlist,
  required _FakeCartRepo cart,
  String slug = 'amul-butter',
}) async {
  final router = GoRouter(
    initialLocation: '/product/$slug',
    routes: [
      GoRoute(
        path: '/product/:slug',
        builder: (context, state) {
          final s = state.pathParameters['slug']!;
          return ProductScreen(key: ValueKey(s), slug: s);
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        reviewRepositoryProvider.overrideWithValue(reviews),
        wishlistRepositoryProvider.overrideWithValue(wishlist),
        cartRepositoryProvider.overrideWithValue(cart),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders gallery, name, price, rating, story and reviews',
      (tester) async {
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    expect(find.byKey(const Key('pdp-image')), findsWidgets);
    expect(find.byKey(const Key('pdp-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('pdp-dot-1')), findsOneWidget);
    expect(find.text('Amul Butter'), findsWidgets);
    expect(find.text('₹199'), findsWidgets);
    expect(find.text('₹244'), findsOneWidget);
    expect(find.text('4.3'), findsWidgets);
    expect(find.text('Creamy farm butter.'), findsOneWidget);
    expect(find.text('Superb'), findsOneWidget);
    expect(find.byKey(const Key('pdp-heart')), findsOneWidget);
  });

  testWidgets('heart toggles the wishlist', (tester) async {
    final wishlist = _FakeWishlistRepo();
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: wishlist,
      cart: _FakeCartRepo(),
    );

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byKey(const Key('pdp-heart')));
    await tester.pumpAndSettle();

    expect(wishlist.toggles.single, {'slug': 'amul-butter', 'hearted': false});
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('inline variant switch swaps the price', (tester) async {
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    expect(find.text('₹199'), findsWidgets);
    await _scrollTo(tester, find.byKey(const Key('pdp-variant-12')));
    await tester.tap(find.byKey(const Key('pdp-variant-12')));
    await tester.pumpAndSettle();
    // Main + sticky blocks follow the selection; only the variant row keeps
    // showing ₹199.
    expect(find.text('₹199'), findsOneWidget);
    expect(find.text('₹244'), findsWidgets);
  });

  testWidgets('more than 3 variants open the VariantSheet', (tester) async {
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
      slug: 'atta-5kg',
    );

    expect(find.byKey(const Key('pdp-variant-open')), findsOneWidget);
    await _scrollTo(tester, find.byKey(const Key('pdp-variant-open')));
    await tester.tap(find.byKey(const Key('pdp-variant-open')));
    await tester.pumpAndSettle();

    expect(find.text('Choose a size'), findsOneWidget);
    await tester.tap(find.byKey(const Key('variant-option-3')));
    await tester.pumpAndSettle();
    expect(find.text('Add · ₹334'), findsOneWidget);

    await tester.tap(find.byKey(const Key('variant-cta')));
    await tester.pumpAndSettle();
    expect(find.text('₹334'), findsWidgets);
  });

  testWidgets('add opens a pending picker; confirm commits the units',
      (tester) async {
    final cart = _FakeCartRepo();
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: cart,
    );

    Finder withinSticky(Finder inner) => find.descendant(
          of: find.byKey(const Key('pdp-sticky-stepper')),
          matching: inner,
        );

    // Phase 1: Add opens the picker — nothing hits the server yet.
    await tester.tap(withinSticky(find.byKey(const Key('pdp-add'))));
    await tester.pumpAndSettle();
    expect(cart.calls, isEmpty);
    expect(withinSticky(find.text('Add 1 · ₹199')), findsOneWidget);

    // Phase 2: choosing units only updates the pending CTA…
    await tester.tap(withinSticky(find.byKey(const Key('qty-plus'))));
    await tester.pumpAndSettle();
    expect(cart.calls, isEmpty);
    expect(withinSticky(find.text('Add 2 · ₹398')), findsOneWidget);

    // …confirm commits both units in ONE call, then the live stepper shows.
    await tester.tap(withinSticky(find.byKey(const Key('pdp-confirm'))));
    await tester.pumpAndSettle();
    expect(cart.calls, ['add 11 x2']);
    expect(withinSticky(find.text('2')), findsOneWidget);

    // Live edits still apply straight to the server cart.
    await tester.tap(withinSticky(find.byKey(const Key('qty-minus'))));
    await tester.pumpAndSettle();
    expect(cart.calls.last, 'update 1 x1');
  });

  testWidgets('backing the picker to zero returns to Add', (tester) async {
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    Finder withinSticky(Finder inner) => find.descendant(
          of: find.byKey(const Key('pdp-sticky-stepper')),
          matching: inner,
        );

    await tester.tap(withinSticky(find.byKey(const Key('pdp-add'))));
    await tester.pumpAndSettle();
    await tester.tap(withinSticky(find.byKey(const Key('qty-minus'))));
    await tester.pumpAndSettle();
    expect(withinSticky(find.byKey(const Key('pdp-add'))), findsOneWidget);
  });

  testWidgets('pincode checker answers quietly inline', (tester) async {
    final catalog = _FakeCatalogRepo();
    await _pumpPdp(
      tester,
      catalog: catalog,
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    await _scrollTo(tester, find.byKey(const Key('pdp-pincode')));
    await tester.enterText(
        find.byKey(const Key('pdp-pincode')), '560001');
    await tester.tap(find.byKey(const Key('pdp-pincode-check')));
    await tester.pumpAndSettle();

    expect(catalog.pincodeCalls, ['560001']);
    expect(find.textContaining('Delivery to 560001'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('pdp-pincode')), '000000');
    await tester.tap(find.byKey(const Key('pdp-pincode-check')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not available for 000000'), findsOneWidget);
  });

  testWidgets('posting a review appends it to the list', (tester) async {
    final reviews = _FakeReviewsRepo();
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: reviews,
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    await _scrollTo(tester, find.byKey(const Key('review-write')));
    await tester.tap(find.byKey(const Key('review-write')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('review-submit')));

    await tester.tap(find.byKey(const Key('review-star-5')));
    await tester.enterText(
        find.byKey(const Key('review-body')), 'Loved it.');
    await tester.tap(find.byKey(const Key('review-submit')));
    await tester.pumpAndSettle();

    expect(reviews.postedRatings, [5]);
    expect(find.text('Loved it.'), findsOneWidget);
  });

  testWidgets('duplicate review shows the already-reviewed message',
      (tester) async {
    final reviews = _FakeReviewsRepo()..failDuplicate = true;
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: reviews,
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    await _scrollTo(tester, find.byKey(const Key('review-write')));
    await tester.tap(find.byKey(const Key('review-write')));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(const Key('review-submit')));

    await tester.enterText(
        find.byKey(const Key('review-body')), 'Again.');
    await tester.tap(find.byKey(const Key('review-submit')));
    await tester.pumpAndSettle();

    expect(
        find.text('You have already reviewed this product.'),
        findsOneWidget);
  });

  testWidgets('related rail opens the related product', (tester) async {
    await _pumpPdp(
      tester,
      catalog: _FakeCatalogRepo(),
      reviews: _FakeReviewsRepo(),
      wishlist: _FakeWishlistRepo(),
      cart: _FakeCartRepo(),
    );

    await _scrollTo(tester, find.text('Related Product'));
    await tester.tap(find.text('Related Product'));
    await tester.pumpAndSettle();
    expect(find.text('Related Product'), findsOneWidget);
  });
}