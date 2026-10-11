import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/address_card.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/address_model.dart';
import '../../addresses/presentation/address_form_sheet.dart';
import '../../cart/presentation/cart_controller.dart';
import 'checkout_controller.dart';

const _days = ['Today', 'Tomorrow'];
const _windows = ['9 AM – 12 PM', '12 – 3 PM', '3 – 6 PM', '6 – 9 PM'];

/// S9 · Checkout (`/checkout`, auth): steps header → address list (+ shared
/// add/edit sheet) → local slot picker → COD/UPI rows → server bill →
/// bottom CTA with double-tap guard. Order first, payment second (COD skips
/// payment); success clears the cart and lands on `/order/:id`.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutControllerProvider);

    ref.listen(checkoutControllerProvider, (_, next) {
      final err = next.placeError;
      if (err != null) {
        showAppSnackbar(context,
            err is ApiException ? err.message : err.toString());
      }
    });

    return Scaffold(
      appBar: EasyGetAppBar(
        showBack: true,
        onBack: () => context.pop(),
        title: 'Checkout',
      ),
      body: _Body(state: state),
      bottomNavigationBar:
          state.cartLoading || state.cart == null || state.cart!.items.isEmpty
              ? null
              : const _PlaceBar(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.addressesLoading || state.cartLoading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpace.lg),
          child: Column(
            children: [
              SkeletonLine(),
              SizedBox(height: AppSpace.sm),
              SkeletonLine(),
              SizedBox(height: AppSpace.sm),
              SkeletonLine(width: 200),
            ],
          ),
        ),
      );
    }
    if (state.addressesError != null) {
      return ErrorState(
        body: 'We could not load your addresses.',
        onRetry: () =>
            ref.read(checkoutControllerProvider.notifier).refresh(),
      );
    }
    if (state.cartError != null || state.cart == null) {
      return ErrorState(
        body: 'We could not load your cart.',
        onRetry: () =>
            ref.read(checkoutControllerProvider.notifier).refresh(),
      );
    }
    if (state.cart!.items.isEmpty) {
      return EmptyState(
        title: 'Your cart is empty',
        body: 'Add something fresh before checking out.',
        actionLabel: 'Browse products',
        onAction: () => context.go('/browse'),
      );
    }

    final coupon = ref.watch(cartControllerProvider).coupon;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(checkoutControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _StepsHeader(),
            _SectionTitle(
              title: 'Delivery address',
              actionLabel: 'Add new',
              onAction: () => _addAddress(context, ref),
            ),
            if (state.addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg),
                child: OutlinedButton(
                  key: const Key('checkout-add-address'),
                  onPressed: () => _addAddress(context, ref),
                  child: const Text('Add address'),
                ),
              )
            else
              for (final address in state.addresses)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                  child: AddressCard(
                    address: address,
                    selected:
                        address.id == state.selectedAddressId,
                    onSelect: () => ref
                        .read(checkoutControllerProvider.notifier)
                        .selectAddress(address.id),
                    onEdit: () =>
                        _editAddress(context, ref, address),
                  ),
                ),
            _SectionTitle(title: 'Delivery slot'),
            _SlotPicker(state: state),
            _SectionTitle(title: 'Payment'),
            _MethodList(state: state),
            _BillBlock(
                subtotal: state.cart!.subtotal, discount: coupon?.discount ?? 0),
            SizedBox(
                height: AppSpace.xxl +
                    MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final saved = await AddressFormSheet.show(context);
    if (saved != null && context.mounted) {
      final notifier = ref.read(checkoutControllerProvider.notifier);
      await notifier.refresh();
      notifier.selectAddress(saved.id);
    }
  }

  Future<void> _editAddress(
      BuildContext context, WidgetRef ref, Address address) async {
    final saved =
        await AddressFormSheet.show(context, existing: address);
    if (saved != null && context.mounted) {
      await ref.read(checkoutControllerProvider.notifier).refresh();
    }
  }
}

