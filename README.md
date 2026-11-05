# Luma

A quiet, fast media player for Android TV. Point Luma at a folder or a USB
disk and it builds a poster wall: recursive scanning, filename parsing, NFO
support, TMDB scraping, resume playback and automatic next-episode.

UI language is Chinese-first.

## Features

- **Poster wall** — films and series grouped automatically, with a
  deterministic gradient fallback when no artwork exists.
- **Local + USB** — add folders through the system picker or an entire
  storage volume. Scanning walks subdirectories up to 24 levels.
- **Automatic metadata** — filename parser → local `.nfo` → TMDB. Posters,
  backdrops, episode stills, ratings, genres, runtimes and overviews.
- **Series grouping** — `S01E02`, `1x02`, `第 2 集`, `Show - 12` and folder
  seasons are recognised; episodes are grouped into one show.
- **Playback** — `media_kit`/libmpv with custom TV controls, D-pad support,
  resume, audio/subtitle track selection, speed and aspect-fit controls,
  sidecar subtitle discovery and auto-next.
- **TV-first UX** — D-pad focus rings, a compact nav rail, 10-foot typography
  and a champagne-on-near-black palette.

## Requirements

| Tool | Version |
| --- | --- |
| Flutter | 3.47 or newer |
| Dart | 3.13 or newer |
| Android | 7.0 (API 24) or newer |
| Android TV | recommended target |

