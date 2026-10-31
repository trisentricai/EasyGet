import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/nav.dart';
import '../../../core/widgets/skeletons.dart';
import '../../../core/widgets/snackbar.dart';
import '../../../core/widgets/states.dart';
import '../../../models/notification_model.dart';
import '../data/notifications_repository.dart';
import 'notifications_providers.dart';

/// E1 · Notifications inbox (`/notifications`, pushed from the Home bell):
/// icon by type, title/body/time, unread dots. Tapping marks read;
/// AppBar action marks everything read.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationsListProvider);

    return Scaffold(
      appBar: EasyGetAppBar(
        showBack: true,
        onBack: () => popOrHome(context),
        title: 'Notifications',
        actions: [
          TextButton(
            key: const Key('notif-mark-all'),
            onPressed: () async {
              try {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllRead();
                ref.invalidate(notificationsListProvider);
                ref.invalidate(unreadCountProvider);
              } catch (_) {
                if (context.mounted) {
                  showAppSnackbar(
                      context, 'Could not mark all as read.');
                }
              }
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: inbox.when(
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                SkeletonLine(height: 64, radius: AppRadii.card),
                SizedBox(height: AppSpace.sm),
                SkeletonLine(height: 64, radius: AppRadii.card),
              ],
            ),
          ),
        ),
        error: (_, _) => ErrorState(
          body: 'We could not load notifications.',
          onRetry: () => ref.invalidate(notificationsListProvider),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              title: "You're all caught up",
              body: 'Order updates and offers will land here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg,
                  AppSpace.md, AppSpace.lg, AppSpace.xxl),
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpace.sm),
              itemBuilder: (_, i) =>
                  _NotificationRow(notification: rows[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  static const _icons = {
    'ORDER': Icons.receipt_long,
    'OFFER': Icons.local_offer_outlined,
    'SYSTEM': Icons.info_outline,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final type = (notification.type ?? '').toUpperCase();
    return InkWell(
      key: Key('notif-${notification.id}'),
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: () async {
        if (!notification.isRead) {
          try {
            await ref
                .read(notificationsRepositoryProvider)
                .markRead(notification.id);
            ref.invalidate(notificationsListProvider);
            ref.invalidate(unreadCountProvider);
          } catch (_) {
            if (context.mounted) {
              showAppSnackbar(context, 'Could not mark as read.');
            }
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: colors.faint),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: Icon(_icons[type] ?? Icons.notifications_outlined,
                  size: 20, color: scheme.primary),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium(
                          scheme.onSurface)),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(
                            scheme.onSurfaceVariant)),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _age(notification.createdAt),
                    style: AppTypography.caption(
                        scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                key: Key('notif-dot-${notification.id}'),
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: AppSpace.sm, top: 4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _age(DateTime? at) {
  if (at == null) return '';
  final delta = DateTime.now().difference(at);
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
  if (delta.inHours < 24) return '${delta.inHours}h ago';
  return '${delta.inDays}d ago';
}