import 'dart:async';

import 'package:luma_tv/core/common/log.dart';

import '../media_repository.dart';
import '../models.dart';
import '../scanner/nfo_parser.dart';
import '../settings_service.dart';
import 'douban_client.dart';
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

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  Future<ScrapeReport> run({
    required String apiKey,
    required TmdbLanguage language,
    required void Function(ScrapeProgress progress) onProgress,
    String doubanApiKey = '',
  }) async {
    _cancelled = false;
    _fatal = false;
    _fatalMessage = null;

    if (apiKey.trim().isEmpty) {
      return ScrapeReport(
        configured: false,
        succeeded: 0,
        failed: 0,
        errors: const ['未配置 TMDB API Key'],
        cancelled: false,
      );
    }

    final tmdbClient = TmdbClient(apiKey: apiKey, language: language.code);
    final doubanClient = DoubanClient(apiKey: doubanApiKey);

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
      logger.i('开始：${movie.title}');
      try {
        final ok = await _scrapeMovie(movie, tmdbClient, doubanClient);
        if (ok) {
          succeeded++;
          logger.i('完成：${movie.title}');
        } else {
          failed++;
          errors.add('${movie.title}：未找到匹配条目');
          logger.i('失败：${movie.title} - 未找到匹配条目');
        }
      } on TmdbException catch (error) {
        if (error.statusCode == 401) {
          _fatal = true;
          _fatalMessage = error.message;
          logger.i('致命错误：${error.message}');
        } else {
          failed++;
          errors.add('${movie.title}：${error.message}');
          logger.i('失败：${movie.title} - ${error.message}');
          await _repository.setScrapeState(
            movie.id!,
            ScrapeState.failed,
            error: error.message,
          );
        }
      } catch (error) {
        failed++;
        errors.add('${movie.title}：${_short(error)}');
        logger.i('失败：${movie.title} - ${_short(error)}');
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
      logger.i('开始：$label');
      try {
        final ok = await _scrapeSeries(episodes, tmdbClient, doubanClient);
        if (ok) {
          succeeded++;
          logger.i('完成：$label');
        } else {
          failed++;
          errors.add('$label：未找到匹配条目');
          logger.i('失败：$label - 未找到匹配条目');
        }
      } on TmdbException catch (error) {
        if (error.statusCode == 401) {
          _fatal = true;
          _fatalMessage = error.message;
          logger.i('致命错误：${error.message}');
        } else {
          failed++;
          errors.add('$label：${error.message}');
          logger.i('失败：$label - ${error.message}');
          await _repository.setSeriesScrapeState(
            lead.seriesKey ?? 'media:${lead.id}',
            ScrapeState.failed,
            error: error.message,
          );
        }
      } catch (error) {
        failed++;
        errors.add('$label：${_short(error)}');
        logger.i('失败：$label - ${_short(error)}');
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

    tmdbClient.dispose();
    doubanClient.dispose();

    logger.i('完成：成功 $succeeded，失败 $failed，共 $total');
    if (errors.isNotEmpty) {
      logger.i('错误列表：');
      for (final e in errors.take(20)) {
        logger.i('  - $e');
      }
    }

    return ScrapeReport(
      configured: true,
      succeeded: succeeded,
      failed: failed,
      errors: errors.take(20).toList(),
      cancelled: _cancelled,
      fatal: _fatalMessage,
    );
  }

  Future<bool> scrapeSingle(
    MediaItem item,
    String tmdbApiKey,
    String language, {
    bool forceRescan = false,
    String doubanApiKey = '',
  }) async {
    final tmdbClient = TmdbClient(apiKey: tmdbApiKey, language: language);
    final doubanClient = DoubanClient(apiKey: doubanApiKey);
    try {
      if (item.isMovie) {
        return await _scrapeMovie(
          item,
          tmdbClient,
          doubanClient,
          forceRescan: forceRescan,
        );
      } else {
        return await _scrapeSeries(
          [item],
          tmdbClient,
          doubanClient,
          forceRescan: forceRescan,
        );
      }
    } finally {
      tmdbClient.dispose();
      doubanClient.dispose();
    }
  }

  Future<bool> _scrapeMovie(
    MediaItem movie,
    TmdbClient tmdbClient,
    DoubanClient doubanClient, {
    bool forceRescan = false,
  }) async {
    final nfo = await _nfoFor(movie);
    final title = nfo?.preferredTitle ?? movie.title;
    final year = nfo?.year ?? movie.year;

    logger.i(
      '搜索电影：$title (年份：$year, 语言：${tmdbClient.language}, forceRescan：$forceRescan)',
    );

    TmdbTitle? details;
    TmdbException? tmdbError;
    Object? tmdbOtherError;
    try {
      if (!forceRescan && nfo?.tmdbId != null) {
        final nfoTmdbId = nfo!.tmdbId!;
        details = await tmdbClient.movieDetails(nfoTmdbId);
        logger.i('按TMDB ID直接获取：$nfoTmdbId -> ${details.title}');
      } else {
        if (forceRescan && nfo?.tmdbId != null) {
          final nfoTmdbId = nfo!.tmdbId;
          logger.i('强制重新搜索，忽略 NFO 中的 TMDB ID：$nfoTmdbId');
        }
        final candidates = await tmdbClient.searchMovie(title, year: year);
        logger.i('TMDB 搜索结果：${candidates.length} 个候选');
        for (final c in candidates.take(5)) {
          logger.i(
            '  候选：id=${c.id} title="${c.title}" original="${c.originalTitle}" year=${c.year} popularity=${c.popularity.toStringAsFixed(1)}',
          );
        }
        final match = TmdbMatcher.best(candidates, title: title, year: year);
        if (match != null) {
          logger.i(
            'TMDB 匹配成功：id=${match.id} title="${match.title}" year=${match.year}',
          );
          details = await tmdbClient.movieDetails(match.id);
          logger.i(
            'TMDB 详情标题：${details.title} (original: ${details.originalTitle})',
          );
        } else {
          logger.i('TMDB 匹配失败：没有达到阈值的候选，尝试豆瓣');
        }
      }
    } on TmdbException catch (error) {
      tmdbError = error;
      logger.i('TMDB 请求失败，尝试豆瓣：${error.message}');
    } catch (error) {
      tmdbOtherError = error;
      logger.i('TMDB 请求异常，尝试豆瓣：${_short(error)}');
    }

    // TMDB 失败（网络错误、超时、API Key 无效、详情获取失败等）
    // 或没有匹配结果时，都尝试豆瓣。
    if (details == null) {
      final doubanOk = await _scrapeMovieFromDouban(
        movie: movie,
        title: title,
        year: year,
        doubanClient: doubanClient,
      );
      if (doubanOk) return true;
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

    // 豆瓣也不可用时，把 TMDB 的原始错误抛出去，
    // 让调用方能够显示“连接失败”而不是误报“未找到匹配条目”。
    if (tmdbError != null) throw tmdbError;
    if (tmdbOtherError != null) throw tmdbOtherError;

    await _repository.setScrapeState(
      movie.id!,
      ScrapeState.failed,
      error: '未找到匹配条目',
    );
    return false;
  }

  /// TMDB 不可用或无匹配时，用豆瓣刮削电影。
  ///
  /// 返回 true 表示豆瓣已成功写入元数据。
  Future<bool> _scrapeMovieFromDouban({
    required MediaItem movie,
    required String title,
    required int? year,
    required DoubanClient doubanClient,
  }) async {
    if (doubanClient.apiKey.isEmpty) {
      logger.i('豆瓣 API Key 未配置，跳过豆瓣刮削');
      return false;
    }
    try {
      final doubanCandidates = await doubanClient.searchMovie(
        title,
        year: year,
      );
      logger.i('豆瓣搜索结果：${doubanCandidates.length} 个候选');
      for (final c in doubanCandidates.take(5)) {
        logger.i(
          '  豆瓣候选：id=${c.id} title="${c.title}" original="${c.originalTitle}" year=${c.year} rating=${c.rating}',
        );
      }
      final doubanMatch = DoubanMatcher.best(
        doubanCandidates,
        title: title,
        year: year,
      );
      if (doubanMatch == null) {
        logger.i('豆瓣匹配失败：没有达到阈值的候选');
        return false;
      }
      logger.i(
        '豆瓣匹配成功：id=${doubanMatch.id} title="${doubanMatch.title}" year=${doubanMatch.year}',
      );
      final doubanDetails = await _doubanDetails(doubanClient, doubanMatch);
      await _applyDoubanMetadata(movie.id!, doubanDetails);
      logger.i('豆瓣刮削完成：${movie.title}');
      return true;
    } catch (e) {
      logger.i('豆瓣异常：$e');
      return false;
    }
  }

  Future<bool> _scrapeSeries(
    List<MediaItem> episodes,
    TmdbClient tmdbClient,
    DoubanClient doubanClient, {
    bool forceRescan = false,
  }) async {
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

    logger.i(
      '搜索剧集：$title (年份：$year, 语言：${tmdbClient.language}, forceRescan：$forceRescan)',
    );

    TmdbTitle? show;
    TmdbException? tmdbError;
    Object? tmdbOtherError;
    try {
      if (!forceRescan && nfo?.tmdbId != null) {
        final nfoTmdbId = nfo!.tmdbId!;
        show = await tmdbClient.tvDetails(nfoTmdbId);
        logger.i('按TMDB ID直接获取剧集：$nfoTmdbId -> ${show.title}');
      } else {
        if (forceRescan && nfo?.tmdbId != null) {
          final nfoTmdbId = nfo!.tmdbId;
          logger.i('强制重新搜索剧集，忽略 NFO 中的 TMDB ID：$nfoTmdbId');
        }
        final candidates = await tmdbClient.searchTv(title, year: year);
        logger.i('TMDB 搜索结果：${candidates.length} 个候选');
        for (final c in candidates.take(5)) {
          logger.i(
            '  候选：id=${c.id} title="${c.title}" original="${c.originalTitle}" year=${c.year} popularity=${c.popularity.toStringAsFixed(1)}',
          );
        }
        final match = TmdbMatcher.best(candidates, title: title, year: year);
        if (match != null) {
          logger.i(
            'TMDB 匹配成功：id=${match.id} title="${match.title}" year=${match.year}',
          );
          show = await tmdbClient.tvDetails(match.id);
          logger.i('TMDB 详情标题：${show.title} (original: ${show.originalTitle})');
        } else {
          logger.i('TMDB 匹配失败：没有达到阈值的候选，尝试豆瓣');
        }
      }
    } on TmdbException catch (error) {
      tmdbError = error;
      logger.i('TMDB 请求失败，尝试豆瓣：${error.message}');
    } catch (error) {
      tmdbOtherError = error;
      logger.i('TMDB 请求异常，尝试豆瓣：${_short(error)}');
    }

    // TMDB 请求失败或无匹配结果时，都尝试豆瓣。
    if (show == null) {
      final doubanOk = await _scrapeSeriesFromDouban(
        oldKey: oldKey,
        title: title,
        year: year,
        doubanClient: doubanClient,
      );
      if (doubanOk) return true;
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

      // 剧集只刮削剧集级别信息，不再逐集请求 TMDB 的分集详情。
      // applySeriesMetadata 会把剧集信息写到该 series_key 下的所有分集，
      // setSeriesScrapeState 统一标记为已完成。
      await _repository.setSeriesScrapeState(newKey, ScrapeState.done);
      logger.i('剧集刮削完成（仅剧集级别）：${show.title}，共 ${episodes.length} 集');
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
      // 本地 NFO 同样只应用剧集级别信息，分集标题沿用扫描结果。
      await _repository.setSeriesScrapeState(
        oldKey,
        ScrapeState.done,
        error: '使用本地 NFO',
      );
      return true;
    }

    if (tmdbError != null) throw tmdbError;
    if (tmdbOtherError != null) throw tmdbOtherError;

    await _repository.setSeriesScrapeState(
      oldKey,
      ScrapeState.failed,
      error: '未找到匹配条目',
    );
    return false;
  }

  /// TMDB 不可用或无匹配时，用豆瓣刮削剧集（仅剧集级别信息）。
  Future<bool> _scrapeSeriesFromDouban({
    required String oldKey,
    required String title,
    required int? year,
    required DoubanClient doubanClient,
  }) async {
    if (doubanClient.apiKey.isEmpty) {
      logger.i('豆瓣 API Key 未配置，跳过豆瓣刮削');
      return false;
    }
    try {
      final doubanCandidates = await doubanClient.searchTv(title, year: year);
      logger.i('豆瓣搜索结果：${doubanCandidates.length} 个候选');
      for (final c in doubanCandidates.take(5)) {
        logger.i(
          '  豆瓣候选：id=${c.id} title="${c.title}" original="${c.originalTitle}" year=${c.year} rating=${c.rating}',
        );
      }
      final doubanMatch = DoubanMatcher.best(
        doubanCandidates,
        title: title,
        year: year,
      );
      if (doubanMatch == null) {
        logger.i('豆瓣匹配失败：没有达到阈值的候选');
        return false;
      }
      logger.i(
        '豆瓣匹配成功：id=${doubanMatch.id} title="${doubanMatch.title}" year=${doubanMatch.year}',
      );
      final doubanDetails = await _doubanDetails(doubanClient, doubanMatch);
      await _applyDoubanSeriesMetadata(oldKey, doubanDetails);
      await _repository.setSeriesScrapeState(oldKey, ScrapeState.done);
      logger.i('豆瓣剧集刮削完成：$title');
      return true;
    } catch (e) {
      logger.i('豆瓣异常：$e');
      return false;
    }
  }

  /// 获取豆瓣详情（简介、别名、集数）。
  ///
  /// 详情接口失败时退回搜索结果，不阻断刮削。
  Future<DoubanCandidate> _doubanDetails(
    DoubanClient client,
    DoubanCandidate match,
  ) async {
    try {
      final details = await client.subject(match.id);
      if (details != null) {
        final summaryLength = details.overview?.length ?? 0;
        logger.i(
          '豆瓣详情：id=${details.id} 简介=$summaryLength字 '
          '集数=${details.episodeCount ?? '-'} 别名=${details.aka?.join('/') ?? '-'}',
        );
        // 详情接口偶尔缺少 images，用搜索结果补上海报/背景图。
        return details.mergedWith(match);
      }
      logger.w('豆瓣详情为空，使用搜索结果：id=${match.id}');
    } catch (error) {
      logger.w('豆瓣详情获取失败，使用搜索结果：$error');
    }
    return match;
  }

  /// 将豆瓣电影元数据应用到数据库
  Future<void> _applyDoubanMetadata(
    int mediaId,
    DoubanCandidate details,
  ) async {
    await _repository.applyMetadata(
      mediaId,
      ScrapedMetadata(
        title: details.title,
        year: details.year,
        tmdbId: null,
        imdbId: null,
        overview: details.overview,
        posterPath: details.posterPath,
        backdropPath: details.backdropPath,
        rating: details.rating,
        genres: details.genres ?? [],
        runtime: null,
        releaseDate: null,
        metadataSource: 'douban',
        metadataSourceId: details.id.toString(),
      ),
    );
    await _repository.setScrapeState(mediaId, ScrapeState.done);
  }

  /// 将豆瓣剧集元数据应用到数据库。
  ///
  /// 只写剧集级别信息，分集标题/集数保持扫描时的本地结果。
  Future<void> _applyDoubanSeriesMetadata(
    String seriesKey,
    DoubanCandidate details,
  ) async {
    await _repository.applySeriesMetadata(
      seriesKey,
      ScrapedMetadata(
        seriesKey: seriesKey,
        seriesTitle: details.title,
        year: details.year,
        tmdbId: null,
        imdbId: null,
        overview: details.overview,
        posterPath: details.posterPath,
        backdropPath: details.backdropPath,
        rating: details.rating,
        genres: details.genres ?? [],
        metadataSource: 'douban',
        metadataSourceId: details.id.toString(),
      ),
    );
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
