import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'tokens.dart';

/// EasyGet Fresh Market — Material 3 theme built from DESIGN.md §10 tokens.
/// No hardcoded values; everything derives from AppColors + AppTypography.
class AppTheme {
  static ThemeData light() {
    const colors = FreshMarketLightColors();
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryTint,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.marigold,
      onSecondary: AppColors.lightInk,
      tertiary: AppColors.brand,
      onTertiary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightInk,
      surfaceContainerLowest: AppColors.lightCanvas,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSunken,
      surfaceContainerHigh: AppColors.lightSunken,
      surfaceContainerHighest: AppColors.lightBorder,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderStrong,
      shadow: AppColors.lightInk.withValues(alpha: 0.08),
      scrim: AppColors.lightInk.withValues(alpha: 0.4),
      inverseSurface: AppColors.darkCanvas,
      onInverseSurface: AppColors.darkInk,
      inversePrimary: AppColors.darkPrimary,
    );

    return _build(scheme, colors, isDark: false);
  }

  static ThemeData dark() {
    const colors = FreshMarketDarkColors();
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryTint,
      onPrimaryContainer: AppColors.darkInk,
      secondary: AppColors.darkMarigold,
      onSecondary: AppColors.darkCanvas,
      tertiary: AppColors.brand,
      onTertiary: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      surfaceContainerLowest: AppColors.darkCanvas,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSunken,
      surfaceContainerHigh: AppColors.darkSunken,
      surfaceContainerHighest: AppColors.darkBorder,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorderStrong,
      shadow: Colors.black.withValues(alpha: 0.3),
      scrim: Colors.black.withValues(alpha: 0.5),
      inverseSurface: AppColors.lightCanvas,
      onInverseSurface: AppColors.lightInk,
      inversePrimary: AppColors.primary,
    );

    return _build(scheme, colors, isDark: true);
  }

  static ThemeData _build(
    ColorScheme scheme,
    ThemeExtension<dynamic> colors, {
    required bool isDark,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [colors],
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surfaceContainerLowest,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: scheme.outline.withValues(alpha: 0.3),
        titleTextStyle: AppTypography.screenTitle(scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        hintStyle: AppTypography.caption(scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: AppTypography.label(scheme.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(color: scheme.outline),
          foregroundColor: scheme.onSurface,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppTypography.label(scheme.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: AppTypography.label(scheme.onSurface),
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        backgroundColor: scheme.surface,
        contentTextStyle: AppTypography.body(scheme.onSurface),
        actionTextColor: scheme.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: AppTypography.bodyMedium(scheme.onSurface),
        subtitleTextStyle: AppTypography.caption(scheme.onSurfaceVariant),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.label(scheme.primary, size: 12);
          }
          return AppTypography.label(scheme.onSurfaceVariant, size: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return IconThemeData(color: scheme.onSurfaceVariant, size: 22);
        }),
        height: 64,
      ),
    );
  }
}
