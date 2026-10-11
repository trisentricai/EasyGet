import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/features/addresses/data/address_repository.dart';
import 'package:easyget/features/addresses/data/place_autocomplete.dart';
import 'package:easyget/features/addresses/presentation/addresses_screen.dart';
import 'package:easyget/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
const _work = Address(
  id: 2,
  label: 'Work',
  line1: '99 Residency Rd',
  city: 'Bengaluru',
  state: 'KA',
  postalCode: '560025',
  country: 'India',
  phone: '9123456780',
);

class _FakeAddressRepo implements AddressRepository {
  _FakeAddressRepo({this.fail = false});

  bool fail;
  final rows = [_home, _work];
  final List<AddressDraft> created = [];
  final List<int> updated = [];
  final List<int> deleted = [];
  final List<int> defaulted = [];

  @override
  Future<List<Address>> list() async {
    if (fail) throw Exception('boom');
    return List.of(rows);
  }

  @override
  Future<Address> create(AddressDraft draft) async {
    created.add(draft);
    final saved = Address(
      id: 3,
      label: draft.label,
      line1: draft.line1,
      line2: draft.line2 ?? '',
      city: draft.city,
      state: draft.state,
      postalCode: draft.postalCode,
      country: draft.country,
      phone: draft.phone,
    );
    rows.add(saved);
    return saved;
  }

  @override
  Future<Address> update(int id, AddressDraft draft) async {
    updated.add(id);
    return _home;
  }

  @override
  Future<void> delete(int id) async {
    deleted.add(id);
    rows.removeWhere((a) => a.id == id);
  }

  @override
  Future<Address> setDefault(int id) async {
    defaulted.add(id);
    for (var i = 0; i < rows.length; i++) {
      final a = rows[i];
      rows[i] = Address(
        id: a.id,
        label: a.label,
        line1: a.line1,
        line2: a.line2,
        city: a.city,
        state: a.state,
        postalCode: a.postalCode,
        country: a.country,
        phone: a.phone,
        isDefault: a.id == id,
      );
    }
    return rows.firstWhere((a) => a.id == id);
  }
}

