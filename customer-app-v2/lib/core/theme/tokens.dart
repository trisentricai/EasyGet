import 'package:flutter/material.dart';

/// EasyGet Fresh Market — normative color tokens (DESIGN.md §10).
/// Zero hardcoded hex/px outside `core/theme/`.
class AppColors {
  // Light — Warm Paper & Forest Leaf
  static const Color lightCanvas = Color(0xFFFAF6EF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSunken = Color(0xFFF1EAE0);
  static const Color lightInk = Color(0xFF1B1712);
  static const Color lightMuted = Color(0xFF655D52);
  static const Color lightFaint = Color(0xFFA79C8F);
  static const Color lightBorder = Color(0xFFE7DFD3);
  static const Color lightBorderStrong = Color(0xFFD5C9B8);

  // Brand Accents
  static const Color brand = Color(0xFF0C3B2E);
  static const Color primary = Color(0xFF0E7A4D);
  static const Color primaryDark = Color(0xFF0A5C3B);
  static const Color primaryTint = Color(0xFFDDF0E4);
  static const Color marigold = Color(0xFFE79B12);
  static const Color marigoldWash = Color(0xFFFCEFD4);

  // System Feedback
  static const Color success = Color(0xFF15803D);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFB91C1C);

  // Champagne Minimalist (grid cards) + Obsidian Glass (overlays)
  static const Color champagne = Color(0xFFF7EFDD);
  static const Color champagneDeep = Color(0xFFEFE0C2);
  static const Color darkChampagne = Color(0xFF2A241B);
  static const Color darkChampagneDeep = Color(0xFF38301F);
  static const Color obsidian = Color(0xFF141210);
  static const Color obsidianGlass = Color(0xB3141210);
  static const Color champagneInk = Color(0xFFF7EFDD);

  // Category card wash backgrounds (stable per-category hues when images are null)
  static const Color categoryWashDanger = Color(0xFFFDECEA);
  static const Color categoryWashWarning = Color(0xFFFDF3E0);
  static const Color categoryWashSuccess = Color(0xFFE8F5E9);
  static const Color categoryWashInfo = Color(0xFFE3F2FD);

  // Dark — Warm Charcoal (never pure #000)
  static const Color darkCanvas = Color(0xFF12110F);
  static const Color darkSurface = Color(0xFF1B1A17);
  static const Color darkSunken = Color(0xFF26241F);
  static const Color darkInk = Color(0xFFF4EFE7);
  static const Color darkMuted = Color(0xFFA79C8F);
  static const Color darkFaint = Color(0xFF6F675C);
  static const Color darkBorder = Color(0xFF2B2823);
  static const Color darkBorderStrong = Color(0xFF3E3A33);
  static const Color darkPrimary = Color(0xFF3AA76D);
  static const Color darkPrimaryTint = Color(0xFF14342A);
  static const Color darkMarigold = Color(0xFFFFB020);
  static const Color darkMarigoldWash = Color(0xFF3A2C10);
  static const Color darkOnPrimary = Color(0xFF06281C);
}

/// Spacing scale (DESIGN §10.5) — 4pt base, no odd numbers.
class AppSpace {
  const AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// Corner radii (DESIGN §10.6).
class AppRadii {
  const AppRadii._();
  static const double card = 18;
  static const double image = 14;
  static const double button = 16;
  static const double input = 14;
  static const double snackbar = 14;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Motion durations + easing (DESIGN §10.8). Reduced motion is honoured by
/// consumers skipping the rise/slide while keeping fades ≤ [micro].
class AppMotion {
  const AppMotion._();
  static const Duration micro = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 280);
  static const Duration page = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOutCubic;
}

/// Token getters shared by the light and dark color extensions.
abstract class FreshMarketColorTokens {
  Color get brand;
  Color get primary;
  Color get primaryTint;
  Color get primaryDark;
  Color get marigold;
  Color get marigoldWash;
  Color get sunken;
  Color get ink;
  Color get muted;
  Color get faint;
  Color get success;
  Color get danger;
  Color get warning;
  Color get onPrimary;

