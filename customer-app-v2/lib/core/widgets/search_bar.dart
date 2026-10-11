import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';

/// Persistent search field under Home/Browse app bars (DESIGN §11.5):
/// 52dp, sunken fill, radius 16, decorative mic + camera, taps open `/search`.
class AppSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSearchBar({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: SizedBox(
        height: 52,
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const Key('app-search-bar'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap ?? () => context.go('/search'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search, color: scheme.onSurfaceVariant, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search atta, milk, soap…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(scheme.onSurfaceVariant),
                    ),
                  ),
                  Icon(Icons.mic_none, color: scheme.onSurfaceVariant, size: 22),
                  const SizedBox(width: 12),
                  Icon(Icons.camera_alt_outlined,
                      color: scheme.onSurfaceVariant, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}