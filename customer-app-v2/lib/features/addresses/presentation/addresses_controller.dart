import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/address_model.dart';
import '../data/address_repository.dart';

/// S13 · Addresses list state. Tapping a card sets it default (the default
/// flows into the checkout preselect).
class AddressesState {
  const AddressesState({
    this.addresses = const [],
    this.loading = true,
    this.error,
  });

  final List<Address> addresses;
  final bool loading;
  final Object? error;
}

class AddressesController extends Notifier<AddressesState> {
  @override
  AddressesState build() {
    _load();
    return const AddressesState();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(addressRepositoryProvider).list();
      state = AddressesState(addresses: rows, loading: false);
    } catch (e) {
      state = AddressesState(loading: false, error: e);
    }
  }

  Future<void> refresh() => _load();

  Future<void> selectDefault(int id) async {
    await ref.read(addressRepositoryProvider).setDefault(id);
    await _load();
  }

  Future<void> remove(int id) async {
    await ref.read(addressRepositoryProvider).delete(id);
    await _load();
  }
}

final addressesControllerProvider =
    NotifierProvider<AddressesController, AddressesState>(
  AddressesController.new,
);