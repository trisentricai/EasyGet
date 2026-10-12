import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/catalog/presentation/widgets/price_block.dart';
import 'package:easyget/features/catalog/presentation/widgets/product_card.dart';
import 'package:easyget/features/catalog/presentation/widgets/qty_stepper.dart';
import 'package:easyget/features/catalog/presentation/widgets/rating_pill.dart';
import 'package:easyget/features/catalog/presentation/widgets/variant_sheet.dart';
import 'package:easyget/features/wishlist/data/wishlist_repository.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _host(Widget child, {WishlistRepository? wishlist}) => ProviderScope(
      overrides: [
        // Hearts must never touch the network in widget tests: default to a
        // no-op fake, pass a configured one to drive toggle scenarios.
        wishlistRepositoryProvider.overrideWithValue(
            wishlist ?? _FakeWishlistRepo()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    );

class _FakeWishlistRepo implements WishlistRepository {
  final hearts = <String>{};
  final List<Map<String, Object?>> toggles = [];
  bool fail = false;

  @override
  Future<List<String>> fetch() async => hearts.toList();

  @override
  Future<List<CatalogProduct>> fetchProducts() async => const [];

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

const _butter = CatalogProduct(
  id: 1,
  name: 'Amul Butter',
  slug: 'amul-butter',
  brand: 'Amul',
  mrp: 349,
  basePrice: 289,
  discountPercent: 17,
  ratingAvg: 4.3,
  ratingCount: 212,
  primaryImage: 'https://example.com/butter.jpg',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('PriceBlock', () {
    testWidgets('shows tabular price, struck MRP and a real save line',
        (tester) async {
      await tester.pumpWidget(
        _host(const PriceBlock(price: 289, mrp: 349)),
      );

      final price = tester.widget<Text>(find.text('₹289'));
      expect(price.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(find.text('₹349'), findsOneWidget);
      expect(find.text('Save ₹60 · 17% off'), findsOneWidget);
      expect(find.text('SALE'), findsNothing);
    });

    testWidgets('mrp equal to price hides MRP and save line', (tester) async {
      await tester.pumpWidget(_host(const PriceBlock(price: 289, mrp: 289)));

      expect(find.text('₹289'), findsOneWidget);
      expect(find.text('₹349'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });
  });

  group('RatingPill', () {
    testWidgets('renders marigold star + tabular rating + muted count '
        'and taps through', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(RatingPill(rating: 4.3, count: 212, onTap: () => taps++)),
      );

      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.text('4.3'), findsOneWidget);
      expect(find.text('(212)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('rating-pill')));
      expect(taps, 1);
    });
  });

  group('QtyStepper', () {
    testWidgets('morphs Add → − 1 + → caps at maxQty → back to Add',
        (tester) async {
      final changed = <int>[];
      await tester.pumpWidget(
        _host(QtyStepper(quantity: 0, maxQty: 5, onChanged: changed.add)),
      );

      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.byKey(const Key('qty-add')));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(changed, [1]);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('qty-plus')));
        await tester.pumpAndSettle();
      }
      expect(find.text('5'), findsOneWidget);
      expect(find.byTooltip('Only 5 available'), findsOneWidget);
      expect(changed.last, 5);

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('qty-minus')));
        await tester.pumpAndSettle();
      }
      expect(find.text('Add'), findsOneWidget);
    });
  });

  group('ProductCard', () {
    testWidgets('grid card lays out image, name, line, price and Add system',
        (tester) async {
      await tester.pumpWidget(_host(const ProductCard(
        product: _butter,
        density: ProductDensity.grid,
        width: 180,
      )));

      expect(find.byKey(const Key('product-image')), findsOneWidget);
      expect(find.text('Amul Butter'), findsOneWidget);
      expect(find.text('Amul'), findsOneWidget);
      expect(find.text('₹289'), findsOneWidget);
      expect(find.byKey(const Key('qty-add')), findsOneWidget);
      expect(find.byKey(const Key('rating-pill')), findsOneWidget);
      // Obsidian glass discount badge on the image.
      expect(find.text('−17%'), findsOneWidget);
    });

    testWidgets('exposes a semantics label for the product', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const ProductCard(
        product: _butter,
        density: ProductDensity.rail,
        width: 148,
      )));

      expect(
        find.bySemanticsLabel(RegExp('Amul Butter, ₹289')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('taps open the variant sheet only when variants > 1',
        (tester) async {      var opened = 0;
      var pdp = 0;

      await tester.pumpWidget(_host(ProductCard(
        product: _butter,
        density: ProductDensity.grid,
        width: 180,
        variantCount: 3,
        onOpenVariants: () => opened++,
        onTap: () => pdp++,
      )));
      await tester.tap(find.byKey(const Key('product-card')));
      expect(opened, 1);
      expect(pdp, 0);

      await tester.pumpWidget(_host(ProductCard(
        product: _butter,
        density: ProductDensity.grid,
        width: 180,
        onTap: () => pdp++,
      )));
      await tester.tap(find.byKey(const Key('product-card')));
      expect(pdp, 1);
    });

    testWidgets('grid cards measure identically whatever the content',
        (tester) async {
      const short = CatalogProduct(
        id: 1,
        name: 'Milk',
        slug: 'milk',
        mrp: 60,
        basePrice: 60,
      );
      const long = CatalogProduct(
        id: 2,
        name:
            'A very long product name that wraps across two full lines here',
        slug: 'long',
        brand: 'Some Brand With A Long Name',
        mrp: 349,
        basePrice: 289,
        discountPercent: 17,
      );
      await tester.pumpWidget(_host(
        const Row(
          children: [
            ProductCard(
                product: short, density: ProductDensity.grid, width: 180),
            ProductCard(
                product: long, density: ProductDensity.grid, width: 180),
          ],
        ),
      ));

      final shortHeight =
          tester.getSize(find.byKey(const Key('product-card')).at(0)).height;
      final longHeight =
          tester.getSize(find.byKey(const Key('product-card')).at(1)).height;
      expect(shortHeight, longHeight);
    });

    test('gridAspect matches the fixed card anatomy', () {
      // 180px column → 225px image + 180px slots.
      expect(ProductCard.gridAspect(180), closeTo(180 / 405, 0.001));
    });

    testWidgets('card heart toggles the wishlist', (tester) async {
      final wishlist = _FakeWishlistRepo();
      await tester.pumpWidget(_host(
        const ProductCard(
            product: _butter, density: ProductDensity.grid, width: 180),
        wishlist: wishlist,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      await tester.tap(find.byKey(const Key('card-heart-amul-butter')));
      await tester.pumpAndSettle();

      expect(wishlist.toggles.single,
          {'slug': 'amul-butter', 'hearted': false});
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('card heart failure is announced, never silent',
        (tester) async {
      final wishlist = _FakeWishlistRepo()..fail = true;
      await tester.pumpWidget(_host(
        const ProductCard(
            product: _butter, density: ProductDensity.grid, width: 180),
        wishlist: wishlist,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('card-heart-amul-butter')));
      await tester.pumpAndSettle();

      expect(find.text('Could not update your wishlist.'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });

  group('VariantSheet', () {
    const options = [
      VariantOption(id: 1, name: '200 g', price: 199),
      VariantOption(id: 2, name: '500 g', price: 240),
      VariantOption(id: 3, name: '1 kg', price: 289),
    ];

    testWidgets('option rows are 56dp with a checked ring on the selection',
        (tester) async {
      await tester.pumpWidget(_host(const VariantSheet(
        options: options,
        initialIndex: 1,
      )));

      expect(
        tester.getSize(find.byKey(const Key('variant-option-0'))).height,
        56,
      );
      expect(find.byKey(const Key('variant-check-1')), findsOneWidget);
      expect(find.byKey(const Key('variant-check-2')), findsNothing);
      expect(find.text('+₹41'), findsOneWidget);
    });

    testWidgets('footer CTA sums the selected variant price and adds it',
        (tester) async {
      VariantOption? added;
      await tester.pumpWidget(_host(VariantSheet(
        options: options,
        initialIndex: 1,
        onAdd: (o) => added = o,
      )));

      expect(find.text('Add · ₹240'), findsOneWidget);

      await tester.tap(find.byKey(const Key('variant-option-2')));
      await tester.pumpAndSettle();
      expect(find.text('Add · ₹289'), findsOneWidget);

      await tester.tap(find.byKey(const Key('variant-cta')));
      expect(added!.id, 3);
    });
  });
}