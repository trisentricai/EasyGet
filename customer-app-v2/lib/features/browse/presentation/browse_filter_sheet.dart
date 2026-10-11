import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../models/catalog_models.dart';

/// The browse filter value object. Nulls mean "no constraint".
class BrowseFilters {
  const BrowseFilters({
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.minDiscount,
    this.featured,
  });

  final String? brand;
  final double? minPrice;
  final double? maxPrice;
  final double? minDiscount;
  final bool? featured;

  int get activeCount =>
      (brand != null ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (minDiscount != null ? 1 : 0) +
      (featured == true ? 1 : 0);
}

class _PriceBand {
  const _PriceBand(this.label, this.min, this.max);
  final String label;
  final double? min;
  final double? max;
}

const _priceBands = [
  _PriceBand('Under ₹100', null, 100),
  _PriceBand('₹100–500', 100, 500),
  _PriceBand('₹500–1000', 500, 1000),
  _PriceBand('Above ₹1000', 1000, null),
];

const _discountBands = [
  ('Any', null),
  ('10%+', 10.0),
  ('20%+', 20.0),
  ('30%+', 30.0),
];

/// MNC-style browse filter sheet: Brand chips → Price bands → Discount
/// bands → Featured switch → Clear all + live-count Apply. Radius 24 top.
class BrowseFilterSheet extends StatefulWidget {
  const BrowseFilterSheet({
    super.key,
    required this.initial,
    required this.brands,
    this.resultCount = 0,
    this.onApply,
    this.onClear,
  });

  final BrowseFilters initial;
  final List<Brand> brands;
  final int resultCount;
  final ValueChanged<BrowseFilters>? onApply;
  final VoidCallback? onClear;

  @override
  State<BrowseFilterSheet> createState() => _BrowseFilterSheetState();
}

class _BrowseFilterSheetState extends State<BrowseFilterSheet> {
  late String? _brand = widget.initial.brand;
  late int _priceBand = _bandIndexOf(
      widget.initial.minPrice, widget.initial.maxPrice);
  late double? _minDiscount = widget.initial.minDiscount;
  late bool _featured = widget.initial.featured == true;

  static int _bandIndexOf(double? min, double? max) {
    for (var i = 0; i < _priceBands.length; i++) {
      if (_priceBands[i].min == min && _priceBands[i].max == max) return i;
    }
    return -1;
  }

  BrowseFilters get _value => BrowseFilters(
        brand: _brand,
        minPrice: _priceBand < 0 ? null : _priceBands[_priceBand].min,
        maxPrice: _priceBand < 0 ? null : _priceBands[_priceBand].max,
        minDiscount: _minDiscount,
        featured: _featured ? true : null,
      );

  void _clear() {
    setState(() {
      _brand = null;
      _priceBand = -1;
      _minDiscount = null;
      _featured = false;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.only(top: AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: AppTypography.label(scheme.onSurfaceVariant)),
              const SizedBox(height: AppSpace.sm),
              body,
            ],
          ),
        );

    Widget chip({
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.micro,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: selected ? colors.primaryTint : colors.sunken,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.label(
              selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
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
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.lg),
                child: Text('Filters',
                    style:
                        AppTypography.screenTitle(scheme.onSurface)),
              ),
              section(
                'Brand',
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    chip(
                      label: 'All brands',
                      selected: _brand == null,
                      onTap: () => setState(() => _brand = null),
                    ),
                    for (final brand in widget.brands)
                      chip(
                        label: brand.name,
                        selected: _brand == brand.slug,
                        onTap: () => setState(() => _brand =
                            _brand == brand.slug ? null : brand.slug),
                      ),
                  ],
                ),
              ),
              section(
                'Price',
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (var i = 0; i < _priceBands.length; i++)
                      chip(
                        label: _priceBands[i].label,
                        selected: _priceBand == i,
                        onTap: () => setState(() =>
                            _priceBand = _priceBand == i ? -1 : i),
                      ),
                  ],
                ),
              ),
              section(
                'Discount',
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final band in _discountBands)
                      chip(
                        label: band.$1,
                        selected: _minDiscount == band.$2,
                        onTap: () => setState(() => _minDiscount =
                            _minDiscount == band.$2 ? null : band.$2),
                      ),
                  ],
                ),
              ),
              section(
                'More',
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Featured only',
                      style: AppTypography.bodyMedium(
                          scheme.onSurface)),
                  value: _featured,
                  activeThumbColor: scheme.primary,
                  onChanged: (value) =>
                      setState(() => _featured = value),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(top: AppSpace.md),
                child: Row(
                  children: [
                    TextButton(
                      key: const Key('filter-clear'),
                      onPressed: _clear,
                      child: Text('Clear all',
                          style: AppTypography.label(
                              scheme.onSurfaceVariant)),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton(
                          key: const Key('filter-apply'),
                          onPressed: () {
                            widget.onApply?.call(_value);
                            Navigator.of(context).maybePop();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppRadii.button),
                            ),
                          ),
                          child: Text(
                              'Show ${widget.resultCount}',
                              style: AppTypography.label(
                                  scheme.onPrimary,
                                  size: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}