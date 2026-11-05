import 'package:easyget/core/theme/storefront_appearance.dart';
import 'package:easyget/features/account/presentation/account_providers.dart';
import 'package:easyget/models/storefront_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreTheme mobile appearance', () {
    test('decodes the admin payload', () {
      final theme = StoreTheme.fromJson(const {
        'enable_glassmorphism': false,
        'glass_blur_intensity': 24,
        'mobile_default_theme': 'DARK',
      });

      expect(theme.enableGlassmorphism, isFalse);
      expect(theme.glassBlurIntensity, 24);
      expect(theme.mobileDefaultTheme, 'DARK');
    });

    test('defaults when the payload predates the settings', () {
      final theme = StoreTheme.fromJson(const {
        'primary_color': '#16a34a',
      });

      expect(theme.enableGlassmorphism, isTrue);
      expect(theme.glassBlurIntensity, 16);
      expect(theme.mobileDefaultTheme, 'SYSTEM');
    });

    test('clamps blur intensity to the backend 0–40 range', () {
      expect(
        StoreTheme.fromJson(const {'glass_blur_intensity': 99})
            .glassBlurIntensity,
        40,
      );
      expect(
        StoreTheme.fromJson(const {'glass_blur_intensity': -5})
            .glassBlurIntensity,
        0,
      );
    });
  });

  group('StorefrontAppearance', () {
    test('maps mobile_default_theme to a ThemeMode', () {
      expect(
        StorefrontAppearance.fromTheme(
          const StoreTheme(mobileDefaultTheme: 'LIGHT'),
        ).themeMode,
        ThemeMode.light,
      );
      expect(
        StorefrontAppearance.fromTheme(
          const StoreTheme(mobileDefaultTheme: 'DARK'),
        ).themeMode,
        ThemeMode.dark,
      );
      expect(
        StorefrontAppearance.fromTheme(
          const StoreTheme(mobileDefaultTheme: 'SYSTEM'),
        ).themeMode,
        ThemeMode.system,
      );
    });

    test('explicit shopper choice wins over the admin default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(storefrontAppearanceProvider.notifier).apply(
            const StoreTheme(mobileDefaultTheme: 'DARK'),
          );
      expect(container.read(effectiveThemeModeProvider), ThemeMode.dark);

      container.read(themeModeProvider.notifier).set(ThemeMode.light);
      expect(container.read(effectiveThemeModeProvider), ThemeMode.light);
    });

    test('auto follows a refreshed admin default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(storefrontAppearanceProvider.notifier).apply(
            const StoreTheme(mobileDefaultTheme: 'LIGHT'),
          );
      expect(container.read(effectiveThemeModeProvider), ThemeMode.light);

      container.read(storefrontAppearanceProvider.notifier).apply(
            const StoreTheme(mobileDefaultTheme: 'DARK'),
          );
      expect(container.read(effectiveThemeModeProvider), ThemeMode.dark);
    });
  });
}
