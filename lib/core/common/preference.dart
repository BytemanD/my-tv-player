import 'package:shared_preferences/shared_preferences.dart';

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
  kThemeDark('theme_dark');

  final String key;
  const Options(this.key);
}

Future<SharedPreferencesWithCache> loadSharedPreferences() {
  return SharedPreferencesWithCache.create(
    cacheOptions: SharedPreferencesWithCacheOptions(
      allowList: Options.values.map((x) => x.key).toSet(),
    ),
  );
}
