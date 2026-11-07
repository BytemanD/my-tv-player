import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme_option.dart';

/// 松针琥珀
/// 松针绿 #365B4C (primary) + 琥珀金 #D9A441 (accent) + 米白底 #FCF5E5.
/// Dark keeps the same authored triad; only the canvas flips dark.
const pineAmberLight = LumaPalette(
  primary: Color(0xFF365B4C),
  primaryDeep: Color(0xFF264031),
  primarySoft: Color(0x2E365B4C),
  accent: Color(0xFFD9A441),
  accentDeep: Color(0xFFA97822),
  accentSoft: Color(0x2ED9A441),
  surface: Color(0xFFFCF5E5),
  background: Color(0xFFF1EDE0),
  backgroundSoft: Color(0xFFE7E2D4),
  surfaceHigh: Color(0xFFE6E0D1),
  surfaceGlass: Color(0xFFFCF5E5),
  line: Color(0xFFD8D0BF),
  lineSoft: Color(0xFFE7E2D4),
  text: Color(0xFF26372D),
  textDim: Color(0xFF4B5A52),
  textMuted: Color(0xFF75806F),
  textOnSurface: Color(0xFF26372D),
  textDimOnSurface: Color(0xFF4B5A52),
  textMutedOnSurface: Color(0xFF75806F),
  danger: Color(0xFFC24E4E),
  success: Color(0xFF2E7D5B),
);

const pineAmberDark = LumaPalette(
  primary: Color(0xFF365B4C),
  primaryDeep: Color(0xFF264031),
  primarySoft: Color(0x2E365B4C),
  accent: Color(0xFFD9A441),
  accentDeep: Color(0xFFA97822),
  accentSoft: Color(0x2ED9A441),
  surface: Color.fromARGB(255, 22, 22, 20),
  background: Color(0xFF1C241F),
  backgroundSoft: Color(0xFF222C26),
  surfaceHigh: Color(0xFFE6E0D1),
  surfaceGlass: Color(0xFFFCF5E5),
  line: Color.fromARGB(255, 56, 51, 50),
  lineSoft: Color.fromARGB(255, 80, 78, 73),
  text: Color(0xFFEFE6D4),
  textDim: Color(0xFFC8BFA9),
  textMuted: Color(0xFF8F8B7D),
  textOnSurface: Color(0xFF26372D),
  textDimOnSurface: Color(0xFF4B5A52),
  textMutedOnSurface: Color(0xFF75806F),
  danger: Color(0xFFE07373),
  success: Color(0xFF7BD3A5),
);

const pineAmberTheme = LumaThemeOption(
  id: 'pineAmber',
  name: '松针琥珀',
  hint: '松针绿 × 琥珀金',
  swatches: [Color(0xFF365B4C), Color(0xFFD9A441), Color(0xFFFCF5E5)],
  dark: pineAmberDark,
  light: pineAmberLight,
);
