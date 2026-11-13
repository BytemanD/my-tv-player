import 'package:flutter/material.dart';
import 'package:luma_tv/core/common/preference.dart';
import 'package:luma_tv/core/common/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({required this.success, required this.danger});

  final Color success;
  final Color danger;

  @override
  SemanticColors copyWith({Color? success, Color? danger}) {
    return SemanticColors(
      success: success ?? this.success,
      danger: danger ?? this.danger,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

class ThemeItem {
  final String id;
  final String name;
  final String hint;

  const ThemeItem(this.id, this.name, this.hint);
}

AppTheme _getAppTheme({String? themeId, bool? dark}) {
  themeId = themeId ?? "classic";
  dark = dark ?? true;
  final theme = themes[themeId]!;
  return AppTheme(
    id: themeId,
    dark: dark,
    themeData: ThemeData(
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: theme.primary,
            brightness: dark ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: theme.primary,
            secondary: theme.secondary,
            surface: theme.surface,
          ),
      fontFamily: 'sans-serif-condensed',
      extensions: [
        SemanticColors(success: theme.success, danger: theme.danger),
      ],
    ),
  );
}

class AppTheme {
  final String id;
  final bool dark;
  final ThemeData themeData;

  new({required this.id, required this.dark, required this.themeData});
}

class ThemeController extends ChangeNotifier {
  final SharedPreferencesWithCache prefs;

  AppTheme appTheme = _getAppTheme();

  new(this.prefs);

  void load() async {
    appTheme = _getAppTheme(
      themeId: prefs.getString(Options.kThemeId.key),
      dark: prefs.getBool(Options.kThemeMode.key),
    );
  }

  List<ThemeItem> getThemes() {
    return themes.entries.map((x) {
      return ThemeItem(x.key, x.value.name, x.value.hint);
    }).toList();
  }

  Future<void> setDark(bool value) async {
    if (appTheme.dark == value) {
      return;
    }
    appTheme = _getAppTheme(themeId: appTheme.id, dark: value);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    if (themes[value] == null) {
      throw Exception("invalid theme: $value");
    }
    if (appTheme.id == value) {
      return;
    }
    await prefs.setString(Options.kThemeId.key, value);
    appTheme = _getAppTheme(themeId: value, dark: appTheme.dark);
    notifyListeners();
  }
}
