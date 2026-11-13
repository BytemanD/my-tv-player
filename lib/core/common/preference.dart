import 'package:shared_preferences/shared_preferences.dart';

final prefs = SharedPreferencesAsync();

enum Options {
  kLanguage('tmdb_language'),
  kOnboarding('onboarding_complete'),
  kAutoScrape('auto_scrape'),
  kAutoScan('auto_scan_on_start'),
  kAutoSubtitle('auto_subtitle'),
  kAutoNext('auto_play_next'),
  kSeekIntervalSeconds('player_seek_interval_seconds'),
  kRememberPlaybackSpeed('remember_playback_speed'),
  kLastPlaybackSpeed('last_playback_speed'),
  kThemeId('theme_id'),
  kThemeMode('theme_mode');

  final String key;
  const Options(this.key);
}

Future<SharedPreferences> loadSharedPreferences() {
  return SharedPreferences.getInstance();
}
