import 'package:collection/collection.dart';

import '../core/common/utils.dart';

enum MediaKind {
  movie('movie'),
  episode('episode');

  const MediaKind(this.dbValue);
  final String dbValue;

  static MediaKind fromDb(String value) =>
      value == MediaKind.episode.dbValue ? MediaKind.episode : MediaKind.movie;
}

enum ScrapeState {
  pending('pending'),
  done('done'),
  failed('failed'),
  skipped('skipped');

  const ScrapeState(this.dbValue);
  final String dbValue;

  static ScrapeState fromDb(String? value) {
    return switch (value) {
      'done' => ScrapeState.done,
      'failed' => ScrapeState.failed,
      'skipped' => ScrapeState.skipped,
      _ => ScrapeState.pending,
    };
  }
}

class MediaItem {
  const MediaItem({
    this.id,
    required this.sourceId,
    required this.path,
    required this.fileName,
    required this.size,
    required this.modifiedAt,
    required this.kind,
    required this.title,
    this.year,
    this.season,
    this.episode,
    this.seriesKey,
    this.seriesTitle,
    this.tmdbId,
    this.imdbId,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.stillPath,
    this.localPoster,
    this.localBackdrop,
    this.rating,
    this.genres = const [],
    this.runtime,
    this.releaseDate,
    this.nfoPath,
    this.scrapeState = ScrapeState.pending,
    this.scrapeError,
    required this.addedAt,
    required this.updatedAt,
  });

  final int? id;
  final int sourceId;
  final String path;
  final String fileName;
  final int size;
  final int modifiedAt;
  final MediaKind kind;

  /// Movie title, or episode title for an episode row.
  final String title;
  final int? year;
  final int? season;
  final int? episode;
  final String? seriesKey;
  final String? seriesTitle;
  final int? tmdbId;
  final String? imdbId;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? stillPath;
  final String? localPoster;
  final String? localBackdrop;
  final double? rating;
  final List<String> genres;
  final int? runtime;
  final String? releaseDate;
  final String? nfoPath;
  final ScrapeState scrapeState;
  final String? scrapeError;
  final int addedAt;
  final int updatedAt;

  bool get isMovie => kind == MediaKind.movie;
  bool get isEpisode => kind == MediaKind.episode;
  int get durationSeconds => runtime == null ? 0 : runtime! * 60;

  String get displayTitle {
    if (isMovie) return title;
    if (title.trim().isEmpty) {
      return episodeCode(season, episode).isEmpty
          ? (seriesTitle ?? fileName)
          : episodeCode(season, episode);
    }
    return title;
  }

  String get showName => seriesTitle?.trim().isNotEmpty == true
      ? seriesTitle!.trim()
      : title.trim();

