import 'package:flutter/material.dart';

import '../theme_option.dart';
import '../palette.dart';

/// 经典（Luma 原版黑金）
/// near-black canvas, warm champagne accent.
const classicDark = LumaPalette(
  primary: Color(0xFFE9C57E),
  primaryDeep: Color(0xFFC9A45D),
  primarySoft: Color(0x2EE9C57E),
  accent: Color(0xFFA68F5E),
  accentDeep: Color(0xFF7A6841),
  accentSoft: Color(0x24A68F5E),
  surface: Color(0xFF12141A),
  background: Color(0xFF07080B),
  backgroundSoft: Color(0xFF0B0D12),
  surfaceHigh: Color(0xFF1A1D25),
  surfaceGlass: Color(0xE61A1D25),
  line: Color(0xFF262A34),
  lineSoft: Color(0xFF1B1E26),
  text: Color(0xFFF4F1EA),
  textDim: Color(0xFFB0B2BB),
  textMuted: Color(0xFF7C7F89),
  textOnSurface: Color(0xFFF4F1EA),
  textDimOnSurface: Color(0xFFB0B2BB),
  textMutedOnSurface: Color(0xFF7C7F89),
  danger: Color(0xFFE07373),
  success: Color(0xFF7BD3A5),
);

const classicLight = LumaPalette(
  primary: Color(0xFFB9924C),
  primaryDeep: Color(0xFF8F6F31),
  primarySoft: Color(0x29B9924C),
  accent: Color(0xFF6F5E36),
  accentDeep: Color(0xFF4C3F22),
  accentSoft: Color(0x296F5E36),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFFAF9F6),
  backgroundSoft: Color(0xFFF0EEE8),
  surfaceHigh: Color(0xFFE8E6DE),
  surfaceGlass: Color(0xFFF2F1EC),
  line: Color(0xFFDDDAD0),
  lineSoft: Color(0xFFE9E7DE),
  text: Color(0xFF201F1B),
  textDim: Color(0xFF4B483F),
  textMuted: Color(0xFF7B786D),
  textOnSurface: Color(0xFF201F1B),
  textDimOnSurface: Color(0xFF4B483F),
  textMutedOnSurface: Color(0xFF7B786D),
  danger: Color(0xFFC24E4E),
  success: Color(0xFF2E7D5B),
);

const classicTheme = LumaThemeOption(
  id: 'classic',
  name: '经典',
  hint: 'Luma 原版黑金',
  swatches: [Color(0xFF07080B), Color(0xFF1A1D25), Color(0xFFE9C57E)],
  dark: classicDark,
  light: classicLight,
);