Future<void> _pumpAddresses(
  WidgetTester tester, {
  required _FakeAddressRepo repo,
  PlaceAutocompleteService? places,
}) async {
  final router = GoRouter(
    initialLocation: '/addresses',
    routes: [
      GoRoute(
          path: '/addresses',
          builder: (_, _) => const AddressesScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addressRepositoryProvider.overrideWithValue(repo),
        if (places != null)
          placeAutocompleteProvider.overrideWithValue(places),
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

  testWidgets('renders the radio list with the default badge', (tester) async {
    await _pumpAddresses(tester, repo: _FakeAddressRepo());

    expect(find.byKey(const Key('address-card-1')), findsOneWidget);
    expect(find.byKey(const Key('address-card-2')), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.textContaining('12 MG Road'), findsOneWidget);
    expect(find.textContaining('99 Residency Rd'), findsOneWidget);
  });

  testWidgets('tapping a card sets it default', (tester) async {
    final repo = _FakeAddressRepo();
    await _pumpAddresses(tester, repo: repo);

    await tester.tap(find.byKey(const Key('address-card-2')));
    await tester.pumpAndSettle();

    expect(repo.defaulted, [2]);
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('add sheet creates and lists', (tester) async {
    final repo = _FakeAddressRepo();
    await _pumpAddresses(tester, repo: repo);

    await tester.tap(find.byKey(const Key('addresses-add')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('addr-line1')), '5 Lake View');
    await tester.enterText(find.byKey(const Key('addr-city')), 'Bengaluru');
    await tester.enterText(find.byKey(const Key('addr-state')), 'KA');
    await tester.enterText(find.byKey(const Key('addr-postal')), '560002');
    await tester.enterText(find.byKey(const Key('addr-phone')), '9000000001');
    await tester.tap(find.byKey(const Key('addr-save')));
    await tester.pumpAndSettle();

    expect(repo.created.single.line1, '5 Lake View');
    expect(find.textContaining('5 Lake View'), findsOneWidget);
  });

  testWidgets('edit sheet updates', (tester) async {
    final repo = _FakeAddressRepo();
    await _pumpAddresses(tester, repo: repo);

    await tester.tap(find.byKey(const Key('address-edit-1')));
    await tester.pumpAndSettle();

    expect(
        tester
            .widget<TextField>(find.byKey(const Key('addr-line1')))
            .controller!
            .text,
        '12 MG Road');
    await tester.enterText(
        find.byKey(const Key('addr-line1')), '14 MG Road');
    await tester.tap(find.byKey(const Key('addr-save')));
    await tester.pumpAndSettle();

    expect(repo.updated, [1]);
  });

  testWidgets('delete asks first, then deletes', (tester) async {
    final repo = _FakeAddressRepo();
    await _pumpAddresses(tester, repo: repo);

    await tester.tap(find.byKey(const Key('address-delete-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('address-delete-confirm')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('address-delete-confirm')));
    await tester.pumpAndSettle();

    expect(repo.deleted, [2]);
    expect(find.textContaining('99 Residency Rd'), findsNothing);
  });

  testWidgets('empty shows EmptyState', (tester) async {
    final repo = _FakeAddressRepo()..rows.clear();
    await _pumpAddresses(tester, repo: repo);

    expect(find.text('No addresses yet'), findsOneWidget);
  });

  testWidgets('failure shows ErrorState with a working Retry', (tester) async {
    final repo = _FakeAddressRepo(fail: true);
    await _pumpAddresses(tester, repo: repo);

    expect(find.text('Something went wrong'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('12 MG Road'), findsOneWidget);
  });

  testWidgets('cards align to gutters with centered rows', (tester) async {
    await _pumpAddresses(tester, repo: _FakeAddressRepo());

    final card = tester.getRect(find.byKey(const Key('address-card-1')));
    expect(card.left, 16);
    expect(800 - card.right, 16);

    final radio =
        tester.getCenter(find.byIcon(Icons.radio_button_checked));
    final chip = tester.getCenter(find.text('Home'));
    expect((radio.dy - chip.dy).abs(), lessThanOrEqualTo(2));
  });

  testWidgets('manual mode hides the places search box', (tester) async {
    await _pumpAddresses(tester, repo: _FakeAddressRepo());

    await tester.tap(find.byKey(const Key('addresses-add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addr-search')), findsNothing);
    expect(find.byKey(const Key('addr-line1')), findsOneWidget);
  });

  testWidgets('picking a prediction fills the fields', (tester) async {
    await _pumpAddresses(
      tester,
      repo: _FakeAddressRepo(),
      places: _FakePlaces(),
    );

    await tester.tap(find.byKey(const Key('addresses-add')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('addr-search')), '12 MG Road');
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('12 MG Road, Bengaluru'), findsOneWidget);
    await tester.tap(find.byKey(const Key('addr-prediction-0')));
    await tester.pumpAndSettle();

    TextField field(Key key) =>
        tester.widget<TextField>(find.byKey(key));
    expect(field(const Key('addr-line1')).controller!.text, '12 MG Road');
    expect(field(const Key('addr-city')).controller!.text, 'Bengaluru');
    expect(field(const Key('addr-state')).controller!.text, 'Karnataka');
    expect(field(const Key('addr-postal')).controller!.text, '560001');
  });
}

class _FakePlaces implements PlaceAutocompleteService {
  final List<String> queries = [];

  @override
  Future<List<PlacePrediction>> autocomplete(String input) async {
    queries.add(input);
    return const [
      PlacePrediction(
          placeId: 'p1', description: '12 MG Road, Bengaluru'),
    ];
  }

  @override
  Future<PlaceDetails?> details(String placeId) async => const PlaceDetails(
        line1: '12 MG Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        postalCode: '560001',
      );
}