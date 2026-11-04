import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/product_card.dart';
import '../../../shared_widgets/sticky_bottom_cta.dart';
import '../../../shared_widgets/custom_app_bar.dart';
import '../../../features/cart/presentation/cart_controller.dart';
import '../../../models/coupon.dart';

/// Cart & Vouchers screen (Tab 4).
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Coupon? _appliedCoupon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    final cart = ref.watch(cartProvider).state;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.read(cartProvider.notifier).loadCart(),
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              automaticallyImplyLeading: false,
              flexibleSpace: CustomAppBar(
                title: 'Your Cart',
                showSearch: false,
              ),
            ),
            // ETA banner
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Guaranteed 12-Minute Delivery · Free over ₹300',
                        style: AppTypography.body(colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Free delivery progress
            if (cart.subtotal > 0 && cart.subtotal < 300)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Free Delivery Progress',
                            style: AppTypography.bodyMedium(theme.colorScheme.onSurface),
                          ),
                          Text(
                            '₹${cart.subtotal}/₹300',
                            style: AppTypography.tabularPrice(colors.primary, size: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: cart.subtotal / 300,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                        backgroundColor: theme.colorScheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation(colors.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add ₹${300 - cart.subtotal} more for free delivery',
                        style: AppTypography.caption(colors.marigold),
                      ),
                    ],
                  ),
                ),
              ),
            // Coupon row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _CouponRow(
                  appliedCoupon: _appliedCoupon,
                  onApply: _showCouponSheetDialog,
                  onRemove: () => setState(() => _appliedCoupon = null),
                ),
              ),
            ),
            // Line items
            if (cart.items.isEmpty)
              SliverFillRemaining(
                child: _EmptyCartState(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = cart.items[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: colors.danger,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(cartProvider.notifier).removeItem(item.product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.product.name} removed'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () => ref.read(cartProvider.notifier).addToCart(item.product, item.quantity),
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          );
                        },
                        child: ProductCard(
                          product: item.product,
                          variant: ProductVariant.line,
                          quantity: item.quantity,
                          onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                        ),
                      ),
                    );
                  },
                  childCount: cart.items.length,
                ),
              ),
            // Out of stock substitution preference
            if (cart.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SubstitutionPreference(
                    current: cart.substitutionPreference,
                    onChanged: (v) => ref.read(cartProvider.notifier).setSubstitution(v),
                  ),
                ),
              ),
            // Bill summary
            if (cart.items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _BillSummary(cart: cart),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      bottomNavigationBar: cart.items.isNotEmpty
          ? StickyBottomCta(
              label: 'Proceed to checkout',
              price: cart.total,
              onPressed: () => context.push('/checkout'),
            )
          : null,
    );
  }

  void _showCouponSheetDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CouponSheet(
        cartSubtotal: ref.read(cartProvider).state.subtotal,
        onApply: (code) async {
          final validation = await ref.read(cartProvider.notifier).applyCoupon(code, ref.read(cartProvider).state.subtotal);
          if (validation.applied) {
            setState(() => _appliedCoupon = Coupon(
              code: code,
              title: code,
              discountAmount: validation.discount,
              minOrder: 0,
              description: validation.message ?? '',
              expiry: '',
            ));
          }
          if (!mounted) return;
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// ETA banner already in sliver.

/// Coupon row.
class _CouponRow extends StatelessWidget {
  const _CouponRow({
    required this.appliedCoupon,
    required this.onApply,
    required this.onRemove,
  });

  final Coupon? appliedCoupon;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    if (appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Coupon Applied', style: AppTypography.bodyMedium(colors.success)),
                  Text(
                    '${appliedCoupon!.code} · Saved ₹${appliedCoupon!.discountAmount}',
                    style: AppTypography.caption(colors.success),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRemove, child: Text('Remove', style: AppTypography.label(colors.danger))),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onApply,
      icon: Icon(Icons.local_offer_outlined, color: theme.colorScheme.onSurface),
      label: Text('Apply Coupon or Voucher', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
    );
  }
}

/// Empty cart state.
class _EmptyCartState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: colors.faint),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Add some fresh items to get started', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }
}

/// Substitution preference.
class _SubstitutionPreference extends StatelessWidget {
  const _SubstitutionPreference({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Out-of-Stock Substitution', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: current,
          onChanged: (v) => onChanged(v!),
          child: Column(
            children: [
              ...[
                ('call', '📞 Call me', 'I\'ll decide on each item'),
                ('best_match', '🔄 Best match', 'Substitute with similar quality'),
                ('refund', '💵 Refund directly', 'Don\'t substitute, just refund'),
              ].map((opt) => RadioListTile<String>(
                title: Text(opt.$2, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                subtitle: Text(opt.$3, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                value: opt.$1,
                activeColor: colors.primary,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bill summary.
class _BillSummary extends StatelessWidget {
  const _BillSummary({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _BillRow('Item Subtotal', cart.subtotal, isTotal: false),
          if (cart.discount > 0)
            _BillRow('Coupon Discount', -cart.discount, isTotal: false, color: colors.success),
          _BillRow('Delivery Fee', cart.deliveryFee, isTotal: false),
          if (cart.riderTip > 0)
            _BillRow('Rider Tip', cart.riderTip, isTotal: false),
          Divider(color: theme.colorScheme.outlineVariant),
          _BillRow('Total To Pay', cart.total, isTotal: true),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(
    this.label,
    this.amount, {
    this.isTotal = false,
    this.color,
  });

  final String label;
  final int amount;
  final bool isTotal;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTypography.bodyMedium(theme.colorScheme.onSurface).copyWith(fontWeight: FontWeight.w700)
                : AppTypography.body(theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            amount >= 0 ? '₹$amount' : '-₹${-amount}',
            style: (isTotal
                    ? AppTypography.tabularPrice(theme.colorScheme.onSurface, size: 18)
                    : AppTypography.tabularPrice(color ?? theme.colorScheme.onSurface, size: 16))
                .copyWith(fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Coupon sheet.
class _CouponSheet extends StatefulWidget {
  const _CouponSheet({
    required this.cartSubtotal,
    required this.onApply,
  });

  final int cartSubtotal;
  final ValueChanged<String> onApply;

  @override
  State<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends State<_CouponSheet> {
  final _controller = TextEditingController();
  final _coupons = [
    Coupon(code: 'FRESH20', title: 'FRESH20', discountAmount: 50, minOrder: 200, description: '₹50 off on farm orders', expiry: ''),
    Coupon(code: 'MORNING10', title: 'MORNING10', discountAmount: 30, minOrder: 150, description: '₹30 off on organic milk', expiry: ''),
    Coupon(code: 'FIRSTGET', title: 'FIRSTGET', discountAmount: 75, minOrder: 300, description: '₹75 off on first order', expiry: ''),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Coupons & Vouchers', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
              ],
            ),
          ),
          // Manual code input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      prefixIcon: const Icon(Icons.local_offer_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      widget.onApply(_controller.text.trim().toUpperCase());
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Active vouchers list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _coupons.length,
              separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant),
              itemBuilder: (_, i) {
                final c = _coupons[i];
                final valid = widget.cartSubtotal >= c.minOrder;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.code,
                      style: AppTypography.tabularPrice(colors.primary, size: 14),
                    ),
                  ),
                  title: Text(c.title, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                  subtitle: Text('${c.description} · Min ₹${c.minOrder}', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                  trailing: FilledButton(
                    onPressed: valid ? () => widget.onApply(c.code) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: valid ? colors.primary : colors.primary.withValues(alpha: 0.4),
                    ),
                    child: const Text('Use'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}