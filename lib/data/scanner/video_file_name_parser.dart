import 'dart:math' as math;

import '../models.dart';

class ParsedVideoInfo {
  const ParsedVideoInfo({
    required this.title,
    required this.kind,
    this.year,
    this.season,
    this.episode,
    this.episodeTitle,
    this.seriesKey,
  });

  final String title;
  final MediaKind kind;
  final int? year;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String? seriesKey;

  bool get isEpisode => kind == MediaKind.episode;
}

class VideoFileNameParser {
  static const videoExtensions = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    'ts',
    'm2ts',
    'mpg',
    'mpeg',
    'rmvb',
    'rm',
    '3gp',
    'ogv',
    'divx',
    'vob',
    'asf',
  };

  static bool isVideoFile(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return false;
    return videoExtensions.contains(path.substring(dot + 1).toLowerCase());
  }

  static bool shouldIgnore(String fileName, int sizeBytes) {
    final lower = fileName.toLowerCase();
    if (lower.startsWith('.')) return true;
    if (sizeBytes > 0 && sizeBytes < 2 * 1024 * 1024) return true;
    final isStandaloneTrailer = RegExp(r'^trailer\.[^.]+$')
        .hasMatch(lower.split(RegExp(r'[/\\]')).last);
    if (RegExp(
      r'(^|[.\s_-])(sample|trailer|teaser|featurette|extras?|menu)([.\s_-]|$)',
    ).hasMatch(lower)) {
      if (!isStandaloneTrailer) return true;
    }
    if (RegExp(r'预告|花絮|特典|片头|片尾|样片').hasMatch(fileName)) return true;
    return false;
  }

  static String _baseName(String fileName) {
    final slash = math.max(
      fileName.lastIndexOf('/'),
      fileName.lastIndexOf('\\'),
    );
    var name = slash >= 0 ? fileName.substring(slash + 1) : fileName;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name;
  }

  static const _releaseTag =
      // 点分隔的文件名会先被转成空格（如 H.264 -> H 264、DDP5.1 -> DDP5 1），
      // 因此编解码/音轨标记要同时兼容点、空格和紧邻写法。
      r'(2160p|1080p|1080i|720p|576p|480p|4k|uhd|bluray|blu-ray|bdrip|brrip|webrip|web-dl|webdl|hdtv|dvdrip|dvdscr|hdrip|remux|x\.?\s*264|x\.?\s*265|h\.?\s*264|h\.?\s*265|hevc|avc|av1|10bit|8bit|hdr10\+?|hdr|dv|dolby\s*vision|atmos|truehd|dts(?:-hd)?(?:\s*ma)?|ddp?\s*2\s*[.\s]\s*0|ddp?\s*5\s*[.\s]\s*1|dd\+?\s*7\s*[.\s]\s*1|aac\s*2\s*[.\s]\s*0|ac3\s*5\s*[.\s]\s*1|eac3\s*5\s*[.\s]\s*1|aac|ac3|eac3|flac|opus|proper|repack|remastered|extended|unrated|imax|multi|dual\s*audio|dubbed|subbed|complete|nf|internal)';

  static final _releaseTagRegex = RegExp(
    '\\b$_releaseTag\\b',
    caseSensitive: false,
  );
  static final _chineseTagRegex = RegExp(
    r'国语|粤语|中字|简中|繁中|简繁|双语|中英|字幕|无删减|导演剪辑版|蓝光|高清|超清|修复版|收藏版|完整版',
  );

  static final _explicitEpisodePatterns = <RegExp>[
    RegExp(
      r'(?<![a-z0-9])s(\d{1,2})\s*e(\d{1,3})(?![0-9])',
      caseSensitive: false,
    ),
    RegExp(r'(?<![a-z0-9])(\d{1,2})x(\d{1,3})(?![0-9])', caseSensitive: false),
    RegExp(
      r'season\s*(\d{1,2})\s*(?:episode|ep|e)\s*(\d{1,3})',
      caseSensitive: false,
    ),
    RegExp(r'第\s*(\d{1,3})\s*季\s*第\s*(\d{1,3})\s*[集話话]'),
  ];

  static final _chineseEpisodePattern = RegExp(r'第\s*(\d{1,3})\s*[集話话]');
  static final _animeEpisodePattern = RegExp(
    r'(?:^|\s)[-–—]\s*(\d{1,3})(?:v\d+)?(?=\s|$)',
  );
  static final _episodeWordPattern = RegExp(
    r'(?:^|\s)(?:ep|e)\.?\s*(\d{1,3})(?=\s|$)',
    caseSensitive: false,
  );
  static final _bracketEpisodePattern = RegExp(r'\[(\d{1,3})\]');

  static int? _seasonFromFolders(List<String>? folders) {
    if (folders == null) return null;
    for (final folder in folders.reversed) {
      final m = RegExp(
        r'season\s*0?(\d{1,2})',
        caseSensitive: false,
      ).firstMatch(folder);
      if (m != null) return int.tryParse(m.group(1)!);
      final cn = RegExp(r'第\s*(\d{1,3})\s*季').firstMatch(folder);
      if (cn != null) return int.tryParse(cn.group(1)!);
      final s = RegExp(
        r'(?<![a-z0-9])s(\d{1,2})(?![0-9])',
        caseSensitive: false,
      ).firstMatch(folder);
      if (s != null) return int.tryParse(s.group(1)!);
    }
    return null;
  }

  static bool _yearIsPlausibleTitleStart(String spaced, int index) {
    // A leading four-digit number with no other year is usually part of the
    // title (e.g. "1917", "2012"), not a release year.
    return index > 0;
  }

  static ParsedVideoInfo parse(String fileName, {List<String>? folders}) {
    final base = _baseName(fileName);
    var spaced = base
        .replaceAll(RegExp(r'[._]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final folderSeason = _seasonFromFolders(folders);

    // Keep the release year before stripping brackets and tags.
    int? year;
    final yearMatches = RegExp(r'(?<!\d)((?:19|20)\d{2})(?!\d)')
        .allMatches(spaced)
        .where((m) => _yearIsPlausibleTitleStart(spaced, m.start))
        .toList();
    if (yearMatches.isNotEmpty) {
      year = int.tryParse(yearMatches.last.group(1)!);
    }

    final hadReleaseTag =
        _releaseTagRegex.hasMatch(spaced) ||
        RegExp(
          r'\[[^\]]*(?:1080|720|2160|4k|hdr)[^\]]*\]',
          caseSensitive: false,
        ).hasMatch(base);

    // Detect an explicit SxxEyy / 1x02 / 第1季第2集 marker.
    _EpisodeMarker? marker;
    for (final pattern in _explicitEpisodePatterns) {
      final match = pattern.firstMatch(spaced);
      if (match != null) {
        marker = _EpisodeMarker(
          season: int.tryParse(match.group(1)!),
          episode: int.parse(match.group(2)!),
          start: match.start,
          end: match.end,
        );
        break;
      }
    }

    // Chinese "第 2 集" with a season inferred from the folder.
    if (marker == null) {
      final match = _chineseEpisodePattern.firstMatch(spaced);
      if (match != null) {
        marker = _EpisodeMarker(
          season: folderSeason,
          episode: int.parse(match.group(1)!),
          start: match.start,
          end: match.end,
        );
      }
    }

    // Anime style "Show - 01" and "Show EP01".
    if (marker == null) {
      final match = _animeEpisodePattern.firstMatch(spaced);
      if (match != null) {
        marker = _EpisodeMarker(
          season: folderSeason ?? 1,
          episode: int.parse(match.group(1)!),
          start: match.start,
          end: match.end,
        );
      }
    }
    if (marker == null) {
      final match = _episodeWordPattern.firstMatch(spaced);
      if (match != null) {
        marker = _EpisodeMarker(
          season: folderSeason ?? 1,
          episode: int.parse(match.group(1)!),
          start: match.start,
          end: match.end,
        );
      }
    }
    if (marker == null) {
      final match = _bracketEpisodePattern.firstMatch(spaced);
      if (match != null &&
          spaced
              .substring(0, match.start)
              .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
              .trim()
              .isNotEmpty) {
        marker = _EpisodeMarker(
          season: folderSeason ?? 1,
          episode: int.parse(match.group(1)!),
          start: match.start,
          end: match.end,
        );
      }
    }
    if (marker == null &&
        folderSeason != null &&
        RegExp(r'^\d{1,3}$').hasMatch(spaced.trim())) {
      marker = _EpisodeMarker(
        season: folderSeason,
        episode: int.parse(spaced.trim()),
        start: 0,
        end: spaced.length,
      );
    }

    // Clean the title: everything before the episode marker, then strip
    // brackets, release tags and the year.
    var titleRaw = marker == null ? spaced : spaced.substring(0, marker.start);

    titleRaw = titleRaw
        .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
        .replaceAll(RegExp(r'【[^】]*】'), ' ')
        .replaceAll(RegExp(r'\{[^}]*\}'), ' ');
    titleRaw = titleRaw.replaceAll(_releaseTagRegex, ' ');
    titleRaw = titleRaw.replaceAll(_chineseTagRegex, ' ');
    if (year != null) {
      titleRaw = titleRaw.replaceAll(
        RegExp('[(\\[]?\\s*${RegExp.escape(year.toString())}\\s*[)\\]]?'),
        ' ',
      );
    }
    titleRaw = titleRaw
        .replaceAll(RegExp(r'\s*[-–—]\s*$'), '')
        .replaceAll(RegExp(r'^[\s\-–—:：,，.·]+'), '')
        .replaceAll(RegExp(r'[\s\-–—:：,，.·]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (hadReleaseTag && titleRaw.contains(RegExp(r'[-–—]'))) {
      // Strip a trailing release-group suffix, but only when the name looked
      // like a release to begin with. This keeps titles such as "The Big Short".
      titleRaw = titleRaw.replaceAll(
        RegExp(r'\s*[-–—]\s*[A-Za-z0-9@._-]{1,30}$'),
        '',
      );
      titleRaw = titleRaw.trim();
    }

    if (titleRaw.isEmpty) {
      titleRaw = spaced
          .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }
    if (titleRaw.isEmpty) titleRaw = base;

    String? episodeTitle;
    if (marker != null && marker.end < spaced.length) {
      final after = spaced.substring(marker.end);
      final cleaned = after
          .replaceAll(RegExp(r'\[[^\]]*\]'), ' ')
          .replaceAll(_releaseTagRegex, ' ')
          .replaceAll(_chineseTagRegex, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceAll(RegExp(r'^[\s\-–—:：,，.·]+'), '')
          .replaceAll(RegExp(r'[\s\-–—:：,，.·]+$'), '');
      if (cleaned.isNotEmpty &&
          cleaned.length < 90 &&
          !RegExp(
            r'^(x26[45]|hevc|avc)$',
            caseSensitive: false,
          ).hasMatch(cleaned)) {
        episodeTitle = cleaned;
      }
    }

    final isEpisode = marker != null;
    final season = isEpisode ? (marker.season ?? folderSeason ?? 1) : null;
    final episode = isEpisode ? marker.episode : null;
    final seriesKey = isEpisode ? _seriesKey(titleRaw, year) : null;

    return ParsedVideoInfo(
      title: titleRaw,
      kind: isEpisode ? MediaKind.episode : MediaKind.movie,
      year: year,
      season: season,
      episode: episode,
      episodeTitle: episodeTitle,
      seriesKey: seriesKey,
    );
  }

  static String _seriesKey(String title, int? year) {
    final normalized = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^0-9a-zA-Z\u4e00-\u9fff]+'), '')
        .trim();
    return 'name:$normalized${year == null ? '' : ':$year'}';
  }
}

class _EpisodeMarker {
  const _EpisodeMarker({
    required this.season,
    required this.episode,
    required this.start,
    required this.end,
  });

  final int? season;
  final int episode;
  final int start;
  final int end;
}
