import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// Custom AppBar with address row + ETA pill + notification bell.
/// Mirrors React Header component.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.address,
    this.etaMinutes,
    this.showSearch = false,
    this.onSearchTap,
    this.onAddressTap,
    this.onNotificationTap,
    this.notificationCount = 0,
    this.leading,
    this.actions,
  });

  final String? title;
  final String? address;
  final int? etaMinutes;
  final bool showSearch;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAddressTap;
  final VoidCallback? onNotificationTap;
  final int notificationCount;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 44);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return AppBar(
      automaticallyImplyLeading: leading == null,
      leading: leading,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (address != null) ...[
            InkWell(
              onTap: onAddressTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: colors.brand,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        address!,
                        style: AppTypography.caption(theme.colorScheme.onSurface, size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (etaMinutes != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.marigoldWash,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 10,
                      color: colors.marigold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$etaMinutes min',
                      style: AppTypography.tabularNumber(colors.marigold, size: 10),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (title != null) ...[
            Text(
              title!,
              style: AppTypography.screenTitle(theme.colorScheme.onSurface),
            ),
          ],
        ],
      ),
      actions: [
        if (showSearch)
          IconButton(
            onPressed: onSearchTap,
            icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
            tooltip: 'Search',
          ),
        if (notificationCount > 0 || onNotificationTap != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: Icon(Icons.notifications_outlined, color: theme.colorScheme.onSurface),
                tooltip: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colors.danger,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: AppTypography.tabularSmall(Colors.white, size: 9),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ...?actions,
      ],
      bottom: showSearch
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: colors.sunken,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            'Search atta, milk, soap…',
                            style: AppTypography.body(theme.colorScheme.onSurfaceVariant),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '10 MIN',
                              style: AppTypography.tabularNumber(Colors.white, size: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// Simple app bar for inner pages (back button + title).
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      leading: leading ?? const BackButton(),
      title: Text(title, style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
      actions: actions,
    );
  }
}