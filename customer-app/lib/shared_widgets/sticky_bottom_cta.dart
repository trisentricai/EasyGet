import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';

/// 54dp bottom-anchored full-width primary CTA.
/// Mirrors React StickyBottomCta component.
class StickyBottomCta extends StatelessWidget {
  const StickyBottomCta({
    super.key,
    required this.label,
    this.price,
    this.onPressed,
    this.isLoading = false,
    this.enabled = true,
  });

  final String label;
  final int? price;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.freshColors;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewPadding.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      minimum: EdgeInsets.only(bottom: bottomInset + 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: enabled && !isLoading ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: enabled ? colors.primary : colors.primary.withValues(alpha: 0.4),
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (price != null) ...[
                        Text(
                          '₹$price',
                          style: AppTypography.tabularPrice(
                            colors.onPrimary,
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        label,
                        style: AppTypography.label(colors.onPrimary, size: 16),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}