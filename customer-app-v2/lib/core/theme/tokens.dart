import 'package:flutter/material.dart';

/// EasyGet Fresh Market — normative color tokens.
/// Zero hardcoded hex/px outside `core/theme/`.
///
/// Palette reverse-engineered from the live Zepto storefront
/// (`design-reference/zepto-uiux-design.md`): pink CTAs, deep-purple ink and a
/// green price tag with a hard offset edge. Token names are retained so every
/// existing surface retones from one place.
class AppColors {
  // Light — flat white Zepto surfaces.
  static const Color lightCanvas = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSunken = Color(0xFFF7F8FA);
  static const Color lightInk = Color(0xFF101418);
  static const Color lightMuted = Color(0xFF586274);
  static const Color lightFaint = Color(0xFF707686);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderStrong = Color(0xFFD3D8E0);

  // Brand accents — pink is the action colour, purple the ink/ETA colour.
  static const Color brand = Color(0xFF2B1E35);
  static const Color primary = Color(0xFFF9105E);
  static const Color primaryDark = Color(0xFFD9004F);
  static const Color primaryTint = Color(0xFFFFF0F5);
  static const Color marigold = Color(0xFFE79B12);
  static const Color marigoldWash = Color(0xFFFCEFD4);

  // Zepto signature surfaces.
  static const Color purple = Color(0xFF332060);
  static const Color priceGreen = Color(0xFF329537);
  static const Color priceEdge = Color(0xFF084121);

  // System Feedback
  static const Color success = Color(0xFF329537);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFE11D48);

  // Renamed tokens retained for source compatibility.
  static const Color champagne = Color(0xFFFFFFFF);
  static const Color champagneDeep = Color(0xFFE5E7EB);
  static const Color darkChampagne = Color(0xFF1D1722);
  static const Color darkChampagneDeep = Color(0xFF342A3B);
  static const Color obsidian = Color(0xFF101418);
  static const Color obsidianGlass = Color(0xE6101418);
  static const Color champagneInk = Color(0xFFFFFFFF);

  // Category card wash backgrounds (stable per-category hues when images are null)
  static const Color categoryWashDanger = Color(0xFFFFE9EE);
  static const Color categoryWashWarning = Color(0xFFFCF0DA);
  static const Color categoryWashSuccess = Color(0xFFE4F5E8);
  static const Color categoryWashInfo = Color(0xFFE8EEFB);

  // Dark — Zepto ink-purple palette
  static const Color darkCanvas = Color(0xFF141017);
  static const Color darkSurface = Color(0xFF1D1722);
  static const Color darkSunken = Color(0xFF261F2C);
  static const Color darkInk = Color(0xFFF7F3F7);
  static const Color darkMuted = Color(0xFFB6AEBD);
  static const Color darkFaint = Color(0xFF8C8192);
  static const Color darkBorder = Color(0xFF342A3B);
  static const Color darkBorderStrong = Color(0xFF4B3F53);
  static const Color darkPrimary = Color(0xFFFF3269);
  static const Color darkPrimaryTint = Color(0xFF3B1429);
  static const Color darkMarigold = Color(0xFFFFB020);
  static const Color darkMarigoldWash = Color(0xFF3A2C10);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkPurple = Color(0xFFFFB0CD);
  static const Color darkPriceGreen = Color(0xFF5CC46A);
  static const Color darkPriceEdge = Color(0xFF9BE0A3);
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

/// Corner radii — Zepto: compact 8–12pt corners, pills only for count badges.
class AppRadii {
  const AppRadii._();
  static const double card = 12;
  static const double image = 8;
  static const double button = 8;
  static const double input = 8;
  static const double snackbar = 8;
  static const double sheet = 12;
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

  /// Zepto signature colours: deep-purple ink, green price tag + hard edge.
  Color get purple;
  Color get priceGreen;
  Color get priceEdge;

  /// Champagne Minimalist card surface (+ deeper edge for borders).
  Color get champagne;
  Color get champagneDeep;

  /// Glass Morphism card surface (frosted fill) + border (subtle edge).
  /// Works in both light and dark modes.
  Color get glassSurface;
  Color get glassBorder;

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
  Color get purple => AppColors.purple;
  @override
  Color get priceGreen => AppColors.priceGreen;
  @override
  Color get priceEdge => AppColors.priceEdge;
  @override
  Color get champagne => AppColors.champagne;
  @override
  Color get champagneDeep => AppColors.champagneDeep;
  @override
  Color get glassSurface => AppColors.lightCanvas; // flat white card
  @override
  Color get glassBorder => AppColors.lightBorder; // hairline separator
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
  Color get onPrimary => AppColors.darkOnPrimary;
  @override
  Color get purple => AppColors.darkPurple;
  @override
  Color get priceGreen => AppColors.darkPriceGreen;
  @override
  Color get priceEdge => AppColors.darkPriceEdge;
  @override
  Color get champagne => AppColors.darkChampagne;
  @override
  Color get champagneDeep => AppColors.darkChampagneDeep;
  @override
  Color get glassSurface => AppColors.darkSurface;
  @override
  Color get glassBorder => AppColors.darkBorder;
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
