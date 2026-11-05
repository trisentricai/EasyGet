import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/storefront_models.dart';

/// Runtime mirror of the Admin Panel's "Mobile app appearance" settings.
///
/// The storefront render already carries these values; this synchronous
/// projection lets [MaterialApp] and every [ProductCard] react to an admin
/// edit without re-reading the payload or waiting on another request.
@immutable
class StorefrontAppearance {
  const StorefrontAppearance({
    this.enableGlassmorphism = true,
    this.glassBlurIntensity = 16,
    this.themeMode = ThemeMode.system,
  });

  factory StorefrontAppearance.fromTheme(StoreTheme theme) =>
      StorefrontAppearance(
        enableGlassmorphism: theme.enableGlassmorphism,
        glassBlurIntensity: theme.glassBlurIntensity,
        themeMode: switch (theme.mobileDefaultTheme) {
          'LIGHT' => ThemeMode.light,
          'DARK' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
      );

  final bool enableGlassmorphism;
  final double glassBlurIntensity;
  final ThemeMode themeMode;
}

class StorefrontAppearanceController extends Notifier<StorefrontAppearance> {
  @override
  StorefrontAppearance build() => const StorefrontAppearance();

  /// Called after `/storefront/platform/` loads (first paint and pull-to-
  /// refresh), so admin edits apply without an app release.
  void apply(StoreTheme theme) {
    state = StorefrontAppearance.fromTheme(theme);
  }
}

final storefrontAppearanceProvider =
    NotifierProvider<StorefrontAppearanceController, StorefrontAppearance>(
  StorefrontAppearanceController.new,
);
