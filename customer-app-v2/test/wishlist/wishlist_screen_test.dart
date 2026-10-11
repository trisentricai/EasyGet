import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/wishlist/data/wishlist_repository.dart';
import 'package:easyget/features/wishlist/presentation/wishlist_screen.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _saved = CatalogProduct(
  id: 1,
  name: 'Saved Butter',
  slug: 'saved-butter',
  brand: 'Amul',
  mrp: 120,
  basePrice: 99,
  ratingAvg: 4.5,
  ratingCount: 30,
);

class _FakeWishlistRepo implements WishlistRepository {
  _FakeWishlistRepo({this.fail = false, Set<String>? hearts})
      : hearts = hearts ?? {};

  bool fail;
  final Set<String> hearts;
  final List<Map<String, Object?>> toggles = [];

  @override
  Future<List<String>> fetch() async {
    if (fail) throw Exception('boom');
    return hearts.toList();
  }

  @override
  Future<List<CatalogProduct>> fetchProducts() async {
    if (fail) throw Exception('boom');
    return hearts.contains('saved-butter') ? const [_saved] : const [];
  }

  @override
  Future<WishlistToggle> toggle(String slug, {bool hearted = false}) async {
    if (fail) throw Exception('boom');
    toggles.add({'slug': slug, 'hearted': hearted});
    if (hearted) {
      hearts.remove(slug);
    } else {
      hearts.add(slug);
    }
    return WishlistToggle(added: !hearted, slug: slug);
  }
}

class _EmptyCatalogRepo implements CatalogRepository {
  @override
  Future<StorefrontRender> platformStorefront() =>
      throw UnimplementedError();
  @override
  Future<List<Category>> categories() async => const [];
  @override
  Future<CatalogPage> products(
          {String? category,
          String? brand,
          double? minPrice,
          double? maxPrice,
          double? minDiscount,
          bool? isFeatured,
          String? sort,
          int? page}) async =>
      const CatalogPage(results: [], total: 0, page: 1);
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

Future<void> _pumpWishlist(
  WidgetTester tester, {
  required _FakeWishlistRepo repo,
}) async {
  final router = GoRouter(
    initialLocation: '/wishlist',
    routes: [
      GoRoute(
          path: '/wishlist',
          builder: (_, _) => const WishlistScreen()),
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
      overrides: [
        wishlistRepositoryProvider.overrideWithValue(repo),
        catalogRepositoryProvider.overrideWithValue(_EmptyCatalogRepo()),
      ],
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

  testWidgets('grid renders saved products', (tester) async {
    await _pumpWishlist(
        tester, repo: _FakeWishlistRepo(hearts: {'saved-butter'}));

    expect(find.text('Saved Butter'), findsOneWidget);
    expect(find.text('₹99'), findsWidgets);
  });

  testWidgets('unheart removes the row; Undo restores it', (tester) async {
    final repo = _FakeWishlistRepo(hearts: {'saved-butter'});
    await _pumpWishlist(tester, repo: repo);

    await tester.tap(find.byKey(const Key('card-heart-saved-butter')));
    await tester.pumpAndSettle();

    expect(repo.toggles.single,
        {'slug': 'saved-butter', 'hearted': true});
    expect(find.text('Saved Butter'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Saved Butter'), findsOneWidget);
  });

  testWidgets('card tap opens the PDP', (tester) async {
    await _pumpWishlist(
        tester, repo: _FakeWishlistRepo(hearts: {'saved-butter'}));

    await tester.tap(find.text('Saved Butter'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-page')), findsOneWidget);
  });

  testWidgets('empty shows EmptyState with Browse CTA', (tester) async {
    await _pumpWishlist(tester, repo: _FakeWishlistRepo());

    expect(find.text('No saved items yet'), findsOneWidget);
    await tester.tap(find.text('Browse products'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browse-page')), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeWishlistRepo(fail: true);
    await _pumpWishlist(tester, repo: repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No saved items yet'), findsOneWidget);
  });
}