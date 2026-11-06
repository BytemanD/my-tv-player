import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme_option.dart';

/// 石榴奶杏
/// 石榴红 #B5485D (primary) + 奶杏白 #F3E2D1 (accent).
/// Light: surface 奶杏白（浅），Dark: surface 深褐色（深，和 light 相反）。
const pomegranateLight = LumaPalette(
  primary: Color(0xFFB5485D),
  primaryDeep: Color(0xFF8F3846),
  primarySoft: Color(0x40B5485D),
  accent: Color(0xFFF3E2D1),
  accentDeep: Color(0xFFC9B2A0),
  accentSoft: Color(0x40F3E2D1),
  surface: Color(0xFFF3E2D1),
  background: Color(0xFFFBF6F2),
  backgroundSoft: Color(0xFFF2E8DE),
  surfaceHigh: Color(0xFFEBD9CC),
  surfaceGlass: Color(0xFFF3E2D1),
  line: Color(0xFFE8D8CB),
  lineSoft: Color(0xFFF2E8DE),
  text: Color(0xFF3A2A28),
  textDim: Color(0xFF6B5550),
  textMuted: Color(0xFF9B8780),
  textOnSurface: Color(0xFF3A2A28),
  textDimOnSurface: Color(0xFF6B5550),
  textMutedOnSurface: Color(0xFF9B8780),
  danger: Color(0xFFC24E4E),
  success: Color(0xFF2E7D5B),
);

const pomegranateDark = LumaPalette(
  primary: Color(0xFFB5485D),
  primaryDeep: Color(0xFF8F3846),
  primarySoft: Color(0x40B5485D),
  accent: Color(0xFFF3E2D1),
  accentDeep: Color(0xFFC9B2A0),
  accentSoft: Color(0x40F3E2D1),
  surface: Color(0xFF1E1616),
  background: Color(0xFF140F0F),
  backgroundSoft: Color(0xFF1A1515),
  surfaceHigh: Color(0xFF2B1E1E),
  surfaceGlass: Color(0xFF1E1616),
  line: Color(0xFF3A2A28),
  lineSoft: Color(0xFF251B1B),
  text: Color(0xFFF3E2D1),
  textDim: Color(0xFFC8B2A8),
  textMuted: Color(0xFF8F7B74),
  textOnSurface: Color(0xFFF3E2D1),
  textDimOnSurface: Color(0xFFC8B2A8),
  textMutedOnSurface: Color(0xFF8F7B74),
  danger: Color(0xFFE07373),
  success: Color(0xFF7BD3A5),
);

const pomegranateTheme = LumaThemeOption(
  id: 'pomegranate',
  name: '石榴奶杏',
  hint: '石榴红 × 奶杏白',
  swatches: [Color(0xFFB5485D), Color(0xFFF3E2D1), Color(0xFFF3E2D1)],
  dark: pomegranateDark,
  light: pomegranateLight,
);
