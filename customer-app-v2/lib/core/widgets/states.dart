import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// Shared anatomy for empty / error / offline: icon dot + title + body +
/// primary CTA (DESIGN §11 global law).
class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    // Centered in the available body (not stuck to the top): every
    // full-screen usage renders these as the Scaffold body or inside an
    // Expanded, both of which give a bounded height.
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: scheme.primary, size: 28),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AppTypography.screenTitle(scheme.onSurface)),
              if (body != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(body!,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(scheme.onSurfaceVariant)),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpace.xl),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xxl),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadii.button),
                      ),
                    ),
                    child: Text(actionLabel!,
                        style: AppTypography.label(scheme.onPrimary,
                            size: 16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.inventory_2_outlined,
  });

  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _StateView(
        icon: icon,
        title: title,
        body: body,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.body,
    this.retryLabel = 'Retry',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String title;
  final String? body;
  final String retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _StateView(
        icon: icon,
        title: title,
        body: body,
        actionLabel: onRetry == null ? null : retryLabel,
        onAction: onRetry,
      );
}

class OfflineState extends StatelessWidget {
  const OfflineState({
    super.key,
    this.title = "You're offline",
    this.body = 'Check your connection and try again.',
    this.actionLabel = 'Retry',
    this.onAction,
    this.icon = Icons.wifi_off_rounded,
  });

  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => _StateView(
        icon: icon,
        title: title,
        body: body,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}