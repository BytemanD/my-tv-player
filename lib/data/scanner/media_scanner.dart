import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/formatters.dart';
import '../library_source.dart';
import '../models.dart';
import 'nfo_parser.dart';
import 'video_file_name_parser.dart';

class ScanException implements Exception {
  ScanException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ScanProgress {
  const ScanProgress({
    required this.found,
    required this.currentPath,
    required this.scannedFiles,
  });
  final int found;
  final String currentPath;
  final int scannedFiles;
}

class ScanResult {
  const ScanResult({
    required this.items,
    required this.skipped,
    required this.visitedFiles,
    required this.unreadableDirectories,
    required this.failedFiles,
    required this.elapsed,
  });
  final List<MediaItem> items;
  final int skipped;
  final int visitedFiles;
  final int unreadableDirectories;
  final int failedFiles;
  final Duration elapsed;
}

class MediaScanner {
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _maxDepth = 24;

  Future<ScanResult> scan(
    LibrarySource source, {
    void Function(ScanProgress progress)? onProgress,
  }) async {
    final started = DateTime.now();
    final root = Directory(source.path);
    if (!await root.exists()) {
      throw ScanException('目录不存在或无法访问：${source.path}');
    }

    final items = <MediaItem>[];
    final listingCache = <String, Set<String>>{};
    final nfoCache = <String, NfoData?>{};
    var visited = 0;
    var skipped = 0;
    var unreadableDirectories = 0;
    var failedFiles = 0;

    Future<Set<String>> listing(Directory dir) async {
      final path = dir.path;
      final cached = listingCache[path];
      if (cached != null) return cached;
      try {
        final names = <String>{};
        await for (final entity in dir.list(followLinks: false)) {
          names.add(p.basename(entity.path).toLowerCase());
        }
        listingCache[path] = names;
        return names;
      } catch (_) {
        listingCache[path] = const {};
        return const {};
      }
    }

    Future<String?> findNfo(String filePath, List<String> folders) async {
      final dir = p.dirname(filePath);
      final base = p.basenameWithoutExtension(filePath);
      final candidates = <String>[
        p.join(dir, '$base.nfo'),
        p.join(dir, 'movie.nfo'),
        p.join(dir, 'tvshow.nfo'),
      ];
      // tvshow.nfo commonly lives one directory above a season folder.
      if (folders.isNotEmpty) {
        final parent = p.dirname(dir);
        candidates.add(p.join(parent, 'tvshow.nfo'));
      }
      for (final candidate in candidates) {
        if (await File(candidate).exists()) return candidate;
      }
      return null;
    }

    const skippedDirs = {
      'lost.dir',
      r'$recycle.bin',
      'system volume information',
      '@eadir',
      '#recycle',
      '.thumbnails',
      '.trash',
      '.git',
      'node_modules',
    };

    bool shouldSkipDirectory(String path, String name) {
      if (name.startsWith('.') || skippedDirs.contains(name.toLowerCase())) {
        return true;
      }
      final normalized = path.replaceAll('\\', '/').toLowerCase();
      // Android 11+ blocks these even with all-files access, and they are
      // never user media.
      return normalized.endsWith('/android/data') ||
          normalized.endsWith('/android/obb') ||
          normalized.contains('/android/data/') ||
          normalized.contains('/android/obb/');
    }

    Future<void> processFile(File entity) async {
      visited++;

      final FileStat stat;
      stat = await entity.stat();
      if (VideoFileNameParser.shouldIgnore(
        p.basename(entity.path),
        stat.size,
      )) {
        skipped++;
        return;
      }

      final relative = p.relative(entity.path, from: root.path);
      final folders = p.split(relative);
      if (folders.isNotEmpty) folders.removeLast();

      final parsed = VideoFileNameParser.parse(entity.path, folders: folders);
      final nfoPath = await findNfo(entity.path, folders);
      NfoData? nfo;
      if (nfoPath != null) {
        nfo = nfoCache[nfoPath];
        if (nfo == null && !nfoCache.containsKey(nfoPath)) {
          nfo = await NfoParser.parseFile(nfoPath);
          nfoCache[nfoPath] = nfo;
        }
      }

      final dir = p.dirname(entity.path);
      final names = await listing(Directory(dir));
      final base = p.basenameWithoutExtension(entity.path).toLowerCase();
      final localPoster = _findArt(dir, names, base, poster: true);
      final localBackdrop = _findArt(dir, names, base, poster: false);

      final isEpisode = parsed.isEpisode;
      final nfoTitle = nfo?.preferredTitle;
      var parsedSeriesTitle = parsed.title;
      if (isEpisode && _isNumberLikeTitle(parsedSeriesTitle)) {
        parsedSeriesTitle =
            _showFolderName(folders) ??
            _showFolderName([p.basename(root.path)]) ??
            parsedSeriesTitle;
      }
      final seriesTitle = isEpisode
          ? (nfo?.showTitle?.trim().isNotEmpty == true
                ? nfo!.showTitle!.trim()
                : parsedSeriesTitle)
          : null;
      final year = nfo?.year ?? parsed.year;
      final season = nfo?.season ?? parsed.season;
      final episode = nfo?.episode ?? parsed.episode;
      final seriesKey = isEpisode
          ? seriesKeyFromTitle(seriesTitle ?? parsed.title, year: year)
          : null;

      final posterFromNfo = _resolveNfoArtwork(nfo?.poster, nfoPath);
      final backdropFromNfo = _resolveNfoArtwork(nfo?.fanart, nfoPath);

      items.add(
        MediaItem(
          sourceId: source.id!,
          path: entity.path,
          fileName: p.basename(entity.path),
          size: stat.size,
          modifiedAt: stat.modified.millisecondsSinceEpoch,
          kind: parsed.kind,
          title: isEpisode
              ? (nfoTitle != null && nfo?.episode != null
                    ? nfoTitle
                    : (nfoTitle ?? parsed.episodeTitle ?? ''))
              : (nfoTitle ?? parsed.title),
          year: year,
          season: season,
          episode: episode,
          seriesKey: seriesKey,
          seriesTitle: seriesTitle,
          tmdbId: nfo?.tmdbId,
          imdbId: nfo?.imdbId,
          overview: nfo?.plot,
          posterPath: posterFromNfo?.remote,
          backdropPath: backdropFromNfo?.remote,
          localPoster: localPoster ?? posterFromNfo?.local,
          localBackdrop: localBackdrop ?? backdropFromNfo?.local,
          rating: nfo?.rating,
          genres: nfo?.genres ?? const [],
          runtime: nfo?.runtime,
          releaseDate: nfo?.premiered,
          nfoPath: nfoPath,
          scrapeState: ScrapeState.pending,
          addedAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      if (onProgress != null && (items.length % 10 == 0 || items.length == 1)) {
        onProgress(
          ScanProgress(
            found: items.length,
            currentPath: relative,
            scannedFiles: visited,
          ),
        );
      }
    }

    // Walk manually instead of using Directory.list(recursive: true): a single
    // unreadable folder would otherwise abort the whole scan on Android.
    final pending = <({Directory directory, int depth})>[
      (directory: root, depth: 0),
    ];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (current.depth >= _maxDepth) continue;

      final List<FileSystemEntity> entries;
      try {
        entries = await current.directory.list(followLinks: false).toList();
      } catch (error) {
        if (current.depth == 0) {
          throw ScanException('无法读取媒体目录：${current.directory.path}（$error）');
        }
        unreadableDirectories++;
        continue;
      }

      for (final entity in entries) {
        if (entity is Directory) {
          if (shouldSkipDirectory(entity.path, p.basename(entity.path))) {
            continue;
          }
          pending.add((directory: entity, depth: current.depth + 1));
        } else if (entity is File) {
          if (!VideoFileNameParser.isVideoFile(entity.path)) continue;
          try {
            await processFile(entity);
          } catch (error) {
            // One unreadable or malformed file must not abort the scan.
            failedFiles++;
          }
        }
      }
    }

    return ScanResult(
      items: items,
      skipped: skipped,
      visitedFiles: visited,
      unreadableDirectories: unreadableDirectories,
      failedFiles: failedFiles,
      elapsed: DateTime.now().difference(started),
    );
  }

  static final _seasonFolderRegex = RegExp(
    r'^(season|series|s)\s*\d{1,3}$',
    caseSensitive: false,
  );
  static final _chineseSeasonFolderRegex = RegExp(r'^第[一二三四五六七八九十百0-9]+季$');
  static const _genericFolders = {
    'tv',
    'tv shows',
    'shows',
    'show',
    'series',
    '剧集',
    '电视剧',
    '电视',
    'media',
    'video',
    'videos',
    'movies',
    'movie',
    '电影',
    'downloads',
    '下载',
    'anime',
    '动漫',
    '动画',
  };

  static bool _isNumberLikeTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return true;
    if (RegExp(r'^[\d\s._-]+$').hasMatch(trimmed)) return true;
    return RegExp(r'^(ep|e)\s*\d+$', caseSensitive: false).hasMatch(trimmed);
  }

