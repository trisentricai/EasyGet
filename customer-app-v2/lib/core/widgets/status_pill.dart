import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// `OUT_FOR_DELIVERY` → `Out for delivery`.
String humanizeStatus(String status) {
  if (status.isEmpty) return '';
  final words = status.replaceAll('_', ' ').toLowerCase();
  return words[0].toUpperCase() + words.substring(1);
}

/// DESIGN §11.6 — transit = marigold wash, delivered = success, cancelled /
/// refunded = muted.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;

    final (Color background, Color foreground) = switch (status) {
      'DELIVERED' => (colors.success, scheme.onPrimary),
      'CANCELLED' || 'REFUNDED' => (colors.sunken, scheme.onSurfaceVariant),
      _ => (colors.marigoldWash, colors.marigold),
    };

    return Container(
      key: const Key('status-pill'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpace.sm : AppSpace.md,
        vertical: AppSpace.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        humanizeStatus(status),
        style: AppTypography.label(foreground, size: compact ? 11 : 12),
      ),
    );
  }
}