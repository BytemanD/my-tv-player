import 'dart:async';

import '../media_repository.dart';
import '../models.dart';
import '../scanner/nfo_parser.dart';
import '../settings_service.dart';
import 'tmdb_client.dart';

class ScrapeProgress {
  const ScrapeProgress({
    required this.running,
    required this.done,
    required this.total,
    required this.current,
    required this.succeeded,
    required this.failed,
  });

  factory ScrapeProgress.idle() => const ScrapeProgress(
    running: false,
    done: 0,
    total: 0,
    current: '',
    succeeded: 0,
    failed: 0,
  );

  final bool running;
  final int done;
  final int total;
  final String current;
  final int succeeded;
  final int failed;

  double get fraction => total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

class ScrapeReport {
  ScrapeReport({
    required this.configured,
    required this.succeeded,
    required this.failed,
    required this.errors,
    required this.cancelled,
    this.fatal,
  });

  final bool configured;
  final int succeeded;
  final int failed;
  final List<String> errors;
  final bool cancelled;
  final String? fatal;

  int get processed => succeeded + failed;
}

class MetadataScraper {
  MetadataScraper(this._repository);

  final MediaRepository _repository;
  bool _cancelled = false;
  bool _fatal = false;
  String? _fatalMessage;
  final Map<String, NfoData?> _nfoCache = {};
  final Map<String, List<TmdbEpisode>> _seasonCache = {};

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  Future<ScrapeReport> run({
    required String apiKey,
    required TmdbLanguage language,
    required void Function(ScrapeProgress progress) onProgress,
  }) async {
    _cancelled = false;
    _fatal = false;
    _fatalMessage = null;
    _seasonCache.clear();

    if (apiKey.trim().isEmpty) {
      return ScrapeReport(
        configured: false,
        succeeded: 0,
        failed: 0,
        errors: const ['未配置 TMDB API Key'],
        cancelled: false,
      );
    }

    final client = TmdbClient(apiKey: apiKey, language: language.code);

    final pending = await _repository.pendingItems();
    final movies = pending.where((m) => m.isMovie).toList();
    final episodeGroups = <String, List<MediaItem>>{};
    for (final episode in pending.where((m) => m.isEpisode)) {
      final key = episode.seriesKey ?? 'media:${episode.id}';
      episodeGroups.putIfAbsent(key, () => []).add(episode);
    }

    // Pull in already-scraped siblings so show metadata stays consistent.
    final groups = <String, List<MediaItem>>{};
    for (final entry in episodeGroups.entries) {
      final siblings = await _repository.episodesForSeries(entry.key);
      groups[entry.key] = siblings.isEmpty ? entry.value : siblings;
    }

    final total = movies.length + groups.length;
    var done = 0;
    var succeeded = 0;
    var failed = 0;
    final errors = <String>[];

    void emit(String current) {
      onProgress(
        ScrapeProgress(
          running: true,
          done: done,
          total: total,
          current: current,
          succeeded: succeeded,
          failed: failed,
        ),
      );
    }

    emit('准备刮削…');

    Future<void> runMovie(MediaItem movie) async {
      if (_cancelled || _fatal) return;
      emit(movie.title);
      try {
        final ok = await _scrapeMovie(movie, client);
        if (ok) {
          succeeded++;
        } else {
          failed++;
          errors.add('${movie.title}：未找到匹配条目');
        }
      } on TmdbException catch (error) {
        if (error.statusCode == 401) {
          _fatal = true;
          _fatalMessage = error.message;
        } else {
          failed++;
          errors.add('${movie.title}：${error.message}');
          await _repository.setScrapeState(
            movie.id!,
            ScrapeState.failed,
            error: error.message,
          );
        }
      } catch (error) {
        failed++;
        errors.add('${movie.title}：${_short(error)}');
        await _repository.setScrapeState(
          movie.id!,
          ScrapeState.failed,
          error: _short(error),
        );
      } finally {
        done++;
        emit(movie.title);
      }
    }

    Future<void> runSeries(List<MediaItem> episodes) async {
      if (_cancelled || _fatal) return;
      final lead = episodes.first;
      final label = lead.seriesTitle?.trim().isNotEmpty == true
          ? lead.seriesTitle!
          : lead.title;
      emit(label);
      try {
        final ok = await _scrapeSeries(episodes, client);
        if (ok) {
          succeeded++;
        } else {
          failed++;
          errors.add('$label：未找到匹配条目');
        }
      } on TmdbException catch (error) {
        if (error.statusCode == 401) {
          _fatal = true;
          _fatalMessage = error.message;
        } else {
          failed++;
          errors.add('$label：${error.message}');
          await _repository.setSeriesScrapeState(
            lead.seriesKey ?? 'media:${lead.id}',
            ScrapeState.failed,
            error: error.message,
          );
        }
      } catch (error) {
        failed++;
        errors.add('$label：${_short(error)}');
        await _repository.setSeriesScrapeState(
          lead.seriesKey ?? 'media:${lead.id}',
          ScrapeState.failed,
          error: _short(error),
        );
      } finally {
        done++;
        emit(label);
      }
    }

    final tasks = <Future<void> Function()>[
      for (final movie in movies) () => runMovie(movie),
      for (final group in groups.values) () => runSeries(group),
    ];
    await _pool(tasks, 3);

    client.dispose();

    return ScrapeReport(
      configured: true,
      succeeded: succeeded,
      failed: failed,
      errors: errors.take(20).toList(),
      cancelled: _cancelled,
      fatal: _fatalMessage,
    );
  }