A free [TMDB API key](https://www.themoviedb.org/settings/api) is required for
online scraping. NFO metadata still works without one.

## Build

```bash
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"

flutter pub get
flutter build apk --debug

# Smaller, per-ABI release build
flutter build apk --release --split-per-abi
```

Install on a TV or phone over ADB:

```bash
adb connect 192.168.1.50:5555
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

The release build currently uses the debug signing config so it can be
sideloaded immediately. Configure your own keystore in
`android/app/build.gradle.kts` before publishing.

### Themes

Every Luma theme is defined by exactly **three authored colours** plus supporting roles:

- **primary** — the main interactive/CTA hue (buttons, active chips, focus)
- **accent** — the secondary brand hue
- **surface** — the panel/card colour
- supporting roles derived or authored per theme: background, line, text (+ textDim/textMuted), danger, success, and per-role deep/soft shades

Each theme ships a dark and a light variant, both alternate live from **设置 → 外观** (mode is remembered per theme). All colours on screen resolve through `LumaColors.*`, i.e. `LumaColors.primary`, `LumaColors.accent`, `LumaColors.surface` — never hard-code a theme hex outside `lib/core/theme/<name>.dart`.

Current themes:

- **经典** — original near-black + champagne (gold CTA, bronze accent)
- **拜占庭** — plum-black + antique gold CTA (purple accent, gypsum paper in light mode)

To add a new theme, create `lib/core/theme/<name>.dart`, then register it in `lib/core/themes.dart`. `Settings → 外观` renders one tile per registered theme automatically.

### Desktop preview

The same UI runs as a Linux/macOS/Windows desktop app for design review. The
desktop build uses `sqflite_common_ffi`, a native folder picker and the system
libmpv, so scanning and playback work without an Android device.

```bash
# Linux playback needs libmpv (Fedora)
sudo dnf install mpv-libs

flutter run -d linux
```

On the onboarding screen choose **添加媒体目录** to pick any local folder, or
**先看看界面** to browse the empty state. Desktop storage permission is treated
as always granted. This path is for development preview only; the Android TV
build remains the shipping target.

### Gradle mirrors

`android/settings.gradle.kts` and `android/build.gradle.kts` list Aliyun Maven
mirrors before Google/Maven Central. This keeps builds working on networks
where `maven.google.com` is unreachable. Remove or reorder them if you prefer
the upstream repositories.

### media_kit libmpv downloads

`media_kit_libs_android_video` downloads four libmpv jars from GitHub releases
while Gradle configures the project. On networks where GitHub is slow or
blocked, a truncated jar fails with:

```
MD5 verification failed for .../build/media_kit_libs_android_video/v1.1.7/default-armeabi-v7a.jar
```

Pre-fetch the jars once with the helper script, which tries GitHub proxies and
verifies every checksum:

```bash
tool/fetch_media_kit_libs.sh
```

They are cached in `~/.cache/luma/media-kit/v1.1.7`. The Gradle init script
`~/.gradle/init.d/aliyun-mirrors.gradle` copies them into the plugin's build
directory, so `flutter clean` does not force another GitHub download. Without
that init script, copy the jars into
`build/media_kit_libs_android_video/v1.1.7/` manually before building.

### Non-ASCII Flutter SDK paths

Flutter 3.47's `FlutterAppPluginLoaderPlugin` reads `local.properties` with
`Properties.load(InputStream)`, which decodes UTF-8 bytes as ISO-8859-1. If
the Flutter SDK path contains non-ASCII characters (for example
`/home/me/下载/flutter`), Gradle may report a mangled path such as
`/home/me/ä¸‹è½½/flutter`.

Use an ASCII path or symlink the SDK to one. Alternatively, add this to
`~/.gradle/init.d/utf8-flutter-sdk.gradle`:

```groovy
beforeSettings { settings ->
    def localProperties = new File(settings.settingsDir, 'local.properties')
    if (localProperties.isFile()) {
        def properties = new Properties()
        localProperties.withReader('UTF-8') { properties.load(it) }
        def flutterSdk = properties.getProperty('flutter.sdk')
        if (flutterSdk) settings.extraProperties.set('flutterSdkPath', flutterSdk)
    }
}
```

This sets the value before Flutter's settings plugin reads it.

## TMDB setup

1. Create an account at [themoviedb.org](https://www.themoviedb.org/).
2. Open **Settings → API** and request a free API key.
3. In Luma open **设置 → TMDB API Key → 配置**, paste the key and use
   **测试连接** before saving.

The key is stored only in the device's SharedPreferences. Requests go
directly to `api.themoviedb.org`; there is no proxy or cloud account.

TMDB attribution: this product uses the TMDB API but is not endorsed or
certified by TMDB.

## Storage permissions

Android 11 and newer require **All files access** (`MANAGE_EXTERNAL_STORAGE`)
for apps that browse arbitrary folders and USB volumes by real path:

- On first launch, choose **授予文件访问权限**.
- If the system dialog does not appear, open **设置 → 媒体来源 → 去授权**,
  or grant the permission from Android TV's app settings.
- Android 10 and older request `READ_EXTERNAL_STORAGE` instead.
- `READ_MEDIA_VIDEO` is declared for Android 13+ compatibility.

The folder picker uses the Storage Access Framework. If a provider does not
expose a real filesystem path (for example some cloud providers), add the
whole USB volume from **添加目录 → 整块磁盘** instead.

Supported mounts include the primary shared storage and removable volumes
under `/storage/<UUID>`.

## How scanning works

1. Walk the source recursively, ignoring hidden files, sample/trailer files
   and files smaller than 2 MB.
2. Parse the filename for title, year, season and episode. Release tags
   (`1080p`, `BluRay`, `x265`, `WEB-DL`, …) are stripped.
3. Look for a same-name `.nfo` and local artwork (`poster.jpg`,
   `fanart.jpg`, `folder.jpg`, `show.jpg`, …).
4. If a TMDB key is configured and automatic scraping is on, match the item
   and write metadata back to SQLite.
5. On later scans, missing files are removed while scraped metadata on
   existing files is preserved.

### Recommended layout

```
Movies/
  Blade Runner 2049 (2017)/
    Blade.Runner.2049.2017.2160p.mkv
    poster.jpg
    movie.nfo
Shows/
  Severance/
    Season 01/
      Severance.S01E01.mkv
      Severance.S01E01.zh.srt
      show.nfo
```

## Project layout

```
lib/
  app.dart                 bootstrap, splash, error state
  controllers/             AppController (ChangeNotifier)
  core/                    theme, formatters
                      theme.dart      barrel exports
                      theme/          one file per theme (classic, byzantium)
                      themes.dart     built-in theme registry
                      luma_colors.dart semantic colour handle for screens
                      luma_theme.dart ThemeData + page transitions
                      palette.dart    LumaPalette, the shared palette shape
  data/
    app_database.dart      SQLite schema
    media_repository.dart  queries and scan upserts
    scanner/               recursive scanner, filename/NFO parsers
    scraper/               TMDB client, matcher, scrape orchestration
    storage_service.dart   MethodChannel bridge
  features/                home, library, detail, player, settings,
                           onboarding, shell, sources
  widgets/                 TV focus primitives, artwork, shelf, nav rail
android/…/MainActivity.kt  storage permissions, folder picker, volumes
test/                      parser and repository tests
```

## Tests

```bash
flutter analyze
flutter test
```

The repository tests use `sqflite_common_ffi` and an in-memory database, so
they run on the host without an emulator.

## Current scope

- Local storage and USB only. SMB, WebDAV and NFS are not implemented yet.
- No transcoding; libmpv plays the file as-is.
- Embedded and sidecar subtitles are supported; bitmap subtitle styling is
  handled by libmpv defaults.
- The app is landscape-first for TV. Phone/tablet support is functional but
  not the primary design target.
