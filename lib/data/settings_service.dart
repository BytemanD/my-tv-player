import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TmdbLanguage {
  simplifiedChinese('zh-CN', '简体中文'),
  traditionalChinese('zh-TW', '繁體中文'),
  english('en-US', 'English'),
  japanese('ja-JP', '日本語');

  const TmdbLanguage(this.code, this.label);
  final String code;
  final String label;

  static TmdbLanguage fromCode(String? code) {
    return TmdbLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => TmdbLanguage.simplifiedChinese,
    );
  }
}

class SettingsService extends ChangeNotifier {
  SettingsService._(this._prefs);

  static const _kApiKey = 'tmdb_api_key';
  static const _kLanguage = 'tmdb_language';
  static const _kOnboarding = 'onboarding_complete';
  static const _kAutoScrape = 'auto_scrape';
  static const _kAutoScan = 'auto_scan_on_start';
  static const _kAutoSubtitle = 'auto_subtitle';
  static const _kAutoNext = 'auto_play_next';
  static const _kSeekIntervalSeconds = 'player_seek_interval_seconds';
  static const _kThemeId = 'theme_id';
  static const _kThemeModePrefix = 'theme_mode_';

  static const seekIntervalOptions = [5, 10, 15, 30, 60];

  final SharedPreferences _prefs;

  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

  String get tmdbApiKey => _prefs.getString(_kApiKey)?.trim() ?? '';
  bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  TmdbLanguage get language =>
      TmdbLanguage.fromCode(_prefs.getString(_kLanguage));

  bool get onboardingComplete => _prefs.getBool(_kOnboarding) ?? false;

  bool get autoScrape => _prefs.getBool(_kAutoScrape) ?? true;

  bool get autoScanOnStart => _prefs.getBool(_kAutoScan) ?? false;

  bool get autoLoadSubtitles => _prefs.getBool(_kAutoSubtitle) ?? true;

  bool get autoPlayNext => _prefs.getBool(_kAutoNext) ?? true;

  int get seekIntervalSeconds {
    final value = _prefs.getInt(_kSeekIntervalSeconds);
    return seekIntervalOptions.contains(value) ? value! : 10;
  }

  /// Selected theme, e.g. 'classic', 'byzantium', 'pineAmber', 'beanSand'.
  /// Defaults to classic. Unknown ids fall back to classic via LumaThemes.byId().
  String get themeId => _prefs.getString(_kThemeId) ?? 'classic';

  /// Mode for the *current* theme; stored per theme so each theme remembers
  /// its own preferred 明/暗. Defaults to dark.
  String get themeMode =>
      _prefs.getString('$_kThemeModePrefix$themeId') == 'light'
      ? 'light'
      : 'dark';

  Future<void> setTmdbApiKey(String value) async {
    await _prefs.setString(_kApiKey, value.trim());
    notifyListeners();
  }

  Future<void> setLanguage(TmdbLanguage value) async {
    await _prefs.setString(_kLanguage, value.code);
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(_kOnboarding, value);
    notifyListeners();
  }

  Future<void> setAutoScrape(bool value) async {
    await _prefs.setBool(_kAutoScrape, value);
    notifyListeners();
  }

  Future<void> setAutoScanOnStart(bool value) async {
    await _prefs.setBool(_kAutoScan, value);
    notifyListeners();
  }

  Future<void> setAutoLoadSubtitles(bool value) async {
    await _prefs.setBool(_kAutoSubtitle, value);
    notifyListeners();
  }

  Future<void> setAutoPlayNext(bool value) async {
    await _prefs.setBool(_kAutoNext, value);
    notifyListeners();
  }

  Future<void> setSeekIntervalSeconds(int value) async {
    final seconds = seekIntervalOptions.contains(value) ? value : 10;
    await _prefs.setInt(_kSeekIntervalSeconds, seconds);
    notifyListeners();
  }

  Future<void> setThemeId(String value) async {
    await _prefs.setString(_kThemeId, value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(
      '$_kThemeModePrefix$themeId',
      value == 'light' ? 'light' : 'dark',
    );
    notifyListeners();
  }
}