  String? _showFolderName(List<String> folders) {
    for (final folder in folders.reversed) {
      final trimmed = folder.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      if (_seasonFolderRegex.hasMatch(lower) ||
          _chineseSeasonFolderRegex.hasMatch(trimmed) ||
          _genericFolders.contains(lower)) {
        continue;
      }
      return trimmed;
    }
    return null;
  }

  String? _findArt(
    String dir,
    Set<String> names,
    String base, {
    required bool poster,
  }) {
    final stems = poster
        ? ['$base-poster', '$base.poster', base, 'poster', 'folder', 'cover']
        : [
            '$base-fanart',
            '$base-backdrop',
            '$base.fanart',
            '$base-backdrop',
            'fanart',
            'backdrop',
            'background',
          ];
    for (final stem in stems) {
      for (final ext in _imageExtensions) {
        final name = '$stem.$ext';
        if (names.contains(name)) {
          return p.join(dir, name);
        }
      }
    }
    return null;
  }

  _NfoArtwork? _resolveNfoArtwork(String? value, String? nfoPath) {
    if (value == null || value.trim().isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _NfoArtwork(remote: trimmed);
    }
    if (nfoPath == null) return null;
    final candidate = p.isAbsolute(trimmed)
        ? trimmed
        : p.join(p.dirname(nfoPath), trimmed);
    if (File(candidate).existsSync()) {
      return _NfoArtwork(local: candidate);
    }
    return null;
  }
}

class _NfoArtwork {
  const _NfoArtwork({this.remote, this.local});
  final String? remote;
  final String? local;
}
