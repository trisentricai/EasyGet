import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';
import 'app_bar.dart';
import 'bottom_nav.dart';
import 'eta_pill.dart';
import 'search_bar.dart';

/// The persistent shell every tab renders inside: body swaps per branch,
/// BottomNav stays put (DESIGN §11.5).
class EasyGetShell extends StatelessWidget {
  const EasyGetShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: EasyGetBottomNav(navigationShell: navigationShell),
    );
  }
}

/// Per-tab chrome: AppBar (+ optional SearchBar). The body is a placeholder
/// keyed `placeholder-<route>` so later plans prove replacement (Phase 1 T5
/// convention).
class EasyGetTabScaffold extends StatelessWidget {
  const EasyGetTabScaffold({
    super.key,
    required this.route,
    required this.title,
    this.showSearch = false,
    this.home = false,
  });

  final String route;
  final String title;
  final bool showSearch;
  final bool home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EasyGetAppBar(
        title: home ? null : title,
        addressRow: home ? const _AddressRow() : null,
        etaPill: home
            ? const KeyedSubtree(
                key: Key('home-eta-pill'),
                child: EtaPill(minutes: 12),
              )
            : null,
        bottom: showSearch ? const AppSearchBar() : null,
      ),
      body: KeyedSubtree(
        key: Key('placeholder-$route'),
        child: Center(
          child: Text('EASYGET · /$route',
              style: AppTypography.body(Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

/// Home-tab delivery address row (chevron → address sheet later).
class _AddressRow extends StatelessWidget {
  const _AddressRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      key: const Key('home-address-row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined, size: 20, color: scheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Deliver to',
                  style: AppTypography.caption(scheme.onSurfaceVariant)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text('Home · Bengaluru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium(scheme.onSurface)),
                  ),
                  Icon(Icons.keyboard_arrow_down,
                      size: 18, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
