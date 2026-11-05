import 'package:flutter/material.dart';

import '../theme_option.dart';
import '../palette.dart';

/// 拜占庭
/// plum-black canvas, byzantine purple as primary, antique-gold as accent —
/// the Byzantiun royal set (拜占庭紫 #4F3A70 · 圣像金 #C49C4D · 石膏灰白 #DAD2C6).
/// Dark variant: same primary/accent/surface as light, only the canvas flips
/// dark (temporary, the dark identity is undecided).
const byzantiumDark = LumaPalette(
  primary: Color(0xFF4F3A70),
  primaryDeep: Color(0xFF3A2A55),
  primarySoft: Color(0x244F3A70),
  accent: Color(0xFFA87F35),
  accentDeep: Color(0xFF6F5620),
  accentSoft: Color(0x33A87F35),
  surface: Color.fromARGB(255, 26, 26, 24),
  background: Color(0xFF16111F),
  backgroundSoft: Color(0xFF1B1626),
  surfaceHigh: Color(0xFFDFDCD1),
  surfaceGlass: Color(0xFFEFEEE7),
  line: Color(0xFFC9C3B6),
  lineSoft: Color(0xFFD8D4C9),
  text: Color(0xFFE9E3D8),
  textDim: Color(0xFFB9B1A5),
  textMuted: Color(0xFF847E91),
  textOnSurface: Color(0xFF332B45),
  textDimOnSurface: Color(0xFF4F4859),
  textMutedOnSurface: Color(0xFF7A7364),
  danger: Color(0xFFE07373),
  success: Color(0xFF7BD3A5),
);

const byzantiumLight = LumaPalette(
  primary: Color(0xFF4F3A70),
  primaryDeep: Color(0xFF3A2A55),
  primarySoft: Color(0x244F3A70),
  accent: Color(0xFFA87F35),
  accentDeep: Color(0xFF6F5620),
  accentSoft: Color(0x33A87F35),
  surface: Color(0xFFEFEEE7),
  background: Color(0xFFE8E4DA),
  backgroundSoft: Color(0xFFDAD2C6),
  surfaceHigh: Color(0xFFDFDCD1),
  surfaceGlass: Color(0xFFEFEEE7),
  line: Color(0xFFC9C3B6),
  lineSoft: Color(0xFFD8D4C9),
  text: Color(0xFF332B45),
  textDim: Color(0xFF4F4859),
  textMuted: Color(0xFF7A7364),
  textOnSurface: Color(0xFF332B45),
  textDimOnSurface: Color(0xFF4F4859),
  textMutedOnSurface: Color(0xFF7A7364),
  danger: Color(0xFFC24E4E),
  success: Color(0xFF2E7D5B),
);

const byzantiumTheme = LumaThemeOption(
  id: 'byzantium',
  name: '拜占庭',
  hint: '紫金帝王色',
  swatches: [Color(0xFF16111F), Color(0xFF4F3A70), Color(0xFFC49C4D)],
  dark: byzantiumDark,
  light: byzantiumLight,
);
