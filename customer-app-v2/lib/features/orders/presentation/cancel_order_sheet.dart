import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';

/// Shared cancel-confirm sheet (S10 list + S11 detail): editable reason
/// (the API requires one), danger confirm. Returns the reason, or null on
/// dismiss. Callers perform the cancel + refresh.
class CancelOrderSheet extends ConsumerStatefulWidget {
  const CancelOrderSheet({super.key, required this.orderId});

  final int orderId;

  static Future<String?> show(BuildContext context, int orderId) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (_) => CancelOrderSheet(orderId: orderId),
    );
  }

  @override
  ConsumerState<CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends ConsumerState<CancelOrderSheet> {
  late final TextEditingController _reason =
      TextEditingController(text: 'Changed my mind');

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.lg,
              AppSpace.md,
              AppSpace.lg,
              AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
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
              Text('Cancel this order?',
                  style:
                      AppTypography.screenTitle(scheme.onSurface)),
              const SizedBox(height: AppSpace.xs),
              Text('This cannot be undone.',
                  style: AppTypography.body(
                      scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 52,
                child: TextField(
                  key: const Key('cancel-reason'),
                  controller: _reason,
                  textCapitalization:
                      TextCapitalization.sentences,
                  style: AppTypography.body(scheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Reason',
                    contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: AppSpace.lg),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.input),
                      borderSide:
                          BorderSide(color: colors.faint),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  key: const Key('cancel-confirm'),
                  onPressed: () => Navigator.of(context)
                      .pop(_reason.text.trim()),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text('Confirm cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}