import 'theme/classic.dart';
import 'theme/byzantium.dart';
import 'theme/pine_amber.dart';
import 'theme_option.dart';

/// Registry of every built-in theme. Create one file per theme under
/// `theme/` and append it here; the settings picker, persistence and
/// default handling all read from this list.
abstract final class LumaThemes {
  static const classic = classicTheme;
  static const byzantium = byzantiumTheme;
  static const pineAmber = pineAmberTheme;

  static const all = [classicTheme, byzantiumTheme, pineAmberTheme];

  static LumaThemeOption byId(String? id) =>
      all.firstWhere((option) => option.id == id, orElse: () => classicTheme);
}
