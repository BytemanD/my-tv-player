import 'package:flutter/material.dart';

import 'palette.dart';
import 'themes.dart';
import 'theme_option.dart';

/// The active palette handle for call-sites: screens keep reading semantic
/// roles and never touch theme ids directly.
abstract final class LumaColors {
  static LumaThemeOption _option = LumaThemes.classic;
  static Brightness _brightness = Brightness.dark;

  static void apply(String themeId, Brightness brightness) {
    _option = LumaThemes.byId(themeId);
    _brightness = brightness;
  }

  static Brightness get brightness => _brightness;
  static String get themeId => _option.id;
  static LumaThemeOption get option => _option;

  static LumaPalette get _p =>
      _brightness == Brightness.dark ? _option.dark : _option.light;

  // Structure
  static Color get background => _p.background;
  static Color get backgroundSoft => _p.backgroundSoft;
  static Color get surface => _p.surface;
  static Color get surfaceHigh => _p.surfaceHigh;
  static Color get surfaceGlass => _p.surfaceGlass;
  static Color get line => _p.line;
  static Color get lineSoft => _p.lineSoft;

  // Primary
  static Color get primary => _p.primary;
  static Color get primaryDeep => _p.primaryDeep;
  static Color get primarySoft => _p.primarySoft;

  /// Readable text on top of [primary].
  static Color get onPrimary => LumaPalette.onColorFor(_p.primary);

  // Accent
  static Color get accent => _p.accent;
  static Color get accentDeep => _p.accentDeep;
  static Color get accentSoft => _p.accentSoft;

  /// Readable text on top of [accent].
  static Color get onAccent => LumaPalette.onColorFor(_p.accent);

  // Text — background
  static Color get text => _p.text;
  static Color get textDim => _p.textDim;
  static Color get textMuted => _p.textMuted;

  // Text — surface
  static Color get textOnSurface => _p.textOnSurface;
  static Color get textDimOnSurface => _p.textDimOnSurface;
  static Color get textMutedOnSurface => _p.textMutedOnSurface;

  // Feedback
  static Color get danger => _p.danger;
  static Color get success => _p.success;
}
