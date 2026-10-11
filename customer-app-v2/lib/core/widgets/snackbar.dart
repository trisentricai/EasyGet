import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../theme/tokens.dart';

/// DESIGN §11.6 — floating snackbar, radius 14, ink fill / canvas text, one
/// optional action. Token-only styling.
void showAppSnackbar(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final scheme = Theme.of(context).colorScheme;
  final colors = Theme.of(context).freshColors;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.body(scheme.onInverseSurface)),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.snackbar),
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: colors.marigold,
                onPressed: () => onAction?.call(),
              ),
      ),
    );
}