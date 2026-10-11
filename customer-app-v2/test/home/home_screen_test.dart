import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/home/presentation/home_screen.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeCatalogRepo implements CatalogRepository {
  int storefrontCalls = 0;
  int categoriesCalls = 0;
  bool fail = false;
  bool empty = false;
  bool typelessProducts = false;
  bool storyOnly = false;

  StorefrontRender get _render => StorefrontRender(
        store: const StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: const StoreTheme(),
        ticker: const Ticker(items: ['Free delivery over ₹499']),
        sections: [
          StorefrontSection(
            id: 1,
            type: 'BANNER',
            title: 'Offers',
            items: [
              const SectionItem(
                  id: 1,
                  image: 'https://example.com/b1.jpg',
                  link: '/product/amul-butter'),
              const SectionItem(
                  id: 2,
                  image: 'https://example.com/b2.jpg',
                  link: '/browse'),
            ],
          ),
          StorefrontSection(
            id: 2,
            type: 'PRODUCT_ROW',
            title: 'Fresh picks',
            items: [
              const SectionItem(
                  id: 3,
                  productSlug: 'amul-butter',
                  caption: 'Amul Butter',
                  image: 'https://example.com/butter.jpg',
                  productPrice: 289),
              const SectionItem(
                  id: 4,
                  productSlug: 'atta-5kg',
                  caption: 'Whole Wheat Atta 5 kg',
                  image: 'https://example.com/atta.jpg',
                  productPrice: 240),
            ],
          ),
          const StorefrontSection(
            id: 3,
            type: 'RICH_TEXT',
            title: 'Our story',
            subtitle: 'Farm fresh, every morning.',
          ),
          const StorefrontSection(
            id: 4,
            type: 'HERO',
            title: 'Festival sale',
            items: [
              SectionItem(
                  id: 5, image: 'https://example.com/hero.jpg'),
            ],
          ),
        ],
      );

  List<Category> get _categories => [
        for (var i = 1; i <= 10; i++)
          Category(id: i, name: 'Cat $i', slug: 'cat-$i'),
      ];

  @override
  Future<StorefrontRender> platformStorefront() async {
    storefrontCalls++;
    if (fail) throw Exception('boom');
    if (empty) {
      return const StorefrontRender(
        store: StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: StoreTheme(),
      );
    }
    if (typelessProducts) {
      return const StorefrontRender(
        store: StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: StoreTheme(),
        sections: [
          StorefrontSection(
            id: 9,
            type: '',
            title: 'Mystery picks',
            items: [
              SectionItem(
                  id: 10,
                  productSlug: 'mystery-butter',
                  caption: 'Mystery Butter',
                  productPrice: 150),
            ],
          ),
        ],
      );
    }
    if (storyOnly) {
      return const StorefrontRender(
        store: StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: StoreTheme(),
        sections: [
          StorefrontSection(
            id: 3,
            type: 'RICH_TEXT',
            title: 'Our story',
            subtitle: 'Farm fresh, every morning.',
          ),
        ],
      );
    }
    return _render;
  }

  @override
  Future<List<Category>> categories() async {
    categoriesCalls++;
    if (fail) throw Exception('boom');
    return empty ? const [] : _categories;
  }

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
  }) async {
    // Sorted/featured calls feed the fallback rails (single row each).
    if (isFeatured == true || sort != null) {
      return const CatalogPage(
        results: [
          CatalogProduct(
              id: 7,
              name: 'Fallback Find',
              slug: 'fallback-find',
              brand: 'Acme',
              mrp: 120,
              basePrice: 99),
        ],
        total: 1,
        page: 1,
        pageSize: 10,
      );
    }
    // Plain calls feed All-products: bare 20/page backend shape.
    final p = page ?? 1;
    final count = p == 1 ? 20 : 5;
    final base = p == 1 ? 0 : 20;
    return CatalogPage(
      results: [
        for (var i = 0; i < count; i++)
          CatalogProduct(
              id: 100 + base + i,
              name: 'HomeItem ${base + i + 1}',
              slug: 'home-${base + i + 1}',
              brand: 'Acme',
              mrp: 120,
              basePrice: 99),
      ],
      total: count,
      page: 1,
    );
  }
  @override
  Future<ProductDetail> product(String slug) => throw UnimplementedError();
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
  Future<PincodeInfo> pincode(String code) => throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