  Future<bool> _scrapeMovie(MediaItem movie, TmdbClient client) async {
    final nfo = await _nfoFor(movie);
    final title = nfo?.preferredTitle ?? movie.title;
    final year = nfo?.year ?? movie.year;

    TmdbTitle? details;
    if (nfo?.tmdbId != null) {
      details = await client.movieDetails(nfo!.tmdbId!);
    } else {
      final candidates = await client.searchMovie(title, year: year);
      final match = TmdbMatcher.best(candidates, title: title, year: year);
      if (match != null) {
        details = await client.movieDetails(match.id);
      }
    }

    if (details != null) {
      await _repository.applyMetadata(
        movie.id!,
        ScrapedMetadata(
          title: _nonEmpty(details.title) ?? title,
          year: details.year ?? year,
          tmdbId: details.id,
          imdbId: details.imdbId,
          overview: _nonEmpty(details.overview) ?? nfo?.plot,
          posterPath: details.posterPath ?? _remoteArt(nfo?.poster),
          backdropPath: details.backdropPath ?? _remoteArt(nfo?.fanart),
          rating: details.rating ?? nfo?.rating,
          genres: details.genres.isNotEmpty ? details.genres : nfo?.genres,
          runtime: details.runtime ?? nfo?.runtime,
          releaseDate: details.releaseDate ?? nfo?.premiered,
        ),
      );
      await _repository.setScrapeState(movie.id!, ScrapeState.done);
      return true;
    }

    if (nfo != null && nfo.hasUsefulData) {
      await _repository.applyMetadata(
        movie.id!,
        _metadataFromNfo(
          nfo,
          fallbackTitle: movie.title,
          fallbackYear: movie.year,
        ),
      );
      await _repository.setScrapeState(
        movie.id!,
        ScrapeState.done,
        error: '使用本地 NFO',
      );
      return true;
    }

    await _repository.setScrapeState(
      movie.id!,
      ScrapeState.failed,
      error: '未找到匹配条目',
    );
    return false;
  }

