import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// EasyGet Fresh Market — normative typography tokens (DESIGN.md §10.4).
/// Product names NEVER use serif. EVERY number uses tabular figures.
class AppTypography {
  static TextStyle _fraunces({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double letterSpacing = -0.5,
    double height = 1.15,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );

  static TextStyle _inter({
    required double fontSize,
    required FontWeight weight,
    required Color color,
    double letterSpacing = 0,
    double height = 1.55,
    bool tabular = false,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
        fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
      );

  // Display / Hero
  static TextStyle displayHero(Color color) => _fraunces(
        fontSize: 28,
        weight: FontWeight.w600,
        color: color,
      );

  static TextStyle sectionHeadline(Color color) => _fraunces(
        fontSize: 24,
        weight: FontWeight.w500,
        color: color,
      );

  // Screen titles
  static TextStyle screenTitle(Color color) => _inter(
        fontSize: 20,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: -0.25,
        height: 1.25,
      );

  // Product names (ALWAYS Inter)
  static TextStyle productName(Color color, {double size = 14}) => _inter(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: -0.15,
        height: 1.3,
      );

  // Body
  static TextStyle body(Color color, {double size = 15}) => _inter(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.55,
      );

  static TextStyle bodyMedium(Color color, {double size = 14}) => _inter(
        fontSize: size,
        weight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle caption(Color color, {double size = 12}) => _inter(
        fontSize: size,
        weight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  // Labels (tabs, chips, ETA)
  static TextStyle label(Color color, {double size = 13}) => _inter(
        fontSize: size,
        weight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
        height: 1.3,
      );

  // Tabular figures — EVERY number (price, qty, ETA, order ID, rating)
  static TextStyle tabularPrice(Color color,
          {double size = 16, FontWeight weight = FontWeight.w700}) =>
      _inter(
        fontSize: size,
        weight: weight,
        color: color,
        letterSpacing: -0.2,
        tabular: true,
      );

  static TextStyle tabularNumber(Color color,
          {double size = 13, FontWeight weight = FontWeight.w500}) =>
      _inter(
        fontSize: size,
        weight: weight,
        color: color,
        letterSpacing: 0.1,
        tabular: true,
      );

  static TextStyle tabularSmall(Color color,
          {double size = 11, FontWeight weight = FontWeight.w400}) =>
      _inter(
        fontSize: size,
        weight: weight,
        color: color,
        tabular: true,
      );
}
