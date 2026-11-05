import 'package:flutter/material.dart';

import 'palette.dart';

/// A theme's identity. Register each theme in theme/theme files, then add it
/// to theme/themes.dart's `all` registry; the settings UI renders one tile
/// per option automatically.
final class LumaThemeOption {
  const LumaThemeOption({
    required this.id,
    required this.name,
    required this.hint,
    required this.swatches,
    required this.dark,
    required this.light,
  });

  final String id;
  final String name;
  final String hint;

  /// Three colours for the picker tile: base, lifted surface, accent.
  final List<Color> swatches;
  final LumaPalette dark;
  final LumaPalette light;
}
