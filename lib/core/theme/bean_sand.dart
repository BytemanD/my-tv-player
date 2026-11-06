import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme_option.dart';

/// 豆沙墨
/// 豆沙粉 #C88697 (primary) + 墨青灰 #31424D (accent) + 米白底 #FAF5EF.
/// Dark keeps the same authored triad; only the canvas flips dark.
const beanSandLight = LumaPalette(
  primary: Color(0xFFC88697),
  primaryDeep: Color(0xFFA96E77),
  primarySoft: Color(0x40C88697),
  accent: Color(0xFF31424D),
  accentDeep: Color(0xFF1F2B32),
  accentSoft: Color(0x4031424D),
  surface: Color(0xFFFAF5EF),
  background: Color(0xFFF5F0E8),
  backgroundSoft: Color(0xFFECE5D8),
  surfaceHigh: Color(0xFFECE5D8),
  surfaceGlass: Color(0xFFFAF5EF),
  line: Color(0xFFD8CFC4),
  lineSoft: Color(0xFFECE5D8),
  text: Color(0xFF2D2420),
  textDim: Color(0xFF5A4B45),
  textMuted: Color(0xFF8B7B74),
  textOnSurface: Color(0xFF2D2420),
  textDimOnSurface: Color(0xFF5A4B45),
  textMutedOnSurface: Color(0xFF8B7B74),
  danger: Color(0xFFC24E4E),
  success: Color(0xFF2E7D5B),
);

const beanSandDark = LumaPalette(
  primary: Color(0xFFC88697),
  primaryDeep: Color(0xFFA96E77),
  primarySoft: Color(0x40C88697),
  accent: Color(0xFF31424D),
  accentDeep: Color(0xFF1F2B32),
  accentSoft: Color(0x4031424D),
  surface: Color.fromARGB(255, 39, 39, 36),
  background: Color(0xFF1C1A1E),
  backgroundSoft: Color(0xFF222026),
  surfaceHigh: Color.fromARGB(255, 27, 26, 25),
  surfaceGlass: Color.fromARGB(255, 11, 10, 10),
  line: Color(0xFFD8CFC4),
  lineSoft: Color(0xFF222026),
  text: Color(0xFFF0E8E0),
  textDim: Color(0xFFC8B8B0),
  textMuted: Color(0xFF8F857E),
  textOnSurface: Color(0xFF2D2420),
  textDimOnSurface: Color(0xFF5A4B45),
  textMutedOnSurface: Color(0xFF8B7B74),
  danger: Color(0xFFE07373),
  success: Color(0xFF7BD3A5),
);

const beanSandTheme = LumaThemeOption(
  id: 'beanSand',
  name: '豆沙墨',
  hint: '豆沙粉 × 墨青灰',
  swatches: [Color(0xFFC88697), Color(0xFF31424D), Color(0xFFFAF5EF)],
  dark: beanSandDark,
  light: beanSandLight,
);
