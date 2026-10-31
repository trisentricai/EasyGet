import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// DESIGN §11.2 — one Add system for every density: `Add` pill (primary
/// outline, 40dp) that morphs (180ms, light haptic) into a `− qty +` stepper
/// (primaryTint fill). Qty 0 morphs back; `+` disables at [maxQty] with a
/// tooltip "Only N available".
class QtyStepper extends StatefulWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.maxQty = 99,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int maxQty;
  final bool compact;

  @override
  State<QtyStepper> createState() => _QtyStepperState();
}

class _QtyStepperState extends State<QtyStepper> {
  late int _qty = widget.quantity;

  @override
  void didUpdateWidget(QtyStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) _qty = widget.quantity;
  }

  void _emit(int next) {
    if (next == _qty) return;
    HapticFeedback.lightImpact();
    setState(() => _qty = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.micro,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      child: _qty == 0 ? _addButton(context) : _stepper(context),
    );
  }

  Widget _addButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = widget.compact ? 34.0 : 40.0;
    return Semantics(
      button: true,
      label: 'Add to cart',
      child: SizedBox(
        key: const ValueKey('qty-add'),
        height: height,
        child: OutlinedButton(
          onPressed: () => _emit(1),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(widget.compact ? 56 : 72, height),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? AppSpace.md : AppSpace.lg,
            ),
            side: BorderSide(color: scheme.primary),
            foregroundColor: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            textStyle: AppTypography.label(scheme.primary),
          ),
          child: const Text('Add'),
        ),
      ),
    );
  }

  Widget _stepper(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final atCap = _qty >= widget.maxQty;
    final size = widget.compact ? 34.0 : 40.0;

    final plusButton = IconButton(
      key: const Key('qty-plus'),
      onPressed: atCap ? null : () => _emit(_qty + 1),
      icon: const Icon(Icons.add),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      color: scheme.primary,
      disabledColor: scheme.onSurfaceVariant.withValues(alpha: 0.38),
      constraints: BoxConstraints.tightFor(width: size, height: size),
      padding: EdgeInsets.zero,
    );

    return Container(
      key: const ValueKey('qty-stepper'),
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: const Key('qty-minus'),
            onPressed: () => _emit(_qty - 1),
            icon: const Icon(Icons.remove),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            color: scheme.primary,
            constraints: BoxConstraints.tightFor(width: size, height: size),
            padding: EdgeInsets.zero,
          ),
          Semantics(
            label: 'Quantity $_qty',
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 20),
              child: Text(
                '$_qty',
                textAlign: TextAlign.center,
                style: AppTypography.tabularNumber(scheme.onSurface, size: 14),
              ),
            ),
          ),
          atCap
              ? Tooltip(
                  message: 'Only ${widget.maxQty} available',
                  child: plusButton,
                )
              : plusButton,
        ],
      ),
    );
  }
}