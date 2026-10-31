import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';

/// One switch row on the [FilterSheet].
class FilterToggle {
  const FilterToggle({
    required this.id,
    required this.label,
    this.value = false,
  });

  final String id;
  final String label;
  final bool value;
}

/// DESIGN §11.6 — browse filter bottom sheet (radius 24 top). Rows are
/// switches (not checkboxes); Apply shows the live result count, Clear resets.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.filters,
    this.resultCount = 0,
    this.onApply,
    this.onClear,
  });

  final List<FilterToggle> filters;
  final int resultCount;
  final ValueChanged<Set<String>>? onApply;
  final VoidCallback? onClear;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late final Map<String, bool> _state = {
    for (final f in widget.filters) f.id: f.value,
  };

  Set<String> get _enabled =>
      _state.entries.where((e) => e.value).map((e) => e.key).toSet();

  void _clear() {
    setState(() {
      for (final key in _state.keys) {
        _state[key] = false;
      }
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
            child: Text('Filters',
                style: AppTypography.screenTitle(scheme.onSurface)),
          ),
          for (final filter in widget.filters)
            SwitchListTile(
              value: _state[filter.id] ?? false,
              onChanged: (value) =>
                  setState(() => _state[filter.id] = value),
              title: Text(filter.label,
                  style: AppTypography.bodyMedium(scheme.onSurface)),
              activeThumbColor: scheme.primary,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: Row(
              children: [
                TextButton(
                  key: const Key('filter-clear'),
                  onPressed: _clear,
                  child: Text('Clear',
                      style: AppTypography.label(scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: FilledButton(
                      key: const Key('filter-apply'),
                      onPressed: () {
                        widget.onApply?.call(_enabled);
                        Navigator.of(context).maybePop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                      ),
                      child: Text('Show ${widget.resultCount}',
                          style:
                              AppTypography.label(scheme.onPrimary, size: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}