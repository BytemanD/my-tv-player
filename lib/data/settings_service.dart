import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  static const _kLanguage = 'tmdb_language';
  static const _kOnboarding = 'onboarding_complete';
  static const _kAutoScrape = 'auto_scrape';
  static const _kAutoScan = 'auto_scan_on_start';
  static const _kAutoSubtitle = 'auto_subtitle';
  static const _kAutoNext = 'auto_play_next';
  static const _kSeekIntervalSeconds = 'player_seek_interval_seconds';
  static const _kRememberPlaybackSpeed = 'remember_playback_speed';
  static const _kLastPlaybackSpeed = 'last_playback_speed';
  static const _kThemeId = 'theme_id';
  static const _kThemeMode = 'theme_mode';

  static const seekIntervalOptions = [5, 10, 15, 30, 60];

  final SharedPreferences _prefs;

  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService._(prefs);
  }

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

  /// 是否记住上一次的播放速度。打开后，下一个视频将沿用上次切换的速度。
  bool get rememberPlaybackSpeed => _prefs.getBool(_kRememberPlaybackSpeed) ?? true;

  /// 上一次使用的播放速度（倍率），默认 1.0。
  double get lastPlaybackSpeed {
    final value = _prefs.getDouble(_kLastPlaybackSpeed);
    return value ?? 1.0;
  }

  /// Selected theme, e.g. 'classic', 'byzantium', 'pineAmber', 'beanSand'.
  /// Defaults to classic. Unknown ids fall back to classic via LumaThemes.byId().
  String get themeId => _prefs.getString(_kThemeId) ?? 'classic';

  /// Global light/dark mode, shared across all themes. Defaults to dark.
  String get themeMode =>
      _prefs.getString(_kThemeMode) == 'light' ? 'light' : 'dark';

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

  Future<void> setRememberPlaybackSpeed(bool value) async {
    await _prefs.setBool(_kRememberPlaybackSpeed, value);
    notifyListeners();
  }

  Future<void> setLastPlaybackSpeed(double value) async {
    await _prefs.setDouble(_kLastPlaybackSpeed, value);
    notifyListeners();
  }

  Future<void> setThemeId(String value) async {
    await _prefs.setString(_kThemeId, value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(
      _kThemeMode,
      value == 'light' ? 'light' : 'dark',
    );
    notifyListeners();
  }
}
