import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';
import 'app_bar.dart';
import 'bottom_nav.dart';
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
  });

  final String route;
  final String title;
  final bool showSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EasyGetAppBar(
        title: title,
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
