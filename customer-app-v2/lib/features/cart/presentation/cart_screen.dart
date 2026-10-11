import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/eta_pill.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/cart_models.dart';
import '../../../models/catalog_models.dart';
import '../../catalog/presentation/widgets/product_card.dart';
import '../../catalog/presentation/widgets/qty_stepper.dart';
import 'cart_controller.dart';

/// S8 · Cart (`/cart`, tab 4): ETA row → coupon row (validate sheet) → line
/// cards (stepper + remove w/ Undo) → server-truth bill → bottom CTA.
/// Owns its Scaffold (AppBar included), like Home.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartControllerProvider);

    ref.listen(cartControllerProvider, (_, next) {
      final notice = next.mutationError;
      if (notice != null && notice.isNotEmpty) {
        showAppSnackbar(context, notice);
        ref.read(cartControllerProvider.notifier).clearNotice();
      }
    });

    return Scaffold(
      appBar: const EasyGetAppBar(title: 'Your cart'),
      body: _Body(state: state),
      bottomNavigationBar:
          state.loading || state.error != null || state.items.isEmpty
              ? null
              : _CheckoutBar(payable: state.payable),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final CartViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading) {
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
    if (state.error != null) {
      return ErrorState(
        body: 'We could not load your cart.',
        onRetry: () =>
            ref.read(cartControllerProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        title: 'Your cart is empty',
        body: 'Add something fresh to get started.',
        actionLabel: 'Browse products',
        onAction: () => context.go('/browse'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(cartControllerProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
              child: EtaPill(minutes: 12),
            ),
            _CouponRow(state: state),
            for (final item in state.items)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
                child: _LineCard(item: item),
              ),
            _BillBlock(state: state),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
    );
  }
}

/// Coupon row: applied chip (code + discount + remove) or an Apply affordance.
class _CouponRow extends ConsumerWidget {
  const _CouponRow({required this.state});

  final CartViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    if (state.coupon != null) {
      final coupon = state.coupon!;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: colors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: Row(
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 18, color: scheme.primary),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  '${coupon.code} · −₹${_rupees(coupon.discount)}',
                  style: AppTypography.label(scheme.primary),
                ),
              ),
              InkWell(
                key: const Key('coupon-remove'),
                onTap: () => ref
                    .read(cartControllerProvider.notifier)
                    .removeCoupon(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: Icon(Icons.close,
                      size: 18, color: scheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
      child: OutlinedButton.icon(
        key: const Key('coupon-open'),
        onPressed: () => _CouponSheet.show(context),
        icon: const Icon(Icons.local_offer_outlined, size: 18),
        label: const Text('Apply coupon'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: colors.faint),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
        ),
      ),
    );
  }
}

/// Coupon bottom sheet: code field + Apply + inline backend errors.
class _CouponSheet extends ConsumerStatefulWidget {
  const _CouponSheet();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => const _CouponSheet(),
    );
  }

  @override
  ConsumerState<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<_CouponSheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final couponError =
        ref.watch(cartControllerProvider).couponError;
    final applying =
        ref.watch(cartControllerProvider).applyingCoupon;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md,
              AppSpace.lg, AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.faint,
                    borderRadius:
                        BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text('Apply coupon',
                  style: AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                height: 52,
                child: TextField(
                  key: const Key('coupon-field'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _apply(),
                  style: AppTypography.body(scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Coupon code',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.input),
                      borderSide: BorderSide(color: colors.faint),
                    ),
                  ),
                ),
              ),
              if (couponError != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(couponError,
                    style:
                        AppTypography.caption(scheme.error)),
              ],
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 54,
                child: FilledButton(
                  key: const Key('coupon-apply'),
                  onPressed: applying ? null : _apply,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: applying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _apply() async {
    await ref
        .read(cartControllerProvider.notifier)
        .applyCoupon(_code.text);
    if (!mounted) return;
    if (ref.read(cartControllerProvider).couponError == null) {
      Navigator.of(context).pop();
    }
  }
}

/// Line card: 76dp thumb, 3-line middle, stepper + danger remove.
class _LineCard extends ConsumerWidget {
  const _LineCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ProductCard(
      product: CatalogProduct(
        id: item.id,
        name: item.variantName,
        slug: '',
        mrp: item.price,
        basePrice: item.price,
      ),
      density: ProductDensity.line,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          QtyStepper(
            quantity: item.quantity,
            compact: true,
            onChanged: (next) {
              if (next <= 0) {
                _remove(ref, context);
              } else {
                ref
                    .read(cartControllerProvider.notifier)
                    .setQty(item.id, next);
              }
            },
          ),
          TextButton(
            key: Key('line-remove-${item.id}'),
            onPressed: () => _remove(ref, context),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: scheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(WidgetRef ref, BuildContext context) async {
    final removed = await ref
        .read(cartControllerProvider.notifier)
        .removeLine(item);
    if (!context.mounted || removed == null) return;
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      messenger
          .showSnackBar(
            SnackBar(
              content: Text('Removed ${item.variantName}'),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => ref
                    .read(cartControllerProvider.notifier)
                    .undoRemove(removed),
              ),
              duration: const Duration(seconds: 5),
            ),
          )
          .closed
          .then((reason) {
        if (reason != SnackBarClosedReason.action) {
          ref.read(cartControllerProvider.notifier).refresh();
        }
      }),
    );
  }
}

/// Server-truth bill: subtotal + validated coupon discount + total.
/// Delivery has no cart-API source, so it resolves at checkout.
class _BillBlock extends StatelessWidget {
  const _BillBlock({required this.state});

  final CartViewState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
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
          _row(context, 'Subtotal', '₹${_rupees(state.subtotal)}',
              scheme.onSurface),
          if (state.coupon != null) ...[
            const SizedBox(height: AppSpace.xs),
            _row(context, 'Coupon ${state.coupon!.code}',
                '−₹${_rupees(state.discount)}', colors.success,
                strong: true),
          ],
          const SizedBox(height: AppSpace.xs),
          _row(context, 'Delivery', 'At checkout',
              scheme.onSurfaceVariant),
          const Divider(height: AppSpace.lg),
          _row(context, 'Total', '₹${_rupees(state.payable)}',
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

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.payable});

  final double payable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
            top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: FilledButton(
            key: const Key('cart-checkout'),
            onPressed: () => context.go('/checkout'),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppRadii.button),
              ),
            ),
            child: Text(
              'Proceed to checkout · ₹${_rupees(payable)}',
              style: AppTypography.label(scheme.onPrimary, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

String _rupees(double value) =>
    value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);