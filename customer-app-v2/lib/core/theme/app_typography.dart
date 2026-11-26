import 'package:flutter/material.dart';

/// Zepto-inspired typography: compact system sans, tight leading, utilitarian
/// weights and tabular figures for every number (price, quantity, ETA, order
/// id, rating). No runtime font download — the licensed Zepto Norms face is
/// not ours to ship, so the platform sans stack is the honest substitute.
class AppTypography {
  static TextStyle _sans({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double height = 1.3,
    bool tabular = false,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );

  static TextStyle displayHero(Color color) => _sans(
        fontSize: 30,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.8,
        height: 1.12,
      );

  static TextStyle sectionHeadline(Color color) => _sans(
        fontSize: 20,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.2,
      );

  static TextStyle screenTitle(Color color) => _sans(
        fontSize: 20,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.2,
      );

  /// Product names clamp to three lines on the web card; two is the app's
  /// grid equivalent. Weight 600 keeps long labels legible at 14pt.
  static TextStyle productName(Color color, {double size = 14}) => _sans(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle body(Color color, {double size = 14}) => _sans(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle bodyMedium(Color color, {double size = 14}) => _sans(
        fontSize: size,
        weight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle caption(Color color, {double size = 12}) => _sans(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.35,
      );

  static TextStyle label(Color color, {double size = 14}) => _sans(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0.02,
        height: 1.3,
      );

  static TextStyle tabularPrice(Color color,
          {double size = 16, FontWeight weight = FontWeight.w700}) =>
      _sans(
        fontSize: size,
        weight: weight,
        color: color,
        letterSpacing: -0.2,
        height: 1.2,
        tabular: true,
      );

  static TextStyle tabularNumber(Color color,
          {double size = 14, FontWeight weight = FontWeight.w500}) =>
      _sans(
        fontSize: size,
        weight: weight,
        color: color,
        letterSpacing: 0,
        height: 1.3,
        tabular: true,
      );

  static TextStyle tabularSmall(Color color,
          {double size = 12, FontWeight weight = FontWeight.w400}) =>
      _sans(
        fontSize: size,
        weight: weight,
        color: color,
        tabular: true,
      );
}
