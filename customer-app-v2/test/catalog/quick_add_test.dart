import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/catalog/presentation/quick_add.dart';
import 'package:easyget/features/catalog/presentation/widgets/product_card.dart';
import 'package:easyget/models/cart_models.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

ProductDetail _detail(String slug, int variants) => ProductDetail(
      id: 1,
      name: 'Test Product',
      slug: slug,
      brand: 'Acme',
      mrp: 120,
      basePrice: 99,
      variants: [
        for (var i = 0; i < variants; i++)
          Variant(id: 50 + i, name: '${(i + 1) * 100} g', price: 99),
      ],
    );

class _FakeCatalogRepo implements CatalogRepository {
  int variants = 1;

  @override
  Future<ProductDetail> product(String slug) async =>
      _detail(slug, variants);
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
  Future<PincodeInfo> pincode(String code) => throw UnimplementedError();
  @override
  Future<StorefrontRender> platformStorefront() =>
      throw UnimplementedError();
  @override
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

class _FakeCartRepo implements CartRepository {
  final List<String> calls = [];
  final lines = <CartItem>[];
  int _nextId = 1;

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
          price: 99,
          quantity: quantity,
          lineTotal: 99.0 * quantity));
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

const _cardProduct = CatalogProduct(
  id: 1,
  name: 'Test Product',
  slug: 'test-product',
  brand: 'Acme',
  mrp: 120,
  basePrice: 99,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('resolveQuickAdd', () {
    test('no variants is unavailable', () async {
      final repo = _FakeCatalogRepo()..variants = 0;
      final outcome = await resolveQuickAdd(repo, 'x');

      expect(outcome.kind, QuickAddKind.unavailable);
    });

    test('one variant adds directly', () async {
      final repo = _FakeCatalogRepo()..variants = 1;
      final outcome = await resolveQuickAdd(repo, 'x');

      expect(outcome.kind, QuickAddKind.added);
      expect(outcome.variantId, 50);
    });

    test('many variants ask to pick', () async {
      final repo = _FakeCatalogRepo()..variants = 3;
      final outcome = await resolveQuickAdd(repo, 'x');

      expect(outcome.kind, QuickAddKind.pick);
      expect(outcome.options, hasLength(3));
    });
  });

  group('card pipeline', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required _FakeCatalogRepo catalog,
      required _FakeCartRepo cart,
    }) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: Center(
                child: ProductCard(
                  product: _cardProduct,
                  density: ProductDensity.grid,
                  width: 180,
                  onQuickAdd: () =>
                      quickAddFromCard(context, _cardProduct),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/cart',
            builder: (_, _) => const Scaffold(
                key: Key('cart-page'), body: Text('CART')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            catalogRepositoryProvider.overrideWithValue(catalog),
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

    testWidgets('single variant adds + confirms with View cart',
        (tester) async {
      final cart = _FakeCartRepo();
      await pumpCard(
          tester,
          catalog: _FakeCatalogRepo()..variants = 1,
          cart: cart);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(cart.calls, ['add 50 x1']);
      expect(find.text('Added 1 × Test Product (₹99)'), findsOneWidget);

      await tester.tap(find.text('View cart'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cart-page')), findsOneWidget);
    });

    testWidgets('many variants open the sheet first', (tester) async {
      final cart = _FakeCartRepo();
      await pumpCard(
          tester,
          catalog: _FakeCatalogRepo()..variants = 3,
          cart: cart);

      // NOTE: no settle here — the pill spinner runs (correctly, invisibly)
      // behind the open sheet until a choice is made.
      await tester.tap(find.text('Add'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Choose a size'), findsOneWidget);
      expect(cart.calls, isEmpty);

      await tester.tap(find.byKey(const Key('variant-option-0')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('variant-cta')));
      await tester.pumpAndSettle();

      expect(cart.calls, ['add 50 x1']);
      expect(find.textContaining('Added 1 ×'), findsOneWidget);
    });

    testWidgets('no variants announces unavailability', (tester) async {
      await pumpCard(
          tester,
          catalog: _FakeCatalogRepo()..variants = 0,
          cart: _FakeCartRepo());

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('Unavailable right now.'), findsOneWidget);
    });

    testWidgets('card shows the explicit added state after a quick-add',
        (tester) async {
      final cart = _FakeCartRepo();
      await pumpCard(
          tester,
          catalog: _FakeCatalogRepo()..variants = 1,
          cart: cart);

      // Plain Add pill up front (no added bar yet).
      expect(find.text('Add'), findsOneWidget);
      expect(find.byKey(const Key('qty-plus')), findsNothing);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Mapped + seeded: the card mirrors the server qty with an explicit
      // "✓ N added" bar and a badge over the image.
      expect(find.text('✓ 1 added'), findsOneWidget);
      expect(find.text('✓ 1 in cart'), findsOneWidget);

      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pumpAndSettle();
      expect(cart.calls, ['add 50 x1', 'add 50 x1']);
      expect(find.text('✓ 2 added'), findsOneWidget);
      expect(find.text('✓ 2 in cart'), findsOneWidget);

      await tester.tap(find.byKey(const Key('qty-minus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qty-minus')));
      await tester.pumpAndSettle();
      expect(find.text('Add'), findsOneWidget);
      expect(find.textContaining('in cart'), findsNothing);
    });

    testWidgets('added state reads "N added" with an Add-more affordance',
        (tester) async {
      final cart = _FakeCartRepo();
      await pumpCard(
          tester,
          catalog: _FakeCatalogRepo()..variants = 1,
          cart: cart);

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Professional added state: explicit "✓ N added" (not a bare number)
      // plus an "Add more" affordance on the increment control.
      expect(find.text('✓ 1 added'), findsOneWidget);
      expect(find.byTooltip('Add more'), findsOneWidget);

      await tester.tap(find.byKey(const Key('qty-plus')));
      await tester.pumpAndSettle();
      expect(find.text('✓ 2 added'), findsOneWidget);

      await tester.tap(find.byKey(const Key('qty-minus')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qty-minus')));
      await tester.pumpAndSettle();
      expect(find.text('Add'), findsOneWidget);
    });
  });
}