  Future<bool> _scrapeSeries(
    List<MediaItem> episodes,
    TmdbClient client,
  ) async {
    final lead = episodes.first;
    var nfo = await _nfoFor(lead);
    for (final episode in episodes) {
      final candidate = await _nfoFor(episode);
      if (candidate?.tmdbId != null || candidate?.showTitle != null) {
        nfo = candidate;
        break;
      }
    }

    final title =
        nfo?.showTitle ?? nfo?.preferredTitle ?? lead.seriesTitle ?? lead.title;
    final year = nfo?.year ?? lead.year;
    final oldKey = lead.seriesKey ?? 'media:${lead.id}';

    TmdbTitle? show;
    if (nfo?.tmdbId != null) {
      show = await client.tvDetails(nfo!.tmdbId!);
    } else {
      final candidates = await client.searchTv(title, year: year);
      final match = TmdbMatcher.best(candidates, title: title, year: year);
      if (match != null) {
        show = await client.tvDetails(match.id);
      }
    }

    if (show != null) {
      final newKey = 'tmdb:${show.id}';
      if (newKey != oldKey) {
        await _repository.renameSeriesKey(oldKey, newKey);
      }
      await _repository.applySeriesMetadata(
        newKey,
        ScrapedMetadata(
          seriesKey: newKey,
          seriesTitle: _nonEmpty(show.title) ?? title,
          year: show.year ?? year,
          tmdbId: show.id,
          imdbId: show.imdbId,
          overview: _nonEmpty(show.overview) ?? nfo?.plot,
          posterPath: show.posterPath ?? _remoteArt(nfo?.poster),
          backdropPath: show.backdropPath ?? _remoteArt(nfo?.fanart),
          rating: show.rating ?? nfo?.rating,
          genres: show.genres.isNotEmpty ? show.genres : nfo?.genres,
        ),
      );

      final seasons = episodes.map((e) => e.season ?? 1).toSet().toList()
        ..sort();
      for (final season in seasons) {
        final tmdbEpisodes = await _season(show.id, season, client);
        final byNumber = {for (final e in tmdbEpisodes) e.episode: e};
        for (final episode in episodes.where(
          (e) => (e.season ?? 1) == season,
        )) {
          final tmdbEpisode = byNumber[episode.episode ?? 0];
          final localNfo = await _nfoFor(episode);
          await _repository.applyMetadata(
            episode.id!,
            ScrapedMetadata(
              title:
                  _nonEmpty(tmdbEpisode?.name) ??
                  (localNfo?.episode != null ? localNfo?.preferredTitle : null),
              year: show.year ?? year,
              season: season,
              episode: episode.episode,
              seriesKey: newKey,
              seriesTitle: show.title,
              tmdbId: show.id,
              imdbId: show.imdbId,
              overview: _nonEmpty(tmdbEpisode?.overview) ?? localNfo?.plot,
              stillPath: tmdbEpisode?.stillPath,
              rating: tmdbEpisode?.rating,
              runtime: tmdbEpisode?.runtime ?? localNfo?.runtime,
              releaseDate: tmdbEpisode?.airDate ?? localNfo?.premiered,
            ),
          );
          await _repository.setScrapeState(episode.id!, ScrapeState.done);
        }
      }

      // Episodes that had a gap in TMDB still belong to the matched show.
      await _repository.setSeriesScrapeState(newKey, ScrapeState.done);
      return true;
    }

    if (nfo != null && nfo.hasUsefulData) {
      await _repository.applySeriesMetadata(
        oldKey,
        ScrapedMetadata(
          seriesTitle: nfo.showTitle ?? nfo.preferredTitle ?? title,
          year: nfo.year ?? year,
          tmdbId: nfo.tmdbId,
          imdbId: nfo.imdbId,
          overview: nfo.plot,
          posterPath: _remoteArt(nfo.poster),
          backdropPath: _remoteArt(nfo.fanart),
          rating: nfo.rating,
          genres: nfo.genres,
        ),
      );
      for (final episode in episodes) {
        final localNfo = await _nfoFor(episode);
        final values = localNfo == null
            ? const ScrapedMetadata()
            : _metadataFromNfo(
                localNfo,
                fallbackTitle: episode.title,
                fallbackYear: episode.year,
                season: episode.season,
                episode: episode.episode,
              );
        await _repository.applyMetadata(episode.id!, values);
        await _repository.setScrapeState(
          episode.id!,
          ScrapeState.done,
          error: '使用本地 NFO',
        );
      }
      return true;
    }

    await _repository.setSeriesScrapeState(
      oldKey,
      ScrapeState.failed,
      error: '未找到匹配条目',
    );
    return false;
  }

  Future<List<TmdbEpisode>> _season(
    int showId,
    int season,
    TmdbClient client,
  ) async {
    final key = '$showId:$season';
    final cached = _seasonCache[key];
    if (cached != null) return cached;
    final episodes = await client.seasonEpisodes(showId, season);
    _seasonCache[key] = episodes;
    return episodes;
  }

  Future<NfoData?> _nfoFor(MediaItem item) async {
    final path = item.nfoPath;
    if (path == null) return null;
    if (_nfoCache.containsKey(path)) return _nfoCache[path];
    final data = await NfoParser.parseFile(path);
    _nfoCache[path] = data;
    return data;
  }

  ScrapedMetadata _metadataFromNfo(
    NfoData nfo, {
    String? fallbackTitle,
    int? fallbackYear,
    int? season,
    int? episode,
  }) {
    return ScrapedMetadata(
      title: nfo.preferredTitle ?? fallbackTitle,
      year: nfo.year ?? fallbackYear,
      season: nfo.season ?? season,
      episode: nfo.episode ?? episode,
      tmdbId: nfo.tmdbId,
      imdbId: nfo.imdbId,
      overview: nfo.plot,
      posterPath: _remoteArt(nfo.poster),
      backdropPath: _remoteArt(nfo.fanart),
      rating: nfo.rating,
      genres: nfo.genres,
      runtime: nfo.runtime,
      releaseDate: nfo.premiered,
    );
  }

  Future<void> _pool(
    List<Future<void> Function()> tasks,
    int concurrency,
  ) async {
    var cursor = 0;
    Future<void> worker() async {
      while (!_cancelled && !_fatal) {
        final index = cursor++;
        if (index >= tasks.length) return;
        await tasks[index]();
      }
    }

    await Future.wait(List.generate(concurrency.clamp(1, 4), (_) => worker()));
  }

  String? _remoteArt(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return null;
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String _short(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    return text.length > 120 ? '${text.substring(0, 117)}...' : text;
  }
}
