import 'package:easyget/core/network/api_exception.dart';
import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/addresses/data/address_repository.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/features/cart/data/coupon_repository.dart';
import 'package:easyget/features/cart/presentation/cart_screen.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/models/address_model.dart';
import 'package:easyget/models/cart_models.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

CartItem _line(int id, int variantId, String name, double price, int qty) =>
    CartItem(
      id: id,
      variantId: variantId,
      variantLabel: name,
      variantName: name,
      price: price,
      quantity: qty,
      lineTotal: price * qty,
    );

class _FakeCartRepo implements CartRepository {
  _FakeCartRepo({this.fail = false});

  bool fail;
  final lines = [
    _line(1, 11, 'Amul Butter 200 g', 199, 2),
    _line(2, 12, 'Whole Wheat Atta 5 kg', 100, 1),
  ];
  final List<String> calls = [];

  static const _names = {
    11: 'Amul Butter 200 g',
    12: 'Whole Wheat Atta 5 kg',
  };
  static const _prices = {11: 199.0, 12: 100.0};

  Cart _cart() => Cart(
        id: 1,
        items: List.of(lines),
        totalItems: lines.fold(0, (a, e) => a + e.quantity),
        subtotal: lines.fold(0.0, (a, e) => a + e.lineTotal),
      );

  @override
  Future<Cart> fetchCart() async {
    if (fail) throw ApiException('Cart is unavailable.');
    return _cart();
  }

  @override
  Future<void> addItem({required int variantId, int quantity = 1}) async {
    calls.add('add $variantId x$quantity');
    final at = lines.indexWhere((e) => e.variantId == variantId);
    if (at >= 0) {
      final line = lines[at];
      lines[at] = _line(line.id, line.variantId, line.variantName, line.price,
          line.quantity + quantity);
    } else {
      lines.add(_line(100 + variantId, variantId,
          _names[variantId] ?? 'Restored', _prices[variantId] ?? 199, quantity));
    }
  }

  @override
  Future<void> updateQty(int itemId, int quantity) async {
    calls.add('update $itemId x$quantity');
    final at = lines.indexWhere((e) => e.id == itemId);
    final line = lines[at];
    lines[at] = _line(
        line.id, line.variantId, line.variantName, line.price, quantity);
  }

  @override
  Future<void> remove(int itemId) async {
    calls.add('remove $itemId');
    lines.removeWhere((e) => e.id == itemId);
  }

  @override
  Future<void> clear() async => lines.clear();
}

class _FakeCouponRepo implements CouponRepository {
  @override
  Future<CouponDiscount> validate(
      {required String code, required double orderValue}) async {
    if (code == 'FRESH10') {
      return const CouponDiscount(code: 'FRESH10', discount: 40);
    }
    throw ApiException('Invalid coupon.');
  }
}