  MediaItem copyWith({
    int? id,
    int? sourceId,
    String? path,
    String? fileName,
    int? size,
    int? modifiedAt,
    MediaKind? kind,
    String? title,
    int? year,
    int? season,
    int? episode,
    String? seriesKey,
    String? seriesTitle,
    int? tmdbId,
    String? imdbId,
    String? overview,
    String? posterPath,
    String? backdropPath,
    String? stillPath,
    String? localPoster,
    String? localBackdrop,
    double? rating,
    List<String>? genres,
    int? runtime,
    String? releaseDate,
    String? nfoPath,
    ScrapeState? scrapeState,
    String? scrapeError,
    int? addedAt,
    int? updatedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      year: year ?? this.year,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      seriesKey: seriesKey ?? this.seriesKey,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      overview: overview ?? this.overview,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      stillPath: stillPath ?? this.stillPath,
      localPoster: localPoster ?? this.localPoster,
      localBackdrop: localBackdrop ?? this.localBackdrop,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      runtime: runtime ?? this.runtime,
      releaseDate: releaseDate ?? this.releaseDate,
      nfoPath: nfoPath ?? this.nfoPath,
      scrapeState: scrapeState ?? this.scrapeState,
      scrapeError: scrapeError ?? this.scrapeError,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MediaItem.fromMap(Map<String, Object?> map) {
    return MediaItem(
      id: map['id'] as int?,
      sourceId: map['source_id'] as int? ?? 0,
      path: map['path'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      size: map['size'] as int? ?? 0,
      modifiedAt: map['modified_at'] as int? ?? 0,
      kind: MediaKind.fromDb(map['kind'] as String? ?? 'movie'),
      title: map['title'] as String? ?? '',
      year: map['year'] as int?,
      season: map['season'] as int?,
      episode: map['episode'] as int?,
      seriesKey: map['series_key'] as String?,
      seriesTitle: map['series_title'] as String?,
      tmdbId: map['tmdb_id'] as int?,
      imdbId: map['imdb_id'] as String?,
      overview: map['overview'] as String?,
      posterPath: map['poster_path'] as String?,
      backdropPath: map['backdrop_path'] as String?,
      stillPath: map['still_path'] as String?,
      localPoster: map['local_poster'] as String?,
      localBackdrop: map['local_backdrop'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      genres:
          (map['genres'] as String?)
              ?.split('\u001f')
              .where((g) => g.isNotEmpty)
              .toList() ??
          const [],
      runtime: map['runtime'] as int?,
      releaseDate: map['release_date'] as String?,
      nfoPath: map['nfo_path'] as String?,
      scrapeState: ScrapeState.fromDb(map['scrape_state'] as String?),
      scrapeError: map['scrape_error'] as String?,
      addedAt: map['added_at'] as int? ?? 0,
      updatedAt: map['updated_at'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'path': path,
      'file_name': fileName,
      'size': size,
      'modified_at': modifiedAt,
      'kind': kind.dbValue,
      'title': title,
      'year': year,
      'season': season,
      'episode': episode,
      'series_key': seriesKey,
      'series_title': seriesTitle,
      'tmdb_id': tmdbId,
      'imdb_id': imdbId,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'still_path': stillPath,
      'local_poster': localPoster,
      'local_backdrop': localBackdrop,
      'rating': rating,
      'genres': genres.isEmpty ? null : genres.join('\u001f'),
      'runtime': runtime,
      'release_date': releaseDate,
      'nfo_path': nfoPath,
      'scrape_state': scrapeState.dbValue,
      'scrape_error': scrapeError,
      'added_at': addedAt,
      'updated_at': updatedAt,
    };
  }
}

/// TMDB / NFO values to merge into one row. A null field means "leave alone".
class ScrapedMetadata {
  const ScrapedMetadata({
    this.title,
    this.year,
    this.season,
    this.episode,
    this.seriesKey,
    this.seriesTitle,
    this.tmdbId,
    this.imdbId,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.stillPath,
    this.rating,
    this.genres,
    this.runtime,
    this.releaseDate,
    this.metadataSource,
    this.metadataSourceId,
  });

  final String? title;
  final int? year;
  final int? season;
  final int? episode;
  final String? seriesKey;
  final String? seriesTitle;
  final int? tmdbId;
  final String? imdbId;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final String? stillPath;
  final double? rating;
  final List<String>? genres;
  final int? runtime;
  final String? releaseDate;

  /// 元数据来源（如 `tmdb`、`douban`），与媒体文件所属的 `source_id` 无关。
  final String? metadataSource;
  final String? metadataSourceId;

  Map<String, Object?> toDbUpdate() {
    final values = <String, Object?>{};
    void put(String key, Object? value) {
      if (value != null) values[key] = value;
    }

    put('title', title);
    put('year', year);
    put('season', season);
    put('episode', episode);
    put('series_key', seriesKey);
    put('series_title', seriesTitle);
    put('tmdb_id', tmdbId);
    put('imdb_id', imdbId);
    put('overview', overview);
    put('poster_path', posterPath);
    put('backdrop_path', backdropPath);
    put('still_path', stillPath);
    put('rating', rating);
    put('runtime', runtime);
    put('release_date', releaseDate);
    put('metadata_source', metadataSource);
    put('metadata_source_id', metadataSourceId);
    if (genres != null && genres!.isNotEmpty) {
      values['genres'] = genres!.join('\u001f');
    }
    return values;
  }
}

/// Episode rows grouped into one show for the poster wall.
class SeriesGroup {
  SeriesGroup(List<MediaItem> items)
    : assert(items.isNotEmpty),
      episodes = List.unmodifiable(
        [...items]..sort((a, b) {
          final s = (a.season ?? 1).compareTo(b.season ?? 1);
          if (s != 0) return s;
          return (a.episode ?? 0).compareTo(b.episode ?? 0);
        }),
      );

  final List<MediaItem> episodes;

  MediaItem get lead => episodes.first;

  String get key => lead.seriesKey ?? 'id:${lead.id}';
  String get title => lead.showName;
  int? get year => episodes
      .map((e) => e.year)
      .whereType<int>()
      .fold<int?>(null, (min, y) => min == null || y < min ? y : min);
  int? get tmdbId => episodes.map((e) => e.tmdbId).whereType<int>().firstOrNull;
  String? get overview => episodes
      .map((e) => e.overview)
      .where((o) => o != null && o.trim().isNotEmpty)
      .firstOrNull;
  String? get posterPath =>
      episodes.map((e) => e.posterPath).whereType<String>().firstOrNull;
  String? get backdropPath =>
      episodes.map((e) => e.backdropPath).whereType<String>().firstOrNull;
  String? get localPoster =>
      episodes.map((e) => e.localPoster).whereType<String>().firstOrNull;
  String? get localBackdrop =>
      episodes.map((e) => e.localBackdrop).whereType<String>().firstOrNull;
  double? get rating =>
      episodes.map((e) => e.rating).whereType<double>().firstOrNull;
  List<String> get genres =>
      episodes.map((e) => e.genres).where((g) => g.isNotEmpty).firstOrNull ??
      const [];
  int get episodeCount => episodes.length;
  List<int> get seasons =>
      episodes.map((e) => e.season ?? 1).toSet().toList()..sort();
  int get addedAt =>
      episodes.map((e) => e.addedAt).fold<int>(0, (a, b) => a > b ? a : b);

  MediaItem? episodeNumber(int season, int episode) {
    for (final item in episodes) {
      if ((item.season ?? 1) == season && (item.episode ?? 0) == episode) {
        return item;
      }
    }
    return null;
  }

  /// Next episode after the supplied one, if any.
  MediaItem? nextAfter(MediaItem current) {
    final index = episodes.indexWhere((e) => e.id == current.id);
    if (index < 0 || index + 1 >= episodes.length) return null;
    return episodes[index + 1];
  }
}

/// A card on the wall: either a film or a grouped series.
class LibraryEntry {
  const LibraryEntry._({this.movie, this.series});

  factory LibraryEntry.movie(MediaItem movie) => LibraryEntry._(movie: movie);
  factory LibraryEntry.series(SeriesGroup series) =>
      LibraryEntry._(series: series);

  final MediaItem? movie;
  final SeriesGroup? series;

  bool get isSeries => series != null;
  MediaItem get lead => movie ?? series!.lead;
  String get key => isSeries ? 'series:${series!.key}' : 'movie:${movie!.id}';
  String get title => isSeries ? series!.title : movie!.title;
  int? get year => isSeries ? series!.year : movie!.year;
  String? get overview => isSeries ? series!.overview : movie!.overview;
  String? get posterPath => isSeries ? series!.posterPath : movie!.posterPath;
  String? get backdropPath =>
      isSeries ? series!.backdropPath : movie!.backdropPath;
  String? get localPoster =>
      isSeries ? series!.localPoster : movie!.localPoster;
  String? get localBackdrop =>
      isSeries ? series!.localBackdrop : movie!.localBackdrop;
  double? get rating => isSeries ? series!.rating : movie!.rating;
  List<String> get genres => isSeries ? series!.genres : movie!.genres;
  int get addedAt => isSeries ? series!.addedAt : movie!.addedAt;
  int? get tmdbId => isSeries ? series!.tmdbId : movie!.tmdbId;
  ScrapeState get scrapeState => lead.scrapeState;
  int? get runtime => isSeries ? null : movie!.runtime;
  int get sourceId => lead.sourceId;
  String get sourcePath => lead.path;
}

class PlaybackProgress {
  const PlaybackProgress({
    required this.mediaId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
    required this.completed,
  });

  final int mediaId;
  final int positionMs;
  final int durationMs;
  final int updatedAt;
  final bool completed;

  double get fraction {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }
}

class ContinueItem {
  const ContinueItem({required this.media, required this.progress});
  final MediaItem media;
  final PlaybackProgress progress;
}
