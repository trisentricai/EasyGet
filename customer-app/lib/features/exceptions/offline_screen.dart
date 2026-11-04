import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Offline screen - shaky 4G / offline.
class OfflineScreen extends ConsumerWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.marigoldWash,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.wifi_off, size: 48, color: colors.marigold),
              ),
              const SizedBox(height: 24),
              Text('You\'re Offline', style: AppTypography.displayHero(theme.colorScheme.onSurface).copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Connection Interrupted', style: AppTypography.bodyMedium(theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              Text('Your local cart and active order tracking are cached.', style: AppTypography.body(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              _ChecklistItem(text: 'Cart state preserved locally'),
              _ChecklistItem(text: 'Driver delivery queue is progressing'),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/home'), child: const Text('Retry Connection Now')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go('/cart'), child: const Text('View Cached Basket')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(text, style: AppTypography.body(theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}