/// Numbered steps header (Address → Slot → Payment). Display only — no
/// stepper theater.
class _StepsHeader extends StatelessWidget {
  const _StepsHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const steps = ['Address', 'Slot', 'Payment'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm),
                  color: scheme.outlineVariant,
                ),
              ),
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: AppTypography.label(scheme.onPrimary,
                          size: 13)),
                ),
                const SizedBox(height: 2),
                Text(steps[i],
                    style: AppTypography.label(scheme.onSurface,
                        size: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
      {required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTypography.productName(scheme.onSurface,
                      size: 17)
                  .copyWith(fontWeight: FontWeight.w700)),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xs),
                child: Text(actionLabel!,
                    style:
                        AppTypography.label(scheme.primary)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Local slot picker: day chips + time-window chips. No backend involved.
class _SlotPicker extends ConsumerWidget {
  const _SlotPicker({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(checkoutControllerProvider.notifier);
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final day in _days) ...[
                AppChip(
                  label: day,
                  selected: state.day == day,
                  onTap: () => notifier.setDay(day),
                ),
                if (day != _days.last)
                  const SizedBox(width: AppSpace.sm),
              ],
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final window in _windows)
                AppChip(
                  key: Key('slot-$window'),
                  label: window,
                  selected: state.window == window,
                  onTap: () => notifier.setWindow(window),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Payment rows: saved UPI methods + always-available COD.
class _MethodList extends ConsumerWidget {
  const _MethodList({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final notifier = ref.read(checkoutControllerProvider.notifier);

    Widget row({
      required Key key,
      required bool selected,
      required String title,
      required String subtitle,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(AppRadii.input),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpace.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(
                color: selected ? scheme.primary : colors.faint,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color:
                      selected ? scheme.primary : colors.faint,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.bodyMedium(
                              scheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTypography.caption(
                              scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final method in state.upiMethods)
          row(
            key: Key('pay-upi-${method.id}'),
            selected: state.method == 'upi' &&
                state.savedMethodId == method.id,
            title: method.label.isEmpty ? 'UPI' : method.label,
            subtitle: (method.upiId ?? '').isEmpty
                ? 'Pay on delivery'
                : method.upiId!,
            onTap: () => notifier.setMethod('upi', method.id),
          ),
        row(
          key: const Key('pay-cod'),
          selected: state.method == 'cod',
          title: 'Cash on delivery',
          subtitle: 'Pay at your door',
          onTap: () => notifier.setMethod('cod'),
        ),
      ],
    );
  }
}

class _BillBlock extends StatelessWidget {
  const _BillBlock({required this.subtotal, required this.discount});

  final double subtotal;
  final double discount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final payable =
        (subtotal - discount).clamp(0, double.infinity).toDouble();
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.lg, AppSpace.lg, 0),
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.faint),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', '₹${_rupees(subtotal)}',
              scheme.onSurface),
          if (discount > 0) ...[
            const SizedBox(height: AppSpace.xs),
            _row(context, 'Coupon', '−₹${_rupees(discount)}',
                colors.success,
                strong: true),
          ],
          const SizedBox(height: AppSpace.xs),
          _row(context, 'Delivery', 'To be confirmed',
              scheme.onSurfaceVariant),
          const Divider(height: AppSpace.lg),
          _row(context, 'Total', '₹${_rupees(payable)}',
              scheme.onSurface,
              strong: true, size: 16),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, Color color,
      {bool strong = false, double size = 14}) {
    final style = strong
        ? AppTypography.tabularPrice(color, size: size)
        : AppTypography.tabularNumber(color, size: size);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.body(
                Theme.of(context).colorScheme.onSurfaceVariant)),
        Text(value, style: style),
      ],
    );
  }
}

class _PlaceBar extends ConsumerWidget {
  const _PlaceBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(checkoutControllerProvider);
    final coupon = ref.watch(cartControllerProvider).coupon;
    final payable = ((state.cart?.subtotal ?? 0) - (coupon?.discount ?? 0))
        .clamp(0, double.infinity)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border:
            Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: FilledButton(
            key: const Key('checkout-place'),
            onPressed: state.placing
                ? null
                : () {
                    unawaited(_place(context, ref));
                  },
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: state.placing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  )
                : Text(
                    'Place order · ₹${_rupees(payable)}',
                    style: AppTypography.label(scheme.onPrimary,
                        size: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _place(BuildContext context, WidgetRef ref) async {
    final order = await ref
        .read(checkoutControllerProvider.notifier)
        .placeOrder();
    if (!context.mounted) return;
    if (order == null) return;
    unawaited(HapticFeedback.mediumImpact());
    showAppSnackbar(context, 'Order placed — thank you!');
    context.go('/order/${order.id}');
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);