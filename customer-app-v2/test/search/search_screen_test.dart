import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/search/data/search_repository.dart';
import 'package:easyget/features/search/presentation/search_screen.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

CatalogProduct _product(int id, String name) => CatalogProduct(
      id: id,
      name: name,
      slug: 'p-$id',
      brand: 'Acme',
      mrp: 140,
      basePrice: 100,
      ratingAvg: 4.1,
      ratingCount: 9,
    );

class _FakeSearchRepo implements SearchRepository {
  final List<String> suggestionCalls = [];
  final List<String> resultCalls = [];
  bool failResults = false;

  @override
  Future<List<String>> suggestions(String query,
      {CancelToken? cancelToken}) async {
    suggestionCalls.add(query);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return ['$query one', '$query two'];
  }

  @override
  Future<CatalogPage> results(String query, {int page = 1}) async {
    resultCalls.add('$query p$page');
    if (failResults) throw Exception('boom');
    if (query == 'zzz') {
      return const CatalogPage(results: [], total: 0, page: 1);
    }
    if (query == 'big') {
      const total = 45;
      const size = 20;
      final start = (page - 1) * size;
      final count = (total - start).clamp(0, size);
      return CatalogPage(
        results: [
          for (var i = 0; i < count; i++)
            _product(100 + start + i, 'Big ${start + i + 1}'),
        ],
        total: total,
        page: page,
        pageSize: size,
      );
    }
    return CatalogPage(
      results: [_product(1, '$query Item'), _product(2, '$query Other')],
      total: 2,
      page: 1,
      pageSize: 10,
    );
  }
}

class _FakeCatalogRepo implements CatalogRepository {
  @override
  Future<List<Category>> categories() async => const [
        Category(id: 1, name: 'Cat 1', slug: 'cat-1'),
        Category(id: 2, name: 'Cat 2', slug: 'cat-2'),
      ];
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
  Future<StorefrontRender> platformStorefront() =>
      throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester, {
  required _FakeSearchRepo searchRepo,
  List<String> seedHistory = const [],
  List<CatalogProduct> seedViews = const [],
  String location = '/search',
}) async {
  final container = ProviderContainer(overrides: [
    searchRepositoryProvider.overrideWithValue(searchRepo),
    catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepo()),
  ]);
  addTearDown(container.dispose);
  for (final term in seedHistory) {
    container.read(searchHistoryProvider.notifier).add(term);
  }
  for (final product in seedViews) {
    container.read(recentlyViewedProvider.notifier).viewed(product);
  }

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
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
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('empty shows recents, category shortcuts and views rail',
      (tester) async {
    await _pumpSearch(
      tester,
      searchRepo: _FakeSearchRepo(),
      seedHistory: const ['atta'],
      seedViews: [_product(9, 'Viewed Ghee')],
    );

    expect(find.text('atta'), findsOneWidget);
    expect(find.text('Cat 1'), findsOneWidget);
    expect(find.text('Recently viewed'), findsOneWidget);
    expect(find.text('Viewed Ghee'), findsOneWidget);
  });

  testWidgets('category shortcut goes to browse', (tester) async {
    await _pumpSearch(tester, searchRepo: _FakeSearchRepo());

    // Trendy 2-column image grid (not chips, not rows).
    final grid = tester.widget<GridView>(
        find.byKey(const Key('search-category-grid')));
    expect(
        (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2);
    expect(find.byKey(const Key('category-grid-cat-1')), findsOneWidget);

    await tester.tap(find.text('Cat 2'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browse-page')), findsOneWidget);
  });

  testWidgets('typing debounces 300ms and shows suggestions', (tester) async {
    final repo = _FakeSearchRepo();
    await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'ap');
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.suggestionCalls, isEmpty);

    await tester.enterText(find.byKey(const Key('search-field')), 'app');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.suggestionCalls, ['app']);
    expect(find.text('app one'), findsOneWidget);
  });

  testWidgets('short queries never hit the network', (tester) async {
    final repo = _FakeSearchRepo();
    await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'a');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.suggestionCalls, isEmpty);
  });

  testWidgets('suggestion tap submits and shows the grid', (tester) async {
    final repo = _FakeSearchRepo();
    await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'app');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('app one'));
    await tester.pumpAndSettle();

    expect(repo.resultCalls, ['app one p1']);
    expect(find.text('2 results'), findsOneWidget);
    expect(find.text('app one Item'), findsOneWidget);
  });

  testWidgets('keyboard submit runs results and records history',
      (tester) async {
    final repo = _FakeSearchRepo();
    final container =
        await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'atta');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(repo.resultCalls, ['atta p1']);
    expect(find.text('atta Item'), findsOneWidget);
    expect(container.read(searchHistoryProvider), ['atta']);
  });

  testWidgets('result card tap opens the PDP', (tester) async {
    await _pumpSearch(tester, searchRepo: _FakeSearchRepo());

    await tester.enterText(find.byKey(const Key('search-field')), 'atta');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('atta Item'),
      500,
      scrollable: find.descendant(
        of: find.byType(GridView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('atta Item'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-page')), findsOneWidget);
  });

  testWidgets('empty results offer Clear search', (tester) async {    await _pumpSearch(tester, searchRepo: _FakeSearchRepo());

    await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Clear search'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeSearchRepo()..failResults = true;
    await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'atta');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.failResults = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('atta Item'), findsOneWidget);
  });

  testWidgets('show-more pages to the end with progress + end marker',
      (tester) async {
    final repo = _FakeSearchRepo();
    await _pumpSearch(tester, searchRepo: repo);

    await tester.enterText(find.byKey(const Key('search-field')), 'big');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Big 1'), findsOneWidget);
    expect(find.text('Show more · 20 of 45'), findsOneWidget);

    await tester.tap(find.text('Show more · 20 of 45'));
    await tester.pumpAndSettle();
    expect(repo.resultCalls.last, 'big p2');
    expect(find.text('Show more · 40 of 45'), findsOneWidget);

    await tester.tap(find.text('Show more · 40 of 45'));
    await tester.pumpAndSettle();
    expect(repo.resultCalls.last, 'big p3');
    expect(find.text('Show more · 45 of 45'), findsNothing);
    expect(
        find.text('You have seen all 45 products'), findsOneWidget);
  });
}