import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'nav.dart';

/// Navigation chrome shared by every tab + inner page (DESIGN §11.5):
/// frosted translucent fill, no elevation, hairline scrolled-under border,
/// Headline title. The back affordance is a framework [BackButton] (so the
/// test `pageBack` and assistive tech find it) with [popOrHome] as the
/// default action.
class EasyGetAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EasyGetAppBar({
    super.key,
    this.title,
    this.showBack = false,
    this.onBack,
    this.addressRow,
    this.etaPill,
    this.actions = const [],
    this.bottom,
  });

  final String? title;
  final bool showBack;
  final VoidCallback? onBack;

  /// Replaces [title] on the Home tab (delivery-address row + chevron).
  final Widget? addressRow;

  /// Marigold wash ETA pill (Home tab).
  final Widget? etaPill;

  final List<Widget> actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 0 : 16,
      leading: showBack
          ? BackButton(onPressed: onBack ?? () => popOrHome(context))
          : null,
      title: addressRow ?? (title == null ? null : Text(title!)),
      actions: [
        if (etaPill != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: etaPill),
          ),
        ...actions,
      ],
      bottom: bottom,
      // Translucent fill without a GPU BackdropFilter: Impeller on some
      // Android GPUs leaks the backdrop blur across the whole screen when a
      // filter is nested in the app bar / cards. The tint keeps the frosted
      // look; the blur itself is intentionally omitted for compatibility.
      flexibleSpace: ColoredBox(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.86),
      ),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shape: Border(bottom: BorderSide(color: colors.glassBorder, width: 1)),
    );
  }
}
