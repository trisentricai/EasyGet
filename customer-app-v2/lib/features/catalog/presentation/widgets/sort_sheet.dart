import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// One orderable sort choice.
class SortOption {
  const SortOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// DESIGN §11.6 — sort bottom sheet (radius 24 top): radio rows, one selection.
class SortSheet extends StatelessWidget {
  const SortSheet({
    super.key,
    required this.options,
    this.selectedId,
    this.onSelect,
  });

  final List<SortOption> options;
  final String? selectedId;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpace.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.faint,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
            child: Text('Sort by',
                style: AppTypography.screenTitle(scheme.onSurface)),
          ),
          for (final option in options)
            ListTile(
              key: Key('sort-option-${option.id}'),
              onTap: () {
                onSelect?.call(option.id);
                Navigator.of(context).maybePop();
              },
              leading: Icon(
                option.id == selectedId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: option.id == selectedId ? scheme.primary : colors.faint,
              ),
              title: Text(option.label,
                  style: AppTypography.bodyMedium(scheme.onSurface)),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
      ),
    );
  }
}