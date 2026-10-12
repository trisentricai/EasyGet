import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/addresses/data/address_repository.dart';
import 'package:easyget/features/catalog/data/catalog_repository.dart';
import 'package:easyget/features/delivery/presentation/delivery_eta.dart';
import 'package:easyget/models/address_model.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/pincode_model.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _home = Address(
  id: 1,
  label: 'Home',
  line1: '12 MG Road',
  city: 'Bengaluru',
  state: 'KA',
  postalCode: '560001',
  country: 'India',
  phone: '9876543210',
  isDefault: true,
);

class _FakeAddressRepo implements AddressRepository {
  _FakeAddressRepo({this.rows = const [_home]});
  final List<Address> rows;

  @override
  Future<List<Address>> list() async => List.of(rows);
  @override
  Future<Address> create(AddressDraft draft) => throw UnimplementedError();
  @override
  Future<Address> update(int id, AddressDraft draft) =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
  @override
  Future<Address> setDefault(int id) async => _home;
}

class _FakeCatalogRepo implements CatalogRepository {
  bool validPin = true;

  @override
  Future<PincodeInfo> pincode(String code) async => validPin
      ? const PincodeInfo(
          valid: true,
          pincode: '560001',
          city: 'Bengaluru',
          state: 'KA',
          etaDays: 2,
          deliveryFee: 30,
          freeDeliveryOver: 499)
      : const PincodeInfo(valid: false, pincode: '000000');
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

Future<void> _pumpPill(
  WidgetTester tester, {
  required _FakeAddressRepo addresses,
  required _FakeCatalogRepo catalog,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addressRepositoryProvider.overrideWithValue(addresses),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: DeliveryEtaPill()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shows the pincode ETA for the default address',
      (tester) async {
    await _pumpPill(
        tester,
        addresses: _FakeAddressRepo(),
        catalog: _FakeCatalogRepo());

    expect(find.byKey(const Key('delivery-eta-pill')), findsOneWidget);
    expect(find.text('2 days'), findsOneWidget);
  });

  testWidgets('hides with no address', (tester) async {
    await _pumpPill(
        tester,
        addresses: _FakeAddressRepo(rows: const []),
        catalog: _FakeCatalogRepo());

    expect(find.byKey(const Key('delivery-eta-pill')), findsNothing);
  });

  testWidgets('hides on an unserviceable pincode', (tester) async {
    await _pumpPill(
        tester,
        addresses: _FakeAddressRepo(),
        catalog: _FakeCatalogRepo()..validPin = false);

    expect(find.byKey(const Key('delivery-eta-pill')), findsNothing);
  });
}
