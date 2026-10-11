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
    return _render;
  }

  @override
  Future<List<Category>> categories() async {
    categoriesCalls++;
    if (fail) throw Exception('boom');
    return empty ? const [] : _categories;
  }

  @override
  Future<CatalogPage> products(
          {String? category,
          String? brand,
          double? minPrice,
          double? maxPrice,
          double? minDiscount,
          bool? isFeatured,
          String? sort,
          int? page}) =>
      throw UnimplementedError();
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
    expect(find.byType(PageView), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-0')), findsOneWidget);
    expect(find.byKey(const Key('carousel-dot-1')), findsOneWidget);

    expect(find.text('Shop by category'), findsOneWidget);
    expect(find.text('Cat 1'), findsOneWidget);
    expect(find.text('Cat 8'), findsOneWidget);
    expect(find.text('Cat 9'), findsNothing);

    expect(find.text('Fresh picks'), findsOneWidget);
    expect(find.text('Amul Butter'), findsOneWidget);
    expect(find.text('₹289'), findsOneWidget);
    expect(find.text('Our story'), findsOneWidget);
  });

  testWidgets('See all goes to /browse and rail cards go to the PDP',
      (tester) async {
    await _pumpHome(tester, _FakeCatalogRepo());

    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browse-page')), findsOneWidget);
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
}