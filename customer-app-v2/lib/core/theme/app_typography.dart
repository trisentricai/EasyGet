import 'package:flutter/material.dart';

/// Apple-style typography: the platform system sans (SF Pro on Apple
/// platforms, Roboto on Android), size-specific tracking, inverse leading and
/// tabular figures for every number. No display serif and no runtime font
/// download — Apple headlines are the system face, tightened, not a different
/// typeface.
class AppTypography {
  static TextStyle _sans({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double height = 1.45,
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

  // Display / Hero — large title: tight tracking, tight leading.
  static TextStyle displayHero(Color color) => _sans(
        fontSize: 34,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -1.2,
        height: 1.1,
      );

  static TextStyle sectionHeadline(Color color) => _sans(
        fontSize: 22,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: -0.5,
        height: 1.15,
      );

  // Screen titles
  static TextStyle screenTitle(Color color) => _sans(
        fontSize: 20,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // Product names
  static TextStyle productName(Color color, {double size = 15}) => _sans(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.3,
      );

  // Body — Apple body is 17pt with comfortable leading.
  static TextStyle body(Color color, {double size = 17}) => _sans(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle bodyMedium(Color color, {double size = 15}) => _sans(
        fontSize: size,
        weight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle caption(Color color, {double size = 13}) => _sans(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.35,
      );

  // Labels (tabs, chips, ETA) — small text gets slight positive tracking.
  static TextStyle label(Color color, {double size = 14}) => _sans(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0.1,
        height: 1.3,
      );

  // Tabular figures — EVERY number (price, qty, ETA, order ID, rating).
  static TextStyle tabularPrice(Color color,
          {double size = 17, FontWeight weight = FontWeight.w700}) =>
      _sans(
        fontSize: size,
        weight: weight,
        color: color,
        letterSpacing: -0.4,
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
