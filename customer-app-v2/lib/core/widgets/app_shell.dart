import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';
import 'app_bar.dart';
import 'bottom_nav.dart';
import 'search_bar.dart';

/// The persistent shell every tab renders inside: body swaps per branch,
/// the flat BottomNav auto-hides on downward vertical scroll and reappears on
/// upward scroll.
class EasyGetShell extends StatefulWidget {
  const EasyGetShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<EasyGetShell> createState() => _EasyGetShellState();
}

class _EasyGetShellState extends State<EasyGetShell> {
  bool _navVisible = true;
  int _lastBranch = -1;

  void _setNavVisible(bool value) {
    if (_navVisible == value) return;
    setState(() => _navVisible = value);
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          notification.metrics.pixels > 16) {
        _setNavVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        _setNavVisible(true);
      }
    } else if (notification is ScrollUpdateNotification &&
        notification.metrics.pixels <= 0) {
      _setNavVisible(true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final branch = widget.navigationShell.currentIndex;
    if (_lastBranch != branch) {
      _lastBranch = branch;
      _navVisible = true;
    }

    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: EasyGetBottomNav(
        navigationShell: widget.navigationShell,
        visible: _navVisible,
      ),
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
