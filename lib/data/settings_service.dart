import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:luma_tv/core/common/preference.dart';
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
  static const seekIntervalOptions = [5, 10, 15, 30, 60];

  final SharedPreferencesWithCache _prefs;

  new(this._prefs);

  /// TMDB API Key 仅来自环境变量（.env 文件或 --dart-define），不再存入数据库。
  /// 优先级：
  /// 1. .env 文件（运行时加载，无需重构建即可修改）
  /// 2. 构建时环境变量（--dart-define=TMDB_API_KEY=xxx）
  static const String _tmdbApiKeyFromEnv = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  /// 豆瓣 API Key 仅来自环境变量（.env 文件或 --dart-define）。
  static const String _doubanApiKeyFromEnv = String.fromEnvironment(
    'DOUBAN_API_KEY',
    defaultValue: '',
  );

  /// TMDB API Key。仅从环境变量读取，不再读取/写入 shared_preferences。
  String get tmdbApiKey {
    // 优先 .env 文件
    final envFileKey = _dotenvGet('TMDB_API_KEY')?.trim();
    if (envFileKey != null && envFileKey.isNotEmpty) return envFileKey;

    // 次优先构建时环境变量
    if (_tmdbApiKeyFromEnv.isNotEmpty) return _tmdbApiKeyFromEnv;

    return '';
  }

  /// 豆瓣 API Key。仅从环境变量读取。
  String get doubanApiKey {
    final envFileKey = _dotenvGet('DOUBAN_API_KEY')?.trim();
    if (envFileKey != null && envFileKey.isNotEmpty) return envFileKey;
    if (_doubanApiKeyFromEnv.isNotEmpty) return _doubanApiKeyFromEnv;
    return '';
  }

  /// 是否通过环境变量注入了豆瓣 API Key（.env 或 dart-define）。
  bool get doubanApiKeyFromEnv {
    return _doubanApiKeyFromEnv.isNotEmpty ||
        (_dotenvGet('DOUBAN_API_KEY')?.isNotEmpty ?? false);
  }

  /// 安全读取 .env 文件中的键值，未初始化时返回 null（测试环境等）。
  String? _dotenvGet(String key) {
    try {
      return dotenv.env[key];
    } on NotInitializedError {
      return null;
    }
  }

  bool get hasTmdbKey => tmdbApiKey.isNotEmpty;

  /// 豆瓣作为备用源，未配置时刮削仍可正常进行。
  bool get hasDoubanKey => doubanApiKey.isNotEmpty;

  TmdbLanguage get language =>
      TmdbLanguage.fromCode(_prefs.getString(Options.kLanguage.key));

  bool get onboardingComplete =>
      _prefs.getBool(Options.kOnboarding.key) ?? false;

  bool get autoScrape => _prefs.getBool(Options.kAutoScrape.key) ?? true;

  bool get autoScanOnStart => _prefs.getBool(Options.kAutoScan.key) ?? false;

  bool get autoLoadSubtitles =>
      _prefs.getBool(Options.kAutoSubtitle.key) ?? true;

  bool get autoPlayNext => _prefs.getBool(Options.kAutoNext.key) ?? true;

  int get seekIntervalSeconds {
    final value = _prefs.getInt(Options.kSeekIntervalSeconds.key);
    return seekIntervalOptions.contains(value) ? value! : 10;
  }

  /// 是否记住上一次的播放速度。打开后，下一个视频将沿用上次切换的速度。
  bool get rememberPlaybackSpeed =>
      _prefs.getBool(Options.kRememberPlaybackSpeed.key) ?? true;

  /// 上一次使用的播放速度（倍率），默认 1.0。
  double get lastPlaybackSpeed {
    final value = _prefs.getDouble(Options.kLastPlaybackSpeed.key);
    return value ?? 1.0;
  }

  /// Selected theme, e.g. 'classic', 'byzantium', 'pineAmber', 'beanSand'.
  /// Defaults to classic. Unknown ids fall back to classic via LumaThemes.byId().
  String get themeId => _prefs.getString(Options.kThemeId.key) ?? 'classic';

  /// Global light/dark mode, shared across all themes. Defaults to dark.
  bool get themeDark => _prefs.getBool(Options.kThemeDark.key) ?? true;

  Future<void> setLanguage(TmdbLanguage value) async {
    await _prefs.setString(Options.kLanguage.key, value.code);
    notifyListeners();
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _prefs.setBool(Options.kOnboarding.key, value);
    notifyListeners();
  }

  Future<void> setAutoScrape(bool value) async {
    await _prefs.setBool(Options.kAutoScrape.key, value);
    notifyListeners();
  }

  Future<void> setAutoScanOnStart(bool value) async {
    await _prefs.setBool(Options.kAutoScan.key, value);
    notifyListeners();
  }

  Future<void> setAutoLoadSubtitles(bool value) async {
    await _prefs.setBool(Options.kAutoSubtitle.key, value);
    notifyListeners();
  }

  Future<void> setAutoPlayNext(bool value) async {
    await _prefs.setBool(Options.kAutoNext.key, value);
    notifyListeners();
  }

  Future<void> setSeekIntervalSeconds(int value) async {
    final seconds = seekIntervalOptions.contains(value) ? value : 10;
    await _prefs.setInt(Options.kSeekIntervalSeconds.key, seconds);
    notifyListeners();
  }

  Future<void> setRememberPlaybackSpeed(bool value) async {
    await _prefs.setBool(Options.kRememberPlaybackSpeed.key, value);
    notifyListeners();
  }

  Future<void> setLastPlaybackSpeed(double value) async {
    await _prefs.setDouble(Options.kLastPlaybackSpeed.key, value);
    notifyListeners();
  }

  Future<void> setThemeId(String value) async {
    await _prefs.setString(Options.kThemeId.key, value);
    notifyListeners();
  }

  Future<void> setThemeDark(bool value) async {
    await _prefs.setBool(Options.kThemeDark.key, value);
    notifyListeners();
  }
}
