import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared_widgets/sticky_bottom_cta.dart';
import '../../../shared_widgets/custom_app_bar.dart';
import '../../../features/orders/data/orders_repository.dart';
import '../../../features/cart/presentation/cart_controller.dart';
import '../../../models/address.dart';

/// Checkout & Slot Booking screen.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0; // 0: Address, 1: Slot, 2: Payment
  Address? _selectedAddress;
  String _selectedSlot = 'Today · 10-Minute Express (8:30 - 8:45 AM)';
  String _selectedPayment = 'upi';
  int _riderTip = 20;
  final Set<String> _instructions = {'leave_door'};
  bool _isPlacing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider).state;

    if (cart.items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('Cart is empty', style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            automaticallyImplyLeading: false,
            flexibleSpace: CustomAppBar(
              title: 'Checkout',
              showSearch: false,
            ),
          ),
          // Steps header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _StepsHeader(currentStep: _step),
            ),
          ),
          // Step content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: [
                _AddressStep(
                  selectedAddress: _selectedAddress,
                  onChange: () => _pickAddress(),
                ),
                _SlotStep(
                  selectedSlot: _selectedSlot,
                  onChanged: (v) => setState(() => _selectedSlot = v),
                ),
                _PaymentStep(
                  selectedPayment: _selectedPayment,
                  onChanged: (v) => setState(() => _selectedPayment = v),
                  riderTip: _riderTip,
                  onTipChanged: (v) => setState(() => _riderTip = v),
                  instructions: _instructions,
                  onInstructionToggle: (inst) {
                    setState(() {
                      if (_instructions.contains(inst)) {
                        _instructions.remove(inst);
                      } else {
                        _instructions.add(inst);
                      }
                    });
                  },
                ),
              ][_step],
            ),
          ),
          // Bill summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _BillSummary(
                cart: cart,
                riderTip: _riderTip,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      bottomNavigationBar: StickyBottomCta(
        label: _step == 2 ? 'Place order' : 'Continue',
        price: cart.total + _riderTip,
        onPressed: _step == 2 ? _placeOrder : _nextStep,
        isLoading: _isPlacing,
      ),
    );
  }

  void _nextStep() {
    if (_step == 0 && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select a delivery address')),
      );
      return;
    }
    setState(() => _step++);
  }

  void _pickAddress() {
    // Navigate to addresses screen for selection
    context.push('/addresses').then((result) {
      if (result is Address) {
        setState(() => _selectedAddress = result);
      }
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) return;
    setState(() => _isPlacing = true);

    try {
      final repo = ref.read(ordersRepositoryProvider);
      final order = await repo.placeOrder(
        addressId: _selectedAddress!.id,
        paymentMethod: _selectedPayment,
        slot: _selectedSlot,
        riderTip: _riderTip,
        instructions: _instructions.toList(),
      );
      if (!mounted) return;
      ref.read(cartProvider.notifier).clearCart();
      context.go('/order/${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }
}

/// Steps header.
class _StepsHeader extends StatelessWidget {
  const _StepsHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final steps = ['Address', 'Time Slot', 'Payment'];

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final isActive = i <= currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: isActive ? colors.primary : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              if (i < steps.length - 1) const SizedBox(width: 8),
            ],
          ));
        }).toList(),
    );
  }
}

/// Address step.
class _AddressStep extends StatelessWidget {
  const _AddressStep({
    required this.selectedAddress,
    required this.onChange,
  });

  final Address? selectedAddress;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Delivery Address', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        if (selectedAddress == null)
          OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.add_location),
            label: const Text('Add Delivery Address'),
          )
        else
          InkWell(
            onTap: onChange,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.primary),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(selectedAddress!.label, style: AppTypography.label(theme.colorScheme.onSurface)),
                            if (selectedAddress!.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('DEFAULT', style: AppTypography.tabularSmall(Colors.white)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(selectedAddress!.fullAddress, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                        Text(selectedAddress!.phone, style: AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: onChange, child: Text('Change', style: AppTypography.label(colors.primary))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
      ],
    );
  }
}

/// Slot step.
class _SlotStep extends StatelessWidget {
  const _SlotStep({
    required this.selectedSlot,
    required this.onChanged,
  });

