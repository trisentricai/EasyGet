import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/snackbar.dart';
import 'wishlist_controller.dart';

/// Heart button that floats over card/gallery images (top-right). Reads the
/// shared wishlist state, flips optimistically, and says so out loud when
/// the server refuses (never a silent no-op).
class CardHeart extends ConsumerWidget {
  const CardHeart({super.key, required this.slug, this.onToggled});

  final String slug;

  /// Fires with the NEW heart state after a successful toggle.
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = Theme.of(context).freshColors;
    final hearted =
        ref.watch(wishlistControllerProvider).value?.contains(slug) ??
            false;

    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          unawaited(HapticFeedback.lightImpact());
          final ok = await ref
              .read(wishlistControllerProvider.notifier)
              .toggle(slug);
          if (!context.mounted) return;
          if (ok) {
            onToggled?.call(!hearted);
          } else {
            showAppSnackbar(context, 'Could not update your wishlist.');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Icon(
            hearted ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: hearted ? colors.danger : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}