  /// Champagne Minimalist card surface (+ deeper edge for borders).
  Color get champagne;
  Color get champagneDeep;

  /// Obsidian Glass overlay (frosted dark pills, badges, Add).
  Color get obsidian;
  Color get obsidianGlass;
  Color get champagneInk;
}

/// Light color extension for brand/marigold tokens not in ColorScheme.
class FreshMarketLightColors extends ThemeExtension<FreshMarketLightColors>
    implements FreshMarketColorTokens {
  const FreshMarketLightColors();

  @override
  FreshMarketLightColors copyWith() => const FreshMarketLightColors();

  @override
  FreshMarketLightColors lerp(
          ThemeExtension<FreshMarketLightColors>? other, double t) =>
      const FreshMarketLightColors();

  @override
  Color get brand => AppColors.brand;
  @override
  Color get primary => AppColors.primary;
  @override
  Color get primaryTint => AppColors.primaryTint;
  @override
  Color get primaryDark => AppColors.primaryDark;
  @override
  Color get marigold => AppColors.marigold;
  @override
  Color get marigoldWash => AppColors.marigoldWash;
  @override
  Color get sunken => AppColors.lightSunken;
  @override
  Color get ink => AppColors.lightInk;
  @override
  Color get muted => AppColors.lightMuted;
  @override
  Color get faint => AppColors.lightFaint;
  @override
  Color get success => AppColors.success;
  @override
  Color get danger => AppColors.danger;
  @override
  Color get warning => AppColors.warning;
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get champagne => AppColors.champagne;
  @override
  Color get champagneDeep => AppColors.champagneDeep;
  @override
  Color get obsidian => AppColors.obsidian;
  @override
  Color get obsidianGlass => AppColors.obsidianGlass;
  @override
  Color get champagneInk => AppColors.champagneInk;
}

/// Dark color extension.
class FreshMarketDarkColors extends ThemeExtension<FreshMarketDarkColors>
    implements FreshMarketColorTokens {
  const FreshMarketDarkColors();

  @override
  FreshMarketDarkColors copyWith() => const FreshMarketDarkColors();

  @override
  FreshMarketDarkColors lerp(
          ThemeExtension<FreshMarketDarkColors>? other, double t) =>
      const FreshMarketDarkColors();

  @override
  Color get brand => AppColors.brand;
  @override
  Color get primary => AppColors.darkPrimary;
  @override
  Color get primaryTint => AppColors.darkPrimaryTint;
  @override
  Color get primaryDark => AppColors.darkPrimary;
  @override
  Color get marigold => AppColors.darkMarigold;
  @override
  Color get marigoldWash => AppColors.darkMarigoldWash;
  @override
  Color get sunken => AppColors.darkSunken;
  @override
  Color get ink => AppColors.darkInk;
  @override
  Color get muted => AppColors.darkMuted;
  @override
  Color get faint => AppColors.darkFaint;
  @override
  Color get success => AppColors.success;
  @override
  Color get danger => AppColors.danger;
  @override
  Color get warning => AppColors.warning;
  @override
  Color get onPrimary => Colors.white;
  @override
  Color get champagne => AppColors.darkChampagne;
  @override
  Color get champagneDeep => AppColors.darkChampagneDeep;
  @override
  Color get obsidian => AppColors.obsidian;
  @override
  Color get obsidianGlass => AppColors.obsidianGlass;
  @override
  Color get champagneInk => AppColors.champagneInk;
}

/// Convenience extension to access custom colors.
extension FreshMarketColors on ThemeData {
  FreshMarketLightColors get freshLight =>
      extension<FreshMarketLightColors>()!;
  FreshMarketDarkColors get freshDark =>
      extension<FreshMarketDarkColors>()!;

  FreshMarketColorTokens get freshColors =>
      brightness == Brightness.dark ? freshDark : freshLight;
}
