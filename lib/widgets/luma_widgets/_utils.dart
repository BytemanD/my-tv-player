import 'package:flutter/material.dart';

Color estimateFrontColor(Color backgroundColor) {
  final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
  return brightness == Brightness.dark ? Colors.white : Colors.black;
}
