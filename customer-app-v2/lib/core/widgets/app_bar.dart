import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';
import 'nav.dart';

/// Navigation chrome shared by every tab + inner page: solid Zepto-white
/// header, deep-purple/ink title, hairline bottom divider and no elevation.
/// The back affordance is a framework [BackButton] so `pageBack` and assistive
/// tech find it, with [popOrHome] as the default action. There is deliberately
/// no GPU blur — see the note in [EasyGetBottomNav].
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
      titleTextStyle: AppTypography.screenTitle(scheme.onSurface),
      actions: [
        if (etaPill != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: etaPill),
          ),
        ...actions,
      ],
      bottom: bottom,
      // Opaque fill: no GPU BackdropFilter anywhere in the chrome. Impeller on
      // the target Android GPU leaks a nested blur across the whole screen.
      flexibleSpace: ColoredBox(color: scheme.surfaceContainerLowest),
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      shape: Border(bottom: BorderSide(color: colors.glassBorder)),
    );
  }
}