  final String selectedSlot;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    final todaySlots = [
      '10-Minute Express (8:30 - 8:45 AM)',
      'Morning Slot (9:00 - 11:00 AM)',
      'Midday Slot (12:00 - 2:00 PM)',
      'Evening Harvest (5:00 - 7:00 PM)',
    ];

    final tomorrowSlots = [
      'Tomorrow Morning (7:00 - 9:00 AM)',
      'Tomorrow Midday (11:00 - 1:00 PM)',
      'Tomorrow Evening (4:00 - 6:00 PM)',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose Delivery Slot', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        // Day selector
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'today', label: Text('Today (Instant / Slotted)')),
            ButtonSegment(value: 'tomorrow', label: Text('Tomorrow Morning')),
          ],
          selected: {'today'},
          onSelectionChanged: (_) {},
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return colors.primaryTint;
              return theme.colorScheme.surfaceContainerHighest;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return colors.primary;
              return theme.colorScheme.onSurfaceVariant;
            }),
          ),
        ),
        const SizedBox(height: 16),
        // Time windows
        RadioGroup<String>(
          groupValue: selectedSlot,
          onChanged: (v) => onChanged(v!),
          child: Column(
            children: [
              ...todaySlots.map((slot) => RadioListTile<String>(
                title: Text(slot, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                value: 'Today · $slot',
                activeColor: colors.primary,
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 16),
              Text('Tomorrow', style: AppTypography.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ...tomorrowSlots.map((slot) => RadioListTile<String>(
                title: Text(slot, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                value: 'Tomorrow · $slot',
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

/// Payment step.
class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.selectedPayment,
    required this.onChanged,
    required this.riderTip,
    required this.onTipChanged,
    required this.instructions,
    required this.onInstructionToggle,
  });

  final String selectedPayment;
  final ValueChanged<String> onChanged;
  final int riderTip;
  final ValueChanged<int> onTipChanged;
  final Set<String> instructions;
  final ValueChanged<String> onInstructionToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: selectedPayment,
          onChanged: (v) => onChanged(v!),
          child: Column(
            children: [
              ...[
                ('upi', 'UPI Instant', 'Google Pay, PhonePe, Paytm', 'RECOMMENDED'),
                ('card', 'Credit / Debit Card', 'Secure card payment', ''),
                ('cod', 'Cash on Doorstep Handover (COD)', 'Pay when delivered', ''),
              ].map((p) => RadioListTile<String>(
                title: Row(
                  children: [
                    Text(p.$2, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
                    if (p.$4 == 'RECOMMENDED') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('RECOMMENDED', style: AppTypography.tabularSmall(Colors.white)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(p.$3, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
                value: p.$1,
                activeColor: colors.primary,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rider tipping
        Text('Rider Tipping', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('100% goes directly to electric rider Ravi Kumar', style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [0, 20, 30, 50].map((tip) => ChoiceChip(
            label: Text(tip == 0 ? 'No tip' : '₹$tip', style: AppTypography.label(
              riderTip == tip ? Colors.white : theme.colorScheme.onSurface,
            )),
            selected: riderTip == tip,
            onSelected: (_) => onTipChanged(tip),
            selectedColor: colors.primary,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          )).toList(),
        ),
        const SizedBox(height: 16),
        // Delivery instructions
        Text('Delivery Instructions', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '🚪 Leave at door',
            '🔕 Do not ring bell',
            '📵 Avoid calling',
            '🛡️ Hand to security',
            '🐾 Pet at home',
          ].map((inst) {
            final selected = instructions.contains(inst);
            return FilterChip(
              label: Text(inst, style: AppTypography.label(
                selected ? Colors.white : theme.colorScheme.onSurface,
              )),
              selected: selected,
              onSelected: (_) => onInstructionToggle(inst),
              selectedColor: colors.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Bill summary.
class _BillSummary extends StatelessWidget {
  const _BillSummary({
    required this.cart,
    required this.riderTip,
  });

  final CartState cart;
  final int riderTip;

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
          _BillRow('Item Subtotal', cart.subtotal),
          if (cart.discount > 0)
            _BillRow('Coupon Discount', -cart.discount, color: colors.success),
          _BillRow('Delivery Fee', cart.deliveryFee),
          if (riderTip > 0)
            _BillRow('Rider Tip', riderTip),
          Divider(color: theme.colorScheme.outlineVariant),
          _BillRow('Total To Pay', cart.total + riderTip, isTotal: true),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(this.label, this.amount, {this.isTotal = false, this.color});

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