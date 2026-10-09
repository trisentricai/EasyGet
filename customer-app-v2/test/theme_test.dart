import 'dart:io';

import 'package:easyget/core/theme/app_theme.dart';
import 'package:easyget/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lightAndDarkSchemesAreDefinedAndDistinct', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    expect(light.colorScheme.primary, AppColors.primary);
    expect(dark.colorScheme.primary, AppColors.darkPrimary);
    expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));

    expect(light.extension<FreshMarketLightColors>(), isNotNull);
    expect(dark.extension<FreshMarketDarkColors>(), isNotNull);
    expect(const FreshMarketLightColors().primary, AppColors.primary);
    expect(const FreshMarketLightColors().marigold, AppColors.marigold);
    expect(const FreshMarketDarkColors().primary, AppColors.darkPrimary);
    expect(const FreshMarketDarkColors().onPrimary, Colors.white);
  });

  test('zeroColorLiteralsOutsideTheme', () {
    final offenders = <String>[];
    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final path = entry.path.replaceAll(r'\', '/');
      if (path.contains('core/theme/')) continue;
      if (entry.readAsStringSync().contains('Color(0x')) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'Color literals must live in core/theme only: $offenders');
  });
}
