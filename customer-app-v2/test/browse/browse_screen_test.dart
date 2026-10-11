import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/browse/presentation/browse_filter_sheet.dart';
import 'package:easyget/features/browse/presentation/browse_screen.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

CatalogProduct _product(int id, String name, double price) => CatalogProduct(
      id: id,
      name: name,
      slug: 'p-$id',
      brand: 'Acme',
      mrp: price + 40,
      basePrice: price,
      ratingAvg: 4.2,
      ratingCount: 50,
    );

class _FakeCatalogRepo implements CatalogRepository {
  final List<Map<String, Object?>> queries = [];
  bool failProducts = false;

  List<Category> get _categories => [
        const Category(id: 1, name: 'Cat 1', slug: 'cat-1'),
        const Category(id: 2, name: 'Cat 2', slug: 'cat-2'),
      ];

  @override
  Future<List<Category>> categories() async => _categories;

  @override
  Future<List<Brand>> brands() async => const [
        Brand(id: 1, name: 'Acme', slug: 'acme'),
        Brand(id: 2, name: 'Volt', slug: 'volt'),
      ];

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
    queries.add({
      'category': category,
      'brand': brand,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'isFeatured': isFeatured,
      'minDiscount': minDiscount,
      'sort': sort,
      'page': page,
    });
    if (failProducts) throw Exception('boom');
    if (category == 'empty-cat') {
      return const CatalogPage(results: [], total: 0, page: 1);
    }
    if (category == 'many') {
      // Bare-list backend shape: no envelope (total/count echo, page echo).
      final p = page ?? 1;
      final count = p == 1 ? 20 : 5;
      final base = p == 1 ? 0 : 20;
      return CatalogPage(
        results: [
          for (var i = 0; i < count; i++)
            _product(p * 100 + i, 'Many ${base + i + 1}', 100),
        ],
        total: count,
        page: 1,
      );
    }
    final p = page ?? 1;
    return CatalogPage(
      results: [
        _product(p * 10 + 1, 'Item ${p}A', 100),
        _product(p * 10 + 2, 'Item ${p}B', 200),
      ],
      total: 4,
      page: p,
      pageSize: 2,
    );
  }

  @override
  Future<ProductDetail> product(String slug) => throw UnimplementedError();
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
  Future<StorefrontRender> platformStorefront() =>
      throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

Future<void> _pumpBrowse(
  WidgetTester tester,
  _FakeCatalogRepo repo, {
  String location = '/browse',
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/browse',
        builder: (_, _) => const BrowseScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (_, _) =>
            const Scaffold(key: Key('search-page'), body: Text('SEARCH')),
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

  testWidgets('chips sync with ?category= and drive the query', (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo, location: '/browse?category=cat-1');

    expect(repo.queries.last['category'], 'cat-1');
    expect(find.text('4 items'), findsOneWidget);
    expect(find.text('Item 1A'), findsOneWidget);
  });

  testWidgets('tapping a chip navigates and re-queries', (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo);

    await tester.tap(find.text('Cat 2'));
    await tester.pumpAndSettle();

    expect(repo.queries.last['category'], 'cat-2');
    expect(find.text('Item 1A'), findsOneWidget);
  });

  testWidgets('toolbar shows count and opens Filter + Sort sheets',
      (tester) async {
    await _pumpBrowse(tester, _FakeCatalogRepo());

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Price'), findsOneWidget);
    expect(find.text('Discount'), findsOneWidget);
    expect(
        find.descendant(
          of: find.byType(BrowseFilterSheet),
          matching: find.text('Acme'),
        ),
        findsOneWidget);
    expect(find.text('Show 4'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.text('Show 4'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Sort'));
    await tester.pumpAndSettle();
    expect(find.text('Price: Low to High'), findsOneWidget);
  });

  testWidgets('grid is 2 columns with a 12dp gap', (tester) async {
    await _pumpBrowse(tester, _FakeCatalogRepo());

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
    expect(delegate.mainAxisSpacing, 12);
    expect(delegate.crossAxisSpacing, 12);
    // 800px viewport → 378px columns → aspect derived from card anatomy.
    expect(delegate.childAspectRatio, closeTo(0.58, 0.01));
  });

  testWidgets('applying Featured resets to page 1 with the filter',
      (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Featured only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 4'));
    await tester.pumpAndSettle();

    final last = repo.queries.last;
    expect(last['isFeatured'], isTrue);
    expect(last['page'], 1);
    expect(find.text('Filter · 1'), findsOneWidget);
  });

  testWidgets('brand + price + discount flow into the query', (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo);

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    final sheetAcme = find.descendant(
      of: find.byType(BrowseFilterSheet),
      matching: find.text('Acme'),
    );
    await tester.tap(sheetAcme);
    await tester.pumpAndSettle();
    await tester.tap(find.text('₹100–500'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20%+'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 4'));
    await tester.pumpAndSettle();

    final last = repo.queries.last;
    expect(last['brand'], 'acme');
    expect(last['minPrice'], 100);
    expect(last['maxPrice'], 500);
    expect(last['minDiscount'], 20.0);
    expect(find.text('Filter · 3'), findsOneWidget);
  });

  testWidgets('sort selection re-queries with the sort param', (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo);

    await tester.tap(find.textContaining('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price: Low to High'));
    await tester.pumpAndSettle();

    expect(repo.queries.last['sort'], 'price_asc');
    expect(find.textContaining('Price: Low to High'), findsOneWidget);
  });

  testWidgets('card tap opens the PDP', (tester) async {
    await _pumpBrowse(tester, _FakeCatalogRepo());

    // NOTE: no pumpAndSettle past this point — the trailing hasMore spinner
    // animates forever by design. Explicit pumps let the fling fully stop so
    // the tap registers as a tap instead of a scroll-stop.
    await tester.scrollUntilVisible(
      find.text('Item 1A'),
      500,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Item 1A'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-page')), findsOneWidget);

    // System back must return to Browse (push, never go).
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Item 1A'), findsOneWidget);
  });

  testWidgets('empty category offers Clear filters', (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo, location: '/browse?category=empty-cat');

    expect(find.text('Clear filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Item 1A'), findsOneWidget);
    expect(repo.queries.last['category'], isNull);
  });

  testWidgets('bare-list backend pages on via the full-page rule',
      (tester) async {
    final repo = _FakeCatalogRepo();
    await _pumpBrowse(tester, repo, location: '/browse?category=many');

    // Total unknown on bare lists: the toolbar shows the loaded count.
    expect(find.text('20 items'), findsOneWidget);
    expect(repo.queries.last['page'], 1);

    List<Object?> pages() =>
        repo.queries.map((q) => q['page']).toList();
    for (var i = 0; i < 8 && !pages().contains(2); i++) {
      await tester.fling(
          find.byType(GridView), const Offset(0, -3000), 2000);
      await tester.pumpAndSettle();
    }
    expect(pages().where((p) => p == 2), hasLength(1));
    expect(find.text('25 items'), findsOneWidget);

    // The short terminal page stops the chain: never a page 3.
    for (var i = 0; i < 4; i++) {
      await tester.fling(
          find.byType(GridView), const Offset(0, -3000), 2000);
      await tester.pumpAndSettle();
    }
    expect(pages().any((p) => p == 3), isFalse);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {    final repo = _FakeCatalogRepo()..failProducts = true;
    await _pumpBrowse(tester, repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.failProducts = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Item 1A'), findsOneWidget);
  });
}