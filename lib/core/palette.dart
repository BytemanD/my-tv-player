import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A theme's full colour set.
///
/// Every Luma theme is built from exactly three authored colours:
///   - [primary] — the main interactive/CTA hue (never for body copy),
///   - [accent]  — the secondary brand hue,
///   - [surface] — the panel/card colour,
/// plus supporting roles derived or authored per theme. Roles, not specific
/// widgets, so screens can paint themselves without change.
final class LumaPalette {
  const LumaPalette({
    required this.primary,
    required this.accent,
    required this.surface,
    required this.background,
    required this.backgroundSoft,
    required this.surfaceHigh,
    required this.surfaceGlass,
    required this.line,
    required this.lineSoft,
    required this.primaryDeep,
    required this.primarySoft,
    required this.accentDeep,
    required this.accentSoft,
    required this.text,
    required this.textDim,
    required this.textMuted,
    required this.textOnSurface,
    required this.textDimOnSurface,
    required this.textMutedOnSurface,
    required this.danger,
    required this.success,
  });

  // --- The three authored colours -------------------------------------
  final Color primary;
  final Color accent;
  final Color surface;

  // --- Structure --------------------------------------------------------
  final Color background;
  final Color backgroundSoft;
  final Color surfaceHigh;
  final Color surfaceGlass;
  final Color line;
  final Color lineSoft;

  // --- Primary companions ------------------------------------------------
  /// Deeper shade of [primary] (borders on filled surfaces).
  final Color primaryDeep;

  /// [primary] at low alpha — selection/focus fills.
  final Color primarySoft;

  // --- Accent companions --------------------------------------------------
  final Color accentDeep;
  final Color accentSoft;

  // --- Text (on background) ------------------------------------------------
  final Color text;
  final Color textDim;
  final Color textMuted;

  // --- Text (on surface) ---------------------------------------------------
  /// Same roles, but for content drawn ON light surfaces. In dark-byzantium
  /// these stay dark (cards are light); everywhere else they match [text].
  final Color textOnSurface;
  final Color textDimOnSurface;
  final Color textMutedOnSurface;

  // --- Feedback -------------------------------------------------------------
  final Color danger;
  final Color success;

  /// Black or white text on [fill], picking whichever has better contrast.
  static Color onColorFor(Color fill) {
    final againstBlack = _contrastRatio(fill, const Color(0xFF181818));
    final againstWhite = _contrastRatio(fill, const Color(0xFFFFFFFF));
    return againstBlack >= againstWhite
        ? const Color(0xFF181818)
        : const Color(0xFFFFFFFF);
  }

  static double _contrastRatio(Color a, Color b) {
    final la = _relativeLuminance(a);
    final lb = _relativeLuminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double channel(double value) {
      return value <= 0.03928
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(((color.r * 255).round() & 0xff) / 255.0);
    final g = channel(((color.g * 255).round() & 0xff) / 255.0);
    final b = channel(((color.b * 255).round() & 0xff) / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }
}
