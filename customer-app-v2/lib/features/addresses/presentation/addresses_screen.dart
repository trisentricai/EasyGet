import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/address_card.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/address_model.dart';
import 'addresses_controller.dart';
import 'address_form_sheet.dart';

/// S13 · Addresses (`/addresses`, auth): radio list of AddressCards (tap =
/// set default) → default badge → shared add/edit sheet → delete behind a
/// danger confirm.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addressesControllerProvider);

    return Scaffold(
      appBar: EasyGetAppBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'Addresses',
      ),
      body: _Body(state: state),
      bottomNavigationBar: state.loading || state.error != null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('addresses-add'),
                    onPressed: () => _addAddress(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add address'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadii.button),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final saved = await AddressFormSheet.show(context);
    if (saved != null && context.mounted) {
      await ref.read(addressesControllerProvider.notifier).refresh();
      if (context.mounted) showAppSnackbar(context, 'Address saved.');
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final AddressesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              SkeletonLine(height: 96, radius: AppRadii.card),
              SizedBox(height: AppSpace.sm),
              SkeletonLine(height: 96, radius: AppRadii.card),
            ],
          ),
        ),
      );
    }
    if (state.error != null) {
      return ErrorState(
        body: 'We could not load your addresses.',
        onRetry: () =>
            ref.read(addressesControllerProvider.notifier).refresh(),
      );
    }
    if (state.addresses.isEmpty) {
      return const EmptyState(
        title: 'No addresses yet',
        body: 'Add one so checkout takes seconds.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(addressesControllerProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md,
            AppSpace.lg, AppSpace.xxl),
        itemCount: state.addresses.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppSpace.sm),
        itemBuilder: (_, i) {
          final address = state.addresses[i];
          return AddressCard(
            address: address,
            selected: address.isDefault,
            onSelect: () => ref
                .read(addressesControllerProvider.notifier)
                .selectDefault(address.id),
            onEdit: () => _editAddress(context, ref, address),
            onDelete: () => _confirmDelete(context, ref, address),
          );
        },
      ),
    );
  }

  Future<void> _editAddress(
      BuildContext context, WidgetRef ref, Address address) async {
    final saved =
        await AddressFormSheet.show(context, existing: address);
    if (saved != null && context.mounted) {
      await ref.read(addressesControllerProvider.notifier).refresh();
      if (context.mounted) showAppSnackbar(context, 'Address updated.');
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Address address) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Delete this address?',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.xs),
              Text(address.singleLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                      scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.lg),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const Key('address-delete-confirm'),
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text('Delete'),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(false),
                child: const Text('Keep it'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(addressesControllerProvider.notifier)
          .remove(address.id);
      if (context.mounted) {
        showAppSnackbar(context, 'Address deleted.');
      }
    }
  }
}