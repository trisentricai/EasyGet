import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// Persistent search field under Home/Browse app bars (DESIGN §11.5):
/// 52dp, sunken translucent fill, radius 16. Taps open `/search`; the mic
/// jumps straight into voice search (`/search?listen=1`). No camera (v1
/// scope). Keys `app-search-bar` / `app-search-mic` are part of the shell
/// contract and stay unchanged.
class AppSearchBar extends StatelessWidget implements PreferredSizeWidget {
  const AppSearchBar({super.key, this.onTap, this.onMic});

  final VoidCallback? onTap;
  final VoidCallback? onMic;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadii.button);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 6, AppSpace.lg, 6),
      child: SizedBox(
        height: 52,
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: radius,
          child: InkWell(
            key: const Key('app-search-bar'),
            borderRadius: radius,
            onTap: onTap ?? () => context.go('/search'),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.6),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Row(
                children: [
                  Icon(Icons.search, color: scheme.onSurfaceVariant, size: 22),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      'Search atta, milk, soap…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(scheme.onSurfaceVariant),
                    ),
                  ),
                  if (onMic != null)
                    IconButton(
                      key: const Key('app-search-mic'),
                      onPressed: onMic,
                      icon: Icon(
                        Icons.mic_none,
                        color: scheme.onSurfaceVariant,
                        size: 22,
                      ),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Icon(
                      Icons.mic_none,
                      color: scheme.onSurfaceVariant,
                      size: 22,
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