Future<void> _pumpCart(
  WidgetTester tester, {
  required _FakeCartRepo cart,
  String location = '/cart',
  AddressRepository? addresses,
  CatalogRepository? catalog,
}) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
      GoRoute(
        path: '/browse',
        builder: (_, _) =>
            const Scaffold(key: Key('browse-page'), body: Text('BROWSE')),
      ),
      GoRoute(
        path: '/checkout',
        builder: (_, _) => const Scaffold(
            key: Key('checkout-page'), body: Text('CHECKOUT')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(cart),
        couponRepositoryProvider.overrideWithValue(_FakeCouponRepo()),
        if (addresses != null)
          addressRepositoryProvider.overrideWithValue(addresses),
        if (catalog != null)
          catalogRepositoryProvider.overrideWithValue(catalog),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAddressRepo implements AddressRepository {
  @override
  Future<List<Address>> list() async => const [
        Address(
          id: 1,
          label: 'Home',
          line1: '12 MG Road',
          city: 'Bengaluru',
          state: 'KA',
          postalCode: '560001',
          country: 'India',
          phone: '9876543210',
          isDefault: true,
        ),
      ];
  @override
  Future<Address> create(AddressDraft draft) => throw UnimplementedError();
  @override
  Future<Address> update(int id, AddressDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
  @override
  Future<Address> setDefault(int id) => throw UnimplementedError();
}

class _FakeCartCatalog implements CatalogRepository {
  @override
  Future<PincodeInfo> pincode(String code) async => const PincodeInfo(
      valid: true,
      pincode: '560001',
      city: 'Bengaluru',
      state: 'KA',
      etaDays: 2,
      deliveryFee: 30,
      freeDeliveryOver: 499);
  @override
  Future<StorefrontRender> platformStorefront() async =>
      const StorefrontRender(
        store: StoreInfo(id: 1, name: 'EasyGet', slug: 'easyget'),
        theme: StoreTheme(),
        ticker: Ticker(items: ['Free delivery over Rs.499']),
      );
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
  Future<StorefrontRender> storefront(String slug) =>
      throw UnimplementedError();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders lines, server bill and checkout CTA', (tester) async {
    await _pumpCart(tester, cart: _FakeCartRepo());

    expect(find.text('Your cart (3)'), findsOneWidget);
    expect(find.text('Amul Butter 200 g'), findsOneWidget);
    expect(find.text('Whole Wheat Atta 5 kg'), findsOneWidget);
    expect(find.text('₹498'), findsWidgets);
    expect(find.text('Proceed to checkout · ₹498'), findsOneWidget);
  });

  testWidgets('stepper edits hit updateQty', (tester) async {
    final cart = _FakeCartRepo();
    await _pumpCart(tester, cart: cart);

    final stepper = find.descendant(
      of: find.byKey(const Key('product-card')).first,
      matching: find.byKey(const Key('qty-plus')),
    );
    await tester.tap(stepper);
    await tester.pumpAndSettle();

    expect(cart.calls, ['update 1 x3']);
  });

  testWidgets('remove offers Undo and restores the line', (tester) async {
    final cart = _FakeCartRepo();
    await _pumpCart(tester, cart: cart);

    await tester.tap(find.byKey(const Key('line-remove-1')));
    await tester.pumpAndSettle();

    expect(cart.calls, ['remove 1']);
    expect(find.text('Amul Butter 200 g'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(cart.calls, ['remove 1', 'add 11 x2']);
    expect(find.text('Amul Butter 200 g'), findsOneWidget);
  });

  testWidgets('stepper to zero removes with Undo', (tester) async {
    final cart = _FakeCartRepo();
    await _pumpCart(tester, cart: cart);

    final stepper = find.descendant(
      of: find.byKey(const Key('product-card')).at(1),
      matching: find.byKey(const Key('qty-minus')),
    );
    await tester.tap(stepper);
    await tester.pumpAndSettle();

    expect(cart.calls, ['remove 2']);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('valid coupon discounts the bill', (tester) async {
    await _pumpCart(tester, cart: _FakeCartRepo());

    await tester.tap(find.byKey(const Key('coupon-open')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('coupon-field')), 'fresh10');
    await tester.tap(find.byKey(const Key('coupon-apply')));
    await tester.pumpAndSettle();

    expect(find.text('FRESH10 · −₹40'), findsOneWidget);
    expect(find.text('Proceed to checkout · ₹458'), findsOneWidget);

    await tester.tap(find.byKey(const Key('coupon-remove')));
    await tester.pumpAndSettle();
    expect(find.text('Proceed to checkout · ₹498'), findsOneWidget);
  });

  testWidgets('invalid coupon shows the backend message inline',
      (tester) async {
    await _pumpCart(tester, cart: _FakeCartRepo());

    await tester.tap(find.byKey(const Key('coupon-open')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('coupon-field')), 'BAD');
    await tester.tap(find.byKey(const Key('coupon-apply')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid coupon.'), findsOneWidget);
    // Sheet stays open on failure so the shopper can retry.
    expect(find.byKey(const Key('coupon-field')), findsOneWidget);
  });

  testWidgets('empty cart offers Browse', (tester) async {
    final cart = _FakeCartRepo()..lines.clear();
    await _pumpCart(tester, cart: cart);

    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Browse products'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('browse-page')), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final cart = _FakeCartRepo(fail: true);
    await _pumpCart(tester, cart: cart);

    expect(find.text('Something went wrong'), findsOneWidget);
    cart.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Amul Butter 200 g'), findsOneWidget);
  });

  testWidgets('CTA goes to checkout', (tester) async {
    await _pumpCart(tester, cart: _FakeCartRepo());

    await tester.tap(find.byKey(const Key('cart-checkout')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-page')), findsOneWidget);

    // System back must return to the cart (push, never go).
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('cart-checkout')), findsOneWidget);
  });

  testWidgets('ETA pill resolves from the default address', (tester) async {
    await _pumpCart(
      tester,
      cart: _FakeCartRepo(),
      addresses: _FakeAddressRepo(),
      catalog: _FakeCartCatalog(),
    );

    expect(find.byKey(const Key('delivery-eta-pill')), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('trust rows render ticker promises', (tester) async {
    await _pumpCart(
      tester,
      cart: _FakeCartRepo(),
      catalog: _FakeCartCatalog(),
    );

    expect(find.text('Free delivery over Rs.499'), findsOneWidget);
  });
}