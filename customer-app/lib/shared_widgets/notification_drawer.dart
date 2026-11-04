import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// Notification drawer bottom sheet + push toast banner.
/// Mirrors React NotificationDrawer component.
class NotificationDrawer extends StatefulWidget {
  const NotificationDrawer({super.key});

  @override
  State<NotificationDrawer> createState() => _NotificationDrawerState();
}

class _NotificationDrawerState extends State<NotificationDrawer> {
  AppNotification? _pushBanner;
  final List<AppNotification> _notifications = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Push toast banner (overlay)
        if (_pushBanner != null)
          _PushToastBanner(
            notification: _pushBanner!,
            onDismiss: () => setState(() => _pushBanner = null),
            onTap: () {
              setState(() => _pushBanner = null);
              // Navigate to action screen
            },
          ),
        // Bottom sheet (hidden by default, shown via showModalBottomSheet)
      ],
    );
  }

  void showSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        notifications: _notifications,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void showPushToast(AppNotification notification) {
    setState(() => _pushBanner = notification);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _pushBanner?.id == notification.id) {
        setState(() => _pushBanner = null);
      }
    });
  }
}

class _PushToastBanner extends StatelessWidget {
  const _PushToastBanner({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    Color bgColor;
    switch (notification.type) {
      case 'order':
        bgColor = colors.primary;
        break;
      case 'promo':
        bgColor = colors.marigold;
        break;
      default:
        bgColor = theme.colorScheme.surface;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          elevation: 4,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title,
                          style: AppTypography.bodyMedium(Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.body,
                          style: AppTypography.caption(Colors.white.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet({
    required this.notifications,
    required this.onClose,
  });

  final List<AppNotification> notifications;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Notifications', style: AppTypography.screenTitle(theme.colorScheme.onSurface)),
                const Spacer(),
                if (notifications.any((n) => !n.read))
                  TextButton(
                    onPressed: () {},
                    child: Text('Mark all read', style: AppTypography.label(colors.primary)),
                  ),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: colors.faint),
                        const SizedBox(height: 16),
                        Text('No notifications', style: AppTypography.body(theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outlineVariant),
                    itemBuilder: (_, i) => _NotificationTile(notification: notifications[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    Color indicatorColor;
    switch (notification.type) {
      case 'order':
        indicatorColor = colors.primary;
        break;
      case 'promo':
        indicatorColor = colors.marigold;
        break;
      default:
        indicatorColor = colors.muted;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(notification.title, style: AppTypography.bodyMedium(theme.colorScheme.onSurface)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notification.body, style: AppTypography.caption(theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(notification.timestamp, style: AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: notification.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
            ),
    );
  }
}

/// Notification model
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.read = false,
    this.actionScreen,
  });

  final String id;
  final String title;
  final String body;
  final String timestamp;
  final String type; // 'order' | 'promo' | 'system'
  final bool read;
  final String? actionScreen;
}