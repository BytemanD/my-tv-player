import 'package:flutter/material.dart';

import 'luma_colors.dart';

abstract final class LumaTheme {
  static const displayFont = 'sans-serif-condensed';

  static ThemeData build() {
    final isDark = LumaColors.brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: LumaColors.primary,
      onPrimary: LumaColors.onPrimary,
      secondary: LumaColors.accent,
      onSecondary: LumaColors.onAccent,
      surface: LumaColors.surface,
      onSurface: LumaColors.textOnSurface,
      error: LumaColors.danger,
      onError: Colors.white,
      outline: LumaColors.line,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: LumaColors.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
    );

    final textTheme = base.textTheme
        .apply(
          bodyColor: LumaColors.textOnSurface,
          displayColor: LumaColors.textOnSurface,
        )
        .copyWith(
          displayLarge: TextStyle(
            fontFamily: displayFont,
            fontSize: 66,
            height: 0.98,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.2,
            color: LumaColors.textOnSurface,
          ),
          displayMedium: TextStyle(
            fontFamily: displayFont,
            fontSize: 48,
            height: 1.02,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            color: LumaColors.textOnSurface,
          ),
          headlineMedium: TextStyle(
            fontSize: 30,
            height: 1.15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: LumaColors.textOnSurface,
          ),
          titleLarge: TextStyle(
            fontSize: 21,
            height: 1.25,
            fontWeight: FontWeight.w600,
            color: LumaColors.textOnSurface,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            height: 1.3,
            fontWeight: FontWeight.w500,
            color: LumaColors.textOnSurface,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.55,
            color: LumaColors.textDimOnSurface,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: LumaColors.textDimOnSurface,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: LumaColors.textOnSurface,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
            color: LumaColors.textMutedOnSurface,
          ),
        );

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: LumaColors.lineSoft,
      iconTheme: IconThemeData(color: LumaColors.textDimOnSurface, size: 22),
      dialogTheme: DialogThemeData(
        backgroundColor: LumaColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LumaColors.surfaceHigh,
        hintStyle: TextStyle(color: LumaColors.textMuted),
        labelStyle: TextStyle(color: LumaColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LumaColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LumaColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LumaColors.primary, width: 1.6),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: LumaPageTransitionsBuilder()},
      ),
    );
  }
}

class LumaPageTransitionsBuilder extends PageTransitionsBuilder {
  const LumaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.015, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
