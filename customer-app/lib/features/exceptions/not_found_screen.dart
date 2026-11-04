import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// 404 not found screen - harvest item not found.
class NotFoundScreen extends ConsumerWidget {
  const NotFoundScreen({super.key});

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
                child: Icon(Icons.article_outlined, size: 48, color: colors.marigold),
              ),
              const SizedBox(height: 24),
              Text('Item Not In Today\'s Harvest', style: AppTypography.displayHero(theme.colorScheme.onSurface).copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text('This product is no longer available or the link is invalid.', style: AppTypography.body(theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/home'), child: const Text('Back to Fresh Market Storefront')),
            ],
          ),
        ),
      ),
    );
  }
}