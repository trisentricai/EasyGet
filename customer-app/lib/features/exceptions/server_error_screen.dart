import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// Server error screen - 500 cold backend recovery.
class ServerErrorScreen extends ConsumerWidget {
  const ServerErrorScreen({super.key});

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
                  color: colors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.dashboard_outlined, size: 48, color: colors.warning),
              ),
              const SizedBox(height: 24),
              Text('Store Server Spinning Up', style: AppTypography.displayHero(theme.colorScheme.onSurface).copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text('Waking up the store...', style: AppTypography.bodyMedium(theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.75,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('GET /storefront/easyget/ · Retrying automatically in ~8s', style: AppTypography.tabularSmall(theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/home'), child: const Text('Wake Up Store Now')),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: () => context.go('/home'), child: const Text('Continue with Offline Cache')),
            ],
          ),
        ),
      ),
    );
  }
}