Future<void> _pumpHome(WidgetTester tester, _FakeCatalogRepo repo) async {
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/browse',
        builder: (_, _) =>
            const Scaffold(key: Key('browse-page'), body: Text('BROWSE')),
      ),
      GoRoute(
        path: '/browse/all',
        builder: (_, _) => const Scaffold(
            key: Key('browse-all-page'), body: Text('BROWSE ALL')),
      ),
      GoRoute(
        path: '/product/:slug',
        builder: (_, _) =>
            const Scaffold(key: Key('product-page'), body: Text('PRODUCT')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders ticker, carousel, 8 categories + See all, rails, story',
      (tester) async {
    await _pumpHome(tester, _FakeCatalogRepo());

    expect(find.text('Free delivery over ₹499'), findsOneWidget);
    // Banner carousel + full-bleed hero banner.
    expect(find.byType(PageView), findsNWidgets(2));
    expect(find.byKey(const Key('carousel-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-1')), findsOneWidget);

    expect(find.text('Shop by category'), findsOneWidget);
    expect(find.text('Cat 1'), findsOneWidget);
    expect(find.text('Cat 8'), findsOneWidget);
    expect(find.text('Cat 9'), findsNothing);

    // Strictly horizontal, non-wrapping category track.
    final track = tester.widget<ListView>(find.descendant(
      of: find.byKey(const Key('home-category-track')),
      matching: find.byType(ListView),
    ));
    expect(track.scrollDirection, Axis.horizontal);

    expect(find.text('Fresh picks'), findsOneWidget);
    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.text('₹289'), findsOneWidget);
    expect(find.text('Our story'), findsOneWidget);
  });

  testWidgets('See all pushes BrowseScreen; system back returns Home',
      (tester) async {
    await _pumpHome(tester, _FakeCatalogRepo());

    await tester.scrollUntilVisible(
      find.text('See all'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browse-all-page')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Fresh picks'), findsOneWidget);
  });

  testWidgets('rail card tap opens its product', (tester) async {
    await _pumpHome(tester, _FakeCatalogRepo());

    await tester.scrollUntilVisible(
      find.text('Amul Butter'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amul Butter'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-page')), findsOneWidget);
  });

  testWidgets('pull-to-refresh re-fires the storefront + categories',
      (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpHome(tester, repo);
    expect(repo.storefrontCalls, 1);

    await tester.fling(
        find.byType(SingleChildScrollView), const Offset(0, 300), 800);
    await tester.pumpAndSettle();
    expect(repo.storefrontCalls, 2);
    expect(repo.categoriesCalls, 2);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeCatalogRepo()..fail = true;
    await _pumpHome(tester, repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Fresh picks'), findsOneWidget);
  });

  testWidgets('empty storefront shows EmptyState', (tester) async {
    final repo = _FakeCatalogRepo()..empty = true;
    await _pumpHome(tester, repo);

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('typeless product sections still render as rails',
      (tester) async {
    final repo = _FakeCatalogRepo()..typelessProducts = true;
    await _pumpHome(tester, repo);

    expect(find.text('Mystery picks'), findsOneWidget);
    expect(find.text('Mystery Butter'), findsOneWidget);
  });

  testWidgets('no product rows falls back to catalog rails', (tester) async {
    final repo = _FakeCatalogRepo()..storyOnly = true;
    await _pumpHome(tester, repo);

    expect(find.text('Hot sales'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);
    expect(find.text('New arrivals'), findsOneWidget);
    expect(find.text('Fallback Find'), findsWidgets);
  });

  testWidgets('All products grid pages with an explicit Show more',
      (tester) async {
    await _pumpHome(tester, _FakeCatalogRepo());

    expect(find.text('All products'), findsOneWidget);
    expect(find.text('HomeItem 1'), findsOneWidget);
    expect(find.text('Show more · 20 shown'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('all-products-more')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('all-products-more')));
    await tester.pumpAndSettle();

    expect(find.text('Show more · 20 shown'), findsNothing);
    expect(find.text('You have seen all 25 products'), findsOneWidget);
  });
}