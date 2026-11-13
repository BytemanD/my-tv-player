import 'package:flutter/material.dart';

class CustomTheme {
  final String name;
  final String hint;
  final Color primary;
  final Color? secondary;
  final Color? surface;

  final Color success;
  final Color danger;

  const CustomTheme(
    this.name,
    this.hint, {
    required this.primary,
    this.secondary,
    this.surface,
    this.success = Colors.green,
    this.danger = Colors.red,
  });
}

const CustomTheme classic = CustomTheme(
  "经典",
  "Luma 原版黑金",
  primary: Color(0xFFD4AF37),
  secondary: Color(0xFF8B6F47),
  // surface: Color(0xFF12141A),
);

const Map<String, CustomTheme> themes = {
  "classic": classic,
  'byzantium': CustomTheme(
    "拜占庭",
    "紫金帝王色",
    primary: Color(0xFF4F3A70),
    secondary: Color(0xFFA87F35),
    success: Color(0xFF7BD3A5),
    danger: Color(0xFFE07373),
    // surface: Color(0xFFA87F35),
  ),
  'beanSand': CustomTheme(
    "豆沙墨",
    "豆沙粉 & 墨青灰",
    primary: Color(0xFFC88697),
    secondary: Color(0xFF31424D),
    success: Color(0xFF2E7D5B),
    danger: Color(0xFFC24E4E),
    // surface: Color(0xFFA87F35),
  ),
  'pineAmber': CustomTheme(
    "松针琥珀",
    "松针绿 & 琥珀金",
    primary: Color(0xFF365B4C),
    secondary: Color(0xFFD9A441),
    success: Color(0xFF2E7D5B),
    danger: Color(0xFFC24E4E),
    // surface: Color(0xFFA87F35),
  ),
  'pomegranate': CustomTheme(
    "石榴奶杏",
    "石榴红 & 奶杏白",
    primary: Color(0xFFB5485D),
    secondary: Color(0xFFC9B2A0),
    success: Color(0xFF2E7D5B),
    danger: Color(0xFFC24E4E),
    // surface: Color(0xFFA87F35),
  ),
  'wisteria': CustomTheme(
    "藤紫",
    "紫藤花 & 橘",
    primary: Color(0xFF382372),
    secondary: Color(0xFFFF7200),
    // surface: Color(0xFFFFE9D4),
  ),
};
