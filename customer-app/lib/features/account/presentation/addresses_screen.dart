import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared_widgets/custom_app_bar.dart';
import '../../account/data/address_repository.dart';
import '../../../models/address.dart';

/// Address Book screen.
class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final addressesState = ref.watch(addressListProvider).state;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.read(addressListProvider.notifier).loadAddresses(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Saved Addresses',
                showSearch: false,
              ),
            ),
            if (addressesState.isLoading)
              SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: colors.primary)),
              )
            else if (addressesState.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: colors.danger),
                        const SizedBox(height: 16),
                        Text('Failed to load addresses',
                            style: AppTypography.bodyMedium(
                                theme.colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        Text(addressesState.error.toString(),
                            style: AppTypography.caption(
                                theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: () =>
                                ref.invalidate(addressListProvider),
                            child: const Text('Retry')),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) {
                    final addresses = addressesState.addresses;
                    if (addresses.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off_outlined,
                                    size: 64, color: colors.faint),
                                const SizedBox(height: 16),
                                Text('No saved addresses',
                                    style: AppTypography.bodyMedium(
                                        theme.colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 8),
                                Text('Add your first delivery address',
                                    style: AppTypography.caption(
                                        theme.colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () => _showAddAddressSheet(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Address'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AddressCard(
                          address: addresses[i],
                          isDefault: addresses[i].isDefault,
                          onTap: () => context.pop(addresses[i]),
                          onEdit: () => _showEditAddressSheet(addresses[i]),
                          onDelete: () => _deleteAddress(addresses[i]),
                          onSetDefault: () => _setDefault(addresses[i]),
                        ),
                        childCount: addresses.length,
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _showAddAddressSheet,
                  icon: const Icon(Icons.add_location),
                  label: const Text('Add New Delivery Address'),
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  void _showAddAddressSheet() {
    _showAddressSheet();
  }

  void _showEditAddressSheet(Address address) {
    _showAddressSheet(address: address);
  }

  void _showAddressSheet({Address? address}) {
    final isEdit = address != null;
    final typeController = TextEditingController(text: address?.type ?? 'Home');
    final labelController = TextEditingController(text: address?.label ?? '');
    final streetController = TextEditingController(text: address?.street ?? '');
    final areaController = TextEditingController(text: address?.area ?? '');
    final pincodeController =
        TextEditingController(text: address?.pincode ?? '');
    final phoneController = TextEditingController(text: address?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
              Text(isEdit ? 'Edit Address' : 'Add New Address',
                  style: AppTypography.screenTitle(
                      Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: typeController.text,
                items: ['Home', 'Work', 'Other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => typeController.text = v ?? 'Home',
                decoration: InputDecoration(
                    labelText: 'Address Type',
                    prefixIcon: const Icon(Icons.home_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                      labelText: 'Label (e.g., Home, Office)',
                      prefixIcon: const Icon(Icons.label_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: streetController,
                  decoration: InputDecoration(
                      labelText: 'House/Flat/Street',
                      prefixIcon: const Icon(Icons.location_on_outlined))),
              const SizedBox(height: 12),
              TextField(
                  controller: areaController,
                  decoration: InputDecoration(
                      labelText: 'Area/Locality',
                      prefixIcon: const Icon(Icons.map_outlined))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: pincodeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Pincode',
                              prefixIcon: const Icon(Icons.pin_outlined)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: const Icon(Icons.phone_outlined)))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: FilledButton(
                          onPressed: () async {
                            final repo = ref.read(addressRepositoryProvider);
                            if (isEdit) {
                              await repo.updateAddress(
                                  id: address.id,
                                  type: typeController.text,
                                  label: labelController.text,
                                  street: streetController.text,
                                  area: areaController.text,
                                  pincode: pincodeController.text,
                                  phone: phoneController.text);
                            } else {
                              await repo.addAddress(
                                  type: typeController.text,
                                  label: labelController.text,
                                  street: streetController.text,
                                  area: areaController.text,
                                  pincode: pincodeController.text,
                                  phone: phoneController.text);
                            }
                            if (!mounted) return;
                            Navigator.pop(context);
                            ref.invalidate(addressListProvider);
                          },
                          child: Text(isEdit ? 'Save' : 'Add'))),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAddress(Address address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Address',
            style: AppTypography.bodyMedium(
                Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to delete this address?',
            style: AppTypography.body(
                Theme.of(context).colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(addressRepositoryProvider).deleteAddress(address.id);
      ref.invalidate(addressListProvider);
    }
  }

  Future<void> _setDefault(Address address) async {
    await ref
        .read(addressRepositoryProvider)
        .updateAddress(id: address.id, isDefault: true);
    ref.invalidate(addressListProvider);
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  final Address address;
  final bool isDefault;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    IconData typeIcon;
    switch (address.type) {
      case 'Home':
        typeIcon = Icons.home_outlined;
        break;
      case 'Work':
        typeIcon = Icons.work_outlined;
        break;
      default:
        typeIcon = Icons.location_on_outlined;
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(address.label,
                                style: AppTypography.productName(
                                    theme.colorScheme.onSurface,
                                    size: 14)),
                            if (isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(999)),
                                child: Text('DEFAULT',
                                    style: AppTypography.tabularSmall(
                                        Colors.white,
                                        size: 9)),
                              ),
                            ],
                          ],
                        ),
                        Text(address.fullAddress,
                            style: AppTypography.caption(
                                theme.colorScheme.onSurfaceVariant)),
                        Text(address.phone,
                            style: AppTypography.tabularSmall(
                                theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (!isDefault)
                    IconButton(
                      onPressed: onSetDefault,
                      icon: Icon(Icons.radio_button_unchecked,
                          color: theme.colorScheme.onSurfaceVariant),
                      tooltip: 'Set as default',
                    )
                  else
                    Icon(Icons.radio_button_checked, color: colors.primary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit')),
                  const SizedBox(width: 8),
                  TextButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outlined,
                          size: 18, color: colors.danger),
                      label: Text('Delete',
                          style: TextStyle(color: colors.danger))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Address list state.
class AddressListState {
  AddressListState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Address> addresses;
  final bool isLoading;
  final String? error;

  AddressListState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
  }) =>
      AddressListState(
        addresses: addresses ?? this.addresses,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Address list notifier.
class _AddressListNotifier extends ChangeNotifier {
  _AddressListNotifier(this._repo) : _state = AddressListState() {
    loadAddresses();
  }

  final AddressRepository _repo;
  AddressListState _state = AddressListState();

  AddressListState get state => _state;

  void _update(AddressListState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadAddresses() async {
    _update(_state.copyWith(isLoading: true, error: null));
    try {
      final addresses = await _repo.getAddresses();
      _update(_state.copyWith(addresses: addresses, isLoading: false));
    } catch (e) {
      _update(_state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}

final addressListProvider = ChangeNotifierProvider<_AddressListNotifier>((ref) {
  return _AddressListNotifier(ref.watch(addressRepositoryProvider));
});
