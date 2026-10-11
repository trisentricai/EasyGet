import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/core/theme/tokens.dart';
import 'package:easyget/core/widgets/address_card.dart';
import 'package:easyget/core/widgets/app_chip.dart';
import 'package:easyget/core/widgets/eta_pill.dart';
import 'package:easyget/core/widgets/order_timeline.dart';
import 'package:easyget/core/widgets/section_header.dart';
import 'package:easyget/core/widgets/skeletons.dart';
import 'package:easyget/core/widgets/snackbar.dart';
import 'package:easyget/core/widgets/states.dart';
import 'package:easyget/core/widgets/status_pill.dart';
import 'package:easyget/features/catalog/presentation/widgets/category_tile.dart';
import 'package:easyget/features/catalog/presentation/widgets/filter_sheet.dart';
import 'package:easyget/features/catalog/presentation/widgets/sort_sheet.dart';
import 'package:easyget/models/address_model.dart';
import 'package:easyget/models/catalog_models.dart';
import 'package:easyget/models/order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('CategoryTile', () {
    testWidgets('shows the image avatar, name and taps through',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(CategoryTile(
        category: const Category(
            id: 1,
            name: 'Dairy',
            slug: 'dairy',
            image: 'https://example.com/dairy.png'),
        onTap: () => taps++,
      )));

      expect(find.byKey(const Key('category-tile-dairy')), findsOneWidget);
      expect(find.text('Dairy'), findsOneWidget);
      await tester.tap(find.byKey(const Key('category-tile-dairy')));
      expect(taps, 1);
    });

    testWidgets('falls back to an icon without an image', (tester) async {
      await tester.pumpWidget(_host(const CategoryTile(
        category: Category(id: 2, name: 'Staples', slug: 'staples'),
      )));

      expect(find.byIcon(Icons.grid_view_outlined), findsOneWidget);
    });
  });

  group('SectionHeader', () {    testWidgets('title left, ghost See all right, never centered',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(SectionHeader(
        title: 'Deals for you',
        onSeeAll: () => taps++,
      )));

      expect(find.text('Deals for you'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      final row = tester.widget<Row>(find.byKey(const Key('section-header')));
      expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);

      await tester.tap(find.text('See all'));
      expect(taps, 1);
    });
  });

  group('AppChip', () {
    testWidgets('is at least 44dp, taps, and paints selected with primaryTint',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(AppChip(
        label: 'Dairy',
        onTap: () => taps++,
      )));

      expect(
        tester.getSize(find.byKey(const Key('chip'))).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.byKey(const Key('chip')));
      expect(taps, 1);

      await tester.pumpWidget(_host(AppChip(
        label: 'Dairy',
        selected: true,
        onTap: () {},
      )));
      final deco = tester
          .widget<AnimatedContainer>(find.byKey(const Key('chip')))
          .decoration as BoxDecoration;
      expect(deco.color, AppColors.primaryTint);
    });
  });

  group('Skeletons', () {
    testWidgets('grid + rail render pulsing skeleton lines', (tester) async {
      await tester.pumpWidget(_host(const SkeletonGrid(count: 4)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SkeletonLine), findsWidgets);

      await tester.pumpWidget(_host(const SkeletonRail(count: 3)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('skeleton-rail')), findsOneWidget);
      expect(find.byType(SkeletonLine), findsWidgets);
    });
  });

  group('States', () {
    testWidgets('EmptyState shows icon, title, body and a primary CTA',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(EmptyState(
        title: 'No products yet',
        body: 'Try another category.',
        actionLabel: 'Browse',
        onAction: () => taps++,
      )));

      expect(find.text('No products yet'), findsOneWidget);
      expect(find.text('Try another category.'), findsOneWidget);
      await tester.tap(find.text('Browse'));
      expect(taps, 1);
    });

    testWidgets('ErrorState offers a Retry action', (tester) async {
      var retries = 0;
      await tester.pumpWidget(_host(ErrorState(
        body: 'We could not load this.',
        onRetry: () => retries++,
      )));

      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('OfflineState labels itself "You\'re offline"', (tester) async {
      await tester.pumpWidget(_host(OfflineState(onAction: () {})));
      expect(find.text("You're offline"), findsOneWidget);
    });
  });

  group('StatusPill + EtaPill', () {
    BoxDecoration deco(WidgetTester tester) => tester
        .widget<Container>(find.byKey(const Key('status-pill')))
        .decoration as BoxDecoration;

    testWidgets('transit = marigold wash', (tester) async {
      await tester.pumpWidget(_host(const StatusPill(status: 'OUT_FOR_DELIVERY')));
      expect(find.text('Out for delivery'), findsOneWidget);
      expect(deco(tester).color, AppColors.marigoldWash);
    });

    testWidgets('delivered = success, cancelled = muted', (tester) async {
      await tester.pumpWidget(_host(const StatusPill(status: 'DELIVERED')));
      expect(find.text('Delivered'), findsOneWidget);
      expect(deco(tester).color, AppColors.success);

      await tester.pumpWidget(_host(const StatusPill(status: 'CANCELLED')));
      expect(deco(tester).color, AppColors.lightSunken);
    });

    testWidgets('EtaPill shows a timer + tabular minutes', (tester) async {
      await tester.pumpWidget(_host(const EtaPill(minutes: 12)));
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);
    });
  });

  group('FilterSheet', () {
    testWidgets('rows are switches, Apply shows live count, Clear resets',
        (tester) async {
      Set<String>? applied;
      await tester.pumpWidget(_host(FilterSheet(
        filters: const [
          FilterToggle(id: 'featured', label: 'Featured'),
          FilterToggle(id: 'instock', label: 'In stock', value: true),
        ],
        resultCount: 42,
        onApply: (ids) => applied = ids,
      )));

      expect(find.byType(Switch), findsNWidgets(2));
      expect(find.byType(Checkbox), findsNothing);
      expect(find.text('Show 42'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<Switch>(find.byType(Switch)).every((s) => !s.value),
        isTrue,
      );

      await tester.tap(find.text('Featured'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show 42'));
      await tester.pumpAndSettle();
      expect(applied, {'featured'});
    });
  });

  group('SortSheet', () {
    testWidgets('selecting an option returns its id', (tester) async {
      String? picked;
      await tester.pumpWidget(_host(SortSheet(
        options: const [
          SortOption(id: 'relevance', label: 'Relevance'),
          SortOption(id: 'price_asc', label: 'Price: Low to High'),
        ],
        selectedId: 'relevance',
        onSelect: (id) => picked = id,
      )));

      await tester.tap(find.text('Price: Low to High'));
      await tester.pumpAndSettle();
      expect(picked, 'price_asc');
    });
  });

  group('AddressCard', () {
    const address = Address(
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

    testWidgets('shows label chip, default badge, tabular phone and delete',
        (tester) async {
      var selected = 0;
      var deleted = 0;
      await tester.pumpWidget(_host(AddressCard(
        address: address,
        selected: true,
        onSelect: () => selected++,
        onDelete: () => deleted++,
      )));

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.textContaining('12 MG Road'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      await tester.tap(find.byKey(const Key('address-delete-1')));
      expect(deleted, 1);

      await tester.tap(find.byKey(const Key('address-card-1')));
      expect(selected, 1);
    });
  });

  group('OrderTimeline', () {
    final events = [
      OrderStatusEvent(from: '', to: 'PENDING'),
      OrderStatusEvent(from: 'PENDING', to: 'CONFIRMED'),
      OrderStatusEvent(from: 'CONFIRMED', to: 'OUT_FOR_DELIVERY'),
    ];

    testWidgets('renders nodes vertically with the current node primary',
        (tester) async {
      await tester.pumpWidget(_host(OrderTimeline(events: events)));

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Out for delivery'), findsOneWidget);
      final node = tester
          .widget<Container>(find.byKey(const Key('timeline-node-2')))
          .decoration as BoxDecoration;
      expect(node.color, AppColors.primary);
    });

    testWidgets('cancelled current node is muted', (tester) async {
      await tester.pumpWidget(_host(OrderTimeline(events: const [
        OrderStatusEvent(from: 'CONFIRMED', to: 'CANCELLED'),
      ])));

      final node = tester
          .widget<Container>(find.byKey(const Key('timeline-node-0')))
          .decoration as BoxDecoration;
      expect(node.color, AppColors.lightFaint);
    });
  });

  group('showAppSnackbar', () {
    testWidgets('floats a message with an optional action', (tester) async {
      var actioned = 0;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showAppSnackbar(
              context,
              'Added to cart',
              actionLabel: 'View',
              onAction: () => actioned++,
            ),
            child: const Text('go'),
          ),
        ),
      )));

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('Added to cart'), findsOneWidget);
      await tester.tap(find.text('View'));
      expect(actioned, 1);
    });
  });
}