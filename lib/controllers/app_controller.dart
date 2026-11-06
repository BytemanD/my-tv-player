import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/library_source.dart';
import '../data/media_repository.dart';
import '../data/models.dart';
import '../data/scanner/media_scanner.dart';
import '../data/scraper/metadata_scraper.dart';
import '../data/scraper/tmdb_client.dart';
import '../core/theme.dart';
import '../data/settings_service.dart';
import '../data/storage_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.database,
    required this.repository,
    required this.settings,
    required this.storage,
    required this.scanner,
  });

  final AppDatabase database;
  final MediaRepository repository;
  final SettingsService settings;
  final StorageService storage;
  final MediaScanner scanner;

  bool initializing = true;
  String? fatalError;
  bool hasStorageAccess = false;

  List<LibrarySource> sources = const [];
  List<LibraryEntry> entries = const [];
  List<LibraryEntry> movieEntries = const [];
  List<LibraryEntry> seriesEntries = const [];
  List<ContinueItem> continueWatching = const [];
  Map<int, PlaybackProgress> progressMap = const {};
  ({int movies, int episodes, int series, int progress}) stats = (
    movies: 0,
    episodes: 0,
    series: 0,
    progress: 0,
  );

  bool scanning = false;
  int scanFound = 0;
  int scanVisited = 0;
  String scanCurrent = '';
  String scanSourceName = '';

  bool scraping = false;
  ScrapeProgress scrapeProgress = ScrapeProgress.idle();
  ScrapeReport? lastScrapeReport;
  MetadataScraper? _activeScraper;

  String? notice;
  bool noticeIsError = false;
  Timer? _noticeTimer;

  DateTime? lastScanAt;

  bool get hasTmdbKey => settings.hasTmdbKey;
  bool get libraryIsEmpty => entries.isEmpty;
  bool get isBusy => scanning || scraping;

  List<LibraryEntry> get recentEntries {
    final list = [...entries];
    list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  /// Up to 10 hero picks for the homepage carousel. Strategy: prefer titles
  /// with artwork, rank untouched (never watched) first, then by TMDB rating,
  /// then by most recently added — so the rail shows high-quality unwatched
  /// movies and shows. Falls back to any entries when artwork is scarce.
  List<LibraryEntry> get heroEntries {
    final withArtwork = entries
        .where((e) => e.backdropPath != null || e.localBackdrop != null)
        .toList();
    final pool = withArtwork.length >= 3 ? withArtwork : List.of(entries);

    int watchedRank(LibraryEntry entry) {
      int completedOf(Iterable<int?> ids) => ids
          .where((id) => id != null && (progressMap[id]?.completed ?? false))
          .length;
      bool anyStartedOf(Iterable<int?> ids) => ids.any(
        (id) => id != null && (progressMap[id]?.fraction ?? 0) > 0.02,
      );

      if (entry.isSeries) {
        final episodes = entry.series!.episodes;
        if (episodes.isEmpty) return 2;
        final ids = episodes.map((e) => e.id);
        if (completedOf(ids) >= episodes.length) return 2; // fully watched
        if (completedOf(ids) > 0 || anyStartedOf(ids)) return 1;
        return 0;
      }
      final id = entry.movie!.id;
      final progress = id == null ? null : progressMap[id];
      if (progress?.completed ?? false) return 2;
      if ((progress?.fraction ?? 0) > 0.02) return 1;
      return 0;
    }

    pool.sort((a, b) {
      final watched = watchedRank(a).compareTo(watchedRank(b));
      if (watched != 0) return watched;
      final rating = (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (rating != 0) return rating;
      return b.addedAt.compareTo(a.addedAt);
    });
    return pool.take(10).toList();
  }

  Future<void> initialize() async {
    initializing = true;
    notifyListeners();
    try {
      hasStorageAccess = await storage.hasAllFilesAccess();
      sources = await repository.sources();
      await refreshLibrary(notify: false);
      if (settings.autoScanOnStart && hasStorageAccess && sources.isNotEmpty) {
        unawaited(scanAll(silent: true));
      }
    } catch (error) {
      fatalError = '初始化失败：$error';
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshLibrary({bool notify = true}) async {
    try {
      final all = await repository.allMedia();
      final movies = all.where((m) => m.isMovie).toList();
      final episodes = all.where((m) => m.isEpisode).toList();
      final groups = <String, List<MediaItem>>{};
      for (final episode in episodes) {
        final key = episode.seriesKey ?? 'media:${episode.id}';
        groups.putIfAbsent(key, () => []).add(episode);
      }

      movieEntries = movies.map(LibraryEntry.movie).toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      seriesEntries =
          groups.values
              .map((list) => LibraryEntry.series(SeriesGroup(list)))
              .toList()
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      entries = [...movieEntries, ...seriesEntries]
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      continueWatching = await repository.continueWatching();
      progressMap = await repository.allProgress();
      stats = await repository.stats();
      sources = await repository.sources();
      if (notify) notifyListeners();
    } catch (error) {
      fatalError = '读取媒体库失败：$error';
      if (notify) notifyListeners();
    }
  }

  Future<void> refreshAccessState() async {
    final access = await storage.hasAllFilesAccess();
    if (access != hasStorageAccess) {
      hasStorageAccess = access;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------- sources

  Future<bool> addSourceFromPicker() async {
    final folder = await storage.pickFolder();
    if (folder == null) return false;
    if (folder.path == null || !folder.accessible) {
      showNotice('无法解析该文件夹的本地路径，请改用“整块磁盘”添加', error: true);
      return false;
    }
    final id = await repository.addSource(
      path: folder.path!,
      name: folder.name,
      uri: folder.uri,
    );
    await refreshLibrary();
    final source = sources.firstWhere((s) => s.id == id);
    await scanSource(source);
    return true;
  }

  Future<void> addVolumeSource(StorageVolume volume) async {
    final id = await repository.addSource(
      path: volume.path,
      name: volume.label.isEmpty ? volume.path : volume.label,
    );
    await refreshLibrary();
    final source = sources.firstWhere((s) => s.id == id);
    await scanSource(source);
  }

  Future<void> removeSource(LibrarySource source) async {
    if (source.id == null) return;
    await repository.removeSource(source.id!);
    await refreshLibrary();
    showNotice('已移除「${source.name}」');
  }

  Future<void> requestStorageAccess() async {
    // 优先尝试普通运行时权限：系统弹标准对话框，用户点允许即可（像 iHub 那样）。
    final status = await storage.requestStoragePermission();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await refreshAccessState();
    if (hasStorageAccess) {
      showNotice('文件访问权限已授予');
      return;
    }

    // 普通权限被拒绝或设备不支持，fallback 到 MANAGE_EXTERNAL_STORAGE 设置页。
    final manageStatus = await storage.requestAllFilesAccess();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await refreshAccessState();
    if (hasStorageAccess) {
      showNotice('文件访问权限已授予');
      return;
    }

    showNotice(
      switch (manageStatus) {
        'opened_manage_app' =>
            '已打开权限页：请允许“所有文件访问权限”，返回 Luma 后会自动刷新',
        'opened_manage_all' =>
            '已打开“所有文件访问”列表：找到 Luma 并允许，返回后会自动刷新',
        'opened_app_details' =>
            '已打开应用详情：请前往 权限 → 所有文件访问 开启，返回后会自动刷新',
        'runtime_requested' => '请在弹出的对话框中允许存储权限',
        'already_granted' => '权限已授予',
        _ =>
            '此设备没有可用的权限设置页，请前往 设置 → 应用 → Luma → 权限，手动开启“所有文件访问”',
      },
      error: status != 'opened_manage_app' &&
          status != 'opened_manage_all' &&
          manageStatus != 'opened_manage_app' &&
          manageStatus != 'opened_manage_all',
    );
  }

  // ---------------------------------------------------------------- scanning

  Future<void> scanAll({bool silent = false}) async {
    if (scanning || sources.isEmpty) return;
    if (!hasStorageAccess) {
      await refreshAccessState();
      if (!hasStorageAccess) {
        if (!silent) {
          showNotice('需要先授予“所有文件访问权限”才能扫描', error: true);
        }
        return;
      }
    }

    scanning = true;
    notifyListeners();
    var totalAdded = 0;
    var totalRemoved = 0;
    var totalFound = 0;
    var totalVisited = 0;
    var totalSkipped = 0;
    var totalUnreadableDirectories = 0;
    var totalFailedFiles = 0;
    try {
      for (final source in sources) {
        scanSourceName = source.name;
        scanFound = 0;
        scanVisited = 0;
        scanCurrent = '';
        notifyListeners();
        try {
          final result = await scanner.scan(
            source,
            onProgress: (progress) {
              scanFound = progress.found;
              scanVisited = progress.scannedFiles;
              scanCurrent = progress.currentPath;
              notifyListeners();
            },
          );
          final applied = await repository.applyScan(source.id!, result.items);
          await repository.touchSource(source.id!);
          totalAdded += applied.added;
          totalRemoved += applied.removed;
          totalFound += result.items.length;
          totalVisited += result.visitedFiles;
          totalSkipped += result.skipped;
          totalUnreadableDirectories += result.unreadableDirectories;
          totalFailedFiles += result.failedFiles;
        } on ScanException catch (error) {
          showNotice(error.message, error: true);
        } catch (error) {
          showNotice('扫描「${source.name}」失败：$error', error: true);
        }
      }
      lastScanAt = DateTime.now();
      await refreshLibrary();
      if (!silent) {
        showNotice(
          '扫描完成：发现 $totalFound 个视频（检查 $totalVisited 个，过滤 $totalSkipped 个），新增 $totalAdded 个，移除 $totalRemoved 个'
          '${totalUnreadableDirectories > 0 ? '；无法读取目录 $totalUnreadableDirectories 个' : ''}'
          '${totalFailedFiles > 0 ? '；处理失败 $totalFailedFiles 个文件' : ''}',
          error: totalUnreadableDirectories > 0 || totalFailedFiles > 0,
        );
      }
      if (settings.autoScrape && settings.hasTmdbKey) {
        await scrapeAll(silent: silent);
      }
    } finally {
      scanning = false;
      scanCurrent = '';
      notifyListeners();
    }
  }

  Future<void> scanSource(LibrarySource source) async {
    if (scanning) return;
    if (!hasStorageAccess) {
      await refreshAccessState();
      if (!hasStorageAccess) {
        showNotice('需要先授予“所有文件访问权限”才能扫描', error: true);
        return;
      }
    }
    scanning = true;
    scanSourceName = source.name;
    scanFound = 0;
    scanVisited = 0;
    scanCurrent = '';
    notifyListeners();
    try {
      final result = await scanner.scan(
        source,
        onProgress: (progress) {
          scanFound = progress.found;
          scanVisited = progress.scannedFiles;
          scanCurrent = progress.currentPath;
          notifyListeners();
        },
      );
      final applied = await repository.applyScan(source.id!, result.items);
      await repository.touchSource(source.id!);
      lastScanAt = DateTime.now();
      await refreshLibrary();
      showNotice(
        '「${source.name}」扫描完成：发现 ${result.items.length} 个视频（检查 ${result.visitedFiles} 个，过滤 ${result.skipped} 个），新增 ${applied.added} 个，移除 ${applied.removed} 个'
        '${result.unreadableDirectories > 0 ? '；无法读取目录 ${result.unreadableDirectories} 个' : ''}'
        '${result.failedFiles > 0 ? '；处理失败 ${result.failedFiles} 个文件' : ''}',
        error: result.unreadableDirectories > 0 || result.failedFiles > 0,
      );
      if (settings.autoScrape && settings.hasTmdbKey) {
        await scrapeAll();
      }
    } on ScanException catch (error) {
      showNotice(error.message, error: true);
    } catch (error) {
      showNotice('扫描失败：$error', error: true);
    } finally {
      scanning = false;
      scanCurrent = '';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- scraping

  Future<void> scrapeAll({bool silent = false}) async {
    if (scraping) return;
    if (!settings.hasTmdbKey) {
      if (!silent) {
        showNotice('请先在设置中填写 TMDB API Key', error: true);
      }
      return;
    }

    scraping = true;
    scrapeProgress = ScrapeProgress(
      running: true,
      done: 0,
      total: 0,
      current: '准备刮削…',
      succeeded: 0,
      failed: 0,
    );
    notifyListeners();

    final scraper = MetadataScraper(repository);
    _activeScraper = scraper;
    try {
      final report = await scraper.run(
        apiKey: settings.tmdbApiKey,
        language: settings.language,
        onProgress: (progress) {
          scrapeProgress = progress;
          notifyListeners();
        },
      );
      lastScrapeReport = report;
      await refreshLibrary();
      if (report.fatal != null) {
        showNotice(report.fatal!, error: true);
      } else if (!silent) {
        if (!report.configured) {
          showNotice('未配置 TMDB API Key', error: true);
        } else if (report.cancelled) {
          showNotice('已停止刮削');
        } else {
          showNotice(
            '刮削完成：成功 ${report.succeeded}，失败 ${report.failed}',
            error: report.failed > 0,
          );
        }
      }
    } catch (error) {
      showNotice('刮削失败：$error', error: true);
    } finally {
      _activeScraper = null;
      scraping = false;
      scrapeProgress = ScrapeProgress.idle();
      notifyListeners();
    }
  }

  void cancelScrape() {
    _activeScraper?.cancel();
    showNotice('正在停止刮削…');
  }

  Future<String> testTmdbConnection(String apiKey) async {
    if (apiKey.trim().isEmpty) return '请先填写 API Key';
    final client = TmdbClient(
      apiKey: apiKey.trim(),
      language: settings.language.code,
    );
    try {
      await client.ping();
      return '连接成功，API Key 有效';
    } on TmdbException catch (error) {
      return error.message;
    } catch (error) {
      return '连接失败：$error';
    } finally {
      client.dispose();
    }
  }

  // --------------------------------------------------------------- settings

  Future<void> setTmdbApiKey(String value) async {
    await settings.setTmdbApiKey(value);
    notifyListeners();
  }

  Future<void> setLanguage(TmdbLanguage language) async {
    await settings.setLanguage(language);
    notifyListeners();
  }

  Future<void> setAutoScrape(bool value) async {
    await settings.setAutoScrape(value);
    notifyListeners();
  }

  Future<void> setAutoScanOnStart(bool value) async {
    await settings.setAutoScanOnStart(value);
    notifyListeners();
  }

  Future<void> setAutoLoadSubtitles(bool value) async {
    await settings.setAutoLoadSubtitles(value);
    notifyListeners();
  }

  Future<void> setAutoPlayNext(bool value) async {
    await settings.setAutoPlayNext(value);
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    await settings.setThemeId(value);
    LumaColors.apply(
      settings.themeId,
      settings.themeMode == 'light' ? Brightness.light : Brightness.dark,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    await settings.setThemeMode(value);
    LumaColors.apply(
      settings.themeId,
      settings.themeMode == 'light' ? Brightness.light : Brightness.dark,
    );
    notifyListeners();
  }

  Future<void> setSeekIntervalSeconds(int value) async {
    await settings.setSeekIntervalSeconds(value);
    notifyListeners();
  }

  Future<void> setRememberPlaybackSpeed(bool value) async {
    await settings.setRememberPlaybackSpeed(value);
    notifyListeners();
  }

  Future<void> setLastPlaybackSpeed(double value) async {
    await settings.setLastPlaybackSpeed(value);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    await settings.setOnboardingComplete(true);
    notifyListeners();
  }

  // ---------------------------------------------------------------- progress

  Future<PlaybackProgress?> progressFor(MediaItem media) async {
    if (media.id == null) return null;
    return repository.progressFor(media.id!);
  }

  Future<void> savePlaybackProgress(
    MediaItem media,
    Duration position,
    Duration duration, {
    bool completed = false,
  }) async {
    if (media.id == null) return;
    await repository.saveProgress(
      mediaId: media.id!,
      positionMs: position.inMilliseconds,
      durationMs: duration.inMilliseconds,
      completed: completed,
    );
    progressMap = {
      ...progressMap,
      media.id!: PlaybackProgress(
        mediaId: media.id!,
        positionMs: position.inMilliseconds,
        durationMs: duration.inMilliseconds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        completed: completed,
      ),
    };
  }

  Future<void> markWatched(MediaItem media) async {
    if (media.id == null) return;
    await repository.markCompleted(
      media.id!,
      durationMs: (media.runtime ?? 0) * 60 * 1000,
    );
    await refreshLibrary();
  }

  Future<void> markUnwatched(MediaItem media) async {
    if (media.id == null) return;
    await repository.deleteProgress(media.id!);
    await refreshLibrary();
  }

  MediaItem? nextEpisodeOf(MediaItem media) {
    if (!media.isEpisode || media.seriesKey == null) return null;
    final entry = entries.firstWhereOrNull(
      (e) => e.isSeries && e.series?.key == media.seriesKey,
    );
    if (entry?.series == null) return null;
    return entry!.series!.nextAfter(media);
  }

  List<MediaItem> queueFor(MediaItem media) {
    if (media.isEpisode && media.seriesKey != null) {
      final entry = entries.firstWhereOrNull(
        (e) => e.isSeries && e.series?.key == media.seriesKey,
      );
      if (entry?.series != null) return entry!.series!.episodes;
    }
    return [media];
  }

  MediaItem? resumeEpisodeForSeries(String seriesKey) {
    final entry = entries.firstWhereOrNull(
      (e) => e.isSeries && e.series?.key == seriesKey,
    );
    if (entry?.series == null) return null;
    MediaItem? best;
    var bestTime = 0;
    for (final episode in entry!.series!.episodes) {
      final progress = episode.id == null ? null : progressMap[episode.id!];
      if (progress == null || progress.completed) continue;
      if (progress.fraction <= 0.02 || progress.fraction >= 0.96) continue;
      if (progress.updatedAt > bestTime) {
        bestTime = progress.updatedAt;
        best = episode;
      }
    }
    if (best != null) return best;
    final firstUnwatched = entry.series!.episodes.firstWhereOrNull(
      (e) => !(e.id != null && (progressMap[e.id!]?.completed ?? false)),
    );
    return firstUnwatched ?? entry.series!.episodes.firstOrNull;
  }

  MediaItem? firstEpisodeOf(String seriesKey) {
    final entry = entries.firstWhereOrNull(
      (e) => e.isSeries && e.series?.key == seriesKey,
    );
    return entry?.series?.episodes.firstOrNull;
  }

  // ------------------------------------------------------------------- misc

  Future<void> clearLibrary() async {
    await repository.clearLibrary();
    await refreshLibrary();
    showNotice('媒体库已清空');
  }

  LibraryEntry? entryByKey(String key) {
    return entries.firstWhereOrNull((e) => e.key == key);
  }

  void showNotice(String message, {bool error = false}) {
    notice = message;
    noticeIsError = error;
    notifyListeners();
    _noticeTimer?.cancel();
    _noticeTimer = Timer(const Duration(seconds: 6), () {
      notice = null;
      notifyListeners();
    });
  }

  void dismissNotice() {
    _noticeTimer?.cancel();
    notice = null;
    notifyListeners();
  }

  Future<void> close() async {
    _noticeTimer?.cancel();
    _activeScraper?.cancel();
    await database.close();
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    _activeScraper?.cancel();
    super.dispose();
  }
}
