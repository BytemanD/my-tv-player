import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbException implements Exception {
  const TmdbException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TmdbCandidate {
  const TmdbCandidate({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.year,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.popularity = 0,
  });

  final int id;
  final String title;
  final String originalTitle;
  final int? year;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final double popularity;
}

class TmdbTitle {
  const TmdbTitle({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.year,
    this.overview,
    this.posterPath,
    this.backdropPath,
    this.rating,
    this.runtime,
    this.genres = const [],
    this.imdbId,
    this.releaseDate,
    this.seasonCount,
  });

  final int id;
  final String title;
  final String originalTitle;
  final int? year;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double? rating;
  final int? runtime;
  final List<String> genres;
  final String? imdbId;
  final String? releaseDate;
  final int? seasonCount;
}

class TmdbEpisode {
  const TmdbEpisode({
    required this.season,
    required this.episode,
    required this.name,
    this.overview,
    this.stillPath,
    this.airDate,
    this.runtime,
    this.rating,
  });

  final int season;
  final int episode;
  final String name;
  final String? overview;
  final String? stillPath;
  final String? airDate;
  final int? runtime;
  final double? rating;
}

class TmdbClient {
  TmdbClient({
    required this.apiKey,
    this.language = 'zh-CN',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String language;
  final http.Client _client;

  // api.tmdb.org 是 TMDB 官方提供的镜像域名，部分网络下
  // api.themoviedb.org 无法访问时仍然可用；失败时自动回退。
  static const _hosts = ['api.tmdb.org', 'api.themoviedb.org'];
  static const _basePath = '/3';
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  bool get _isBearer => apiKey.startsWith('eyJ');

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(milliseconds: 60)) {
      await Future<void>.delayed(const Duration(milliseconds: 60) - elapsed);
    }

    http.Response? response;
    Object? lastError;

    for (final host in _hosts) {
      final uri = Uri.https(host, '$_basePath$path', {
        ...query,
        'language': language,
        if (!_isBearer) 'api_key': apiKey,
      });
      response = null;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          _lastRequest = DateTime.now();
          response = await _client
              .get(
                uri,
                headers: {
                  'Accept': 'application/json',
                  if (_isBearer) 'Authorization': 'Bearer $apiKey',
                },
              )
              .timeout(const Duration(seconds: 18));
          if (response.statusCode == 429) {
            final retryAfter =
                int.tryParse(response.headers['retry-after'] ?? '') ?? 2;
            await Future<void>.delayed(
              Duration(seconds: retryAfter.clamp(1, 10)),
            );
            continue;
          }
          if (response.statusCode >= 500 && attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            continue;
          }
          break;
        } catch (error) {
          lastError = error;
          if (attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            continue;
          }
        }
      }
      // 只有网络失败、限流或 5xx 才换下一个域名；
      // 401/404 等业务错误直接交给上层处理。
      if (response != null &&
          response.statusCode != 429 &&
          response.statusCode < 500) {
        break;
      }
    }

    if (response == null) {
      throw TmdbException('无法连接 TMDB，请检查网络（$lastError）');
    }
    if (response.statusCode == 401) {
      throw const TmdbException('TMDB API Key 无效，请在设置中重新填写', statusCode: 401);
    }
    if (response.statusCode != 200) {
      throw TmdbException(
        'TMDB 请求失败（HTTP ${response.statusCode}）',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const TmdbException('TMDB 返回了无法解析的数据');
    } on FormatException {
      throw const TmdbException('TMDB 返回了无法解析的数据');
    }
  }

  Future<void> ping() async {
    await _get('/configuration');
  }

  Future<List<TmdbCandidate>> searchMovie(String title, {int? year}) async {
    final json = await _get('/search/movie', {
      'query': title,
      'include_adult': 'false',
      if (year != null) 'year': '$year',
    });
    return _candidates(json, isTv: false);
  }

  Future<List<TmdbCandidate>> searchTv(String title, {int? year}) async {
    final json = await _get('/search/tv', {
      'query': title,
      'include_adult': 'false',
      if (year != null) 'first_air_date_year': '$year',
    });
    return _candidates(json, isTv: true);
  }

  List<TmdbCandidate> _candidates(
    Map<String, dynamic> json, {
    required bool isTv,
  }) {
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final date =
              (isTv ? item['first_air_date'] : item['release_date']) as String?;
          return TmdbCandidate(
            id: (item['id'] as num?)?.toInt() ?? 0,
            title: (isTv ? item['name'] : item['title']) as String? ?? '',
            originalTitle:
                (isTv ? item['original_name'] : item['original_title'])
                    as String? ??
                '',
            year: int.tryParse((date ?? '').split('-').first),
            posterPath: item['poster_path'] as String?,
            backdropPath: item['backdrop_path'] as String?,
            overview: item['overview'] as String?,
            popularity: (item['popularity'] as num?)?.toDouble() ?? 0,
          );
        })
        .where((c) => c.id > 0 && c.title.isNotEmpty)
        .toList();
  }

  Future<TmdbTitle> movieDetails(int id) async {
    final json = await _get('/movie/$id', {
      'append_to_response': 'external_ids',
    });
    return TmdbTitle(
      id: id,
      title: json['title'] as String? ?? '',
      originalTitle: json['original_title'] as String? ?? '',
      year: int.tryParse(
        (json['release_date'] as String? ?? '').split('-').first,
      ),
      overview: _nonEmpty(json['overview'] as String?),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble(),
      runtime: (json['runtime'] as num?)?.toInt(),
      genres: _genres(json),
      imdbId:
          (json['external_ids'] as Map<String, dynamic>?)?['imdb_id']
              as String?,
      releaseDate: json['release_date'] as String?,
    );
  }

  Future<TmdbTitle> tvDetails(int id) async {
    final json = await _get('/tv/$id', {'append_to_response': 'external_ids'});
    final episodeRuntimes = json['episode_run_time'];
    int? runtime;
    if (episodeRuntimes is List && episodeRuntimes.isNotEmpty) {
      runtime = (episodeRuntimes.first as num?)?.toInt();
    }
    return TmdbTitle(
      id: id,
      title: json['name'] as String? ?? '',
      originalTitle: json['original_name'] as String? ?? '',
      year: int.tryParse(
        (json['first_air_date'] as String? ?? '').split('-').first,
      ),
      overview: _nonEmpty(json['overview'] as String?),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble(),
      runtime: runtime,
      genres: _genres(json),
      imdbId:
          (json['external_ids'] as Map<String, dynamic>?)?['imdb_id']
              as String?,
      releaseDate: json['first_air_date'] as String?,
      seasonCount: (json['number_of_seasons'] as num?)?.toInt(),
    );
  }

  Future<List<TmdbEpisode>> seasonEpisodes(int tvId, int seasonNumber) async {
    final json = await _get('/tv/$tvId/season/$seasonNumber');
    final episodes = json['episodes'];
    if (episodes is! List) return const [];
    return episodes.whereType<Map<String, dynamic>>().map((item) {
      return TmdbEpisode(
        season: (item['season_number'] as num?)?.toInt() ?? seasonNumber,
        episode: (item['episode_number'] as num?)?.toInt() ?? 0,
        name: item['name'] as String? ?? '',
        overview: _nonEmpty(item['overview'] as String?),
        stillPath: item['still_path'] as String?,
        airDate: item['air_date'] as String?,
        runtime: (item['runtime'] as num?)?.toInt(),
        rating: (item['vote_average'] as num?)?.toDouble(),
      );
    }).toList();
  }

  List<String> _genres(Map<String, dynamic> json) {
    final genres = json['genres'];
    if (genres is! List) return const [];
    return genres
        .whereType<Map<String, dynamic>>()
        .map((g) => g['name'] as String?)
        .whereType<String>()
        .where((g) => g.isNotEmpty)
        .toList();
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  void dispose() => _client.close();
}

class TmdbMatcher {
  static TmdbCandidate? best(
    List<TmdbCandidate> candidates, {
    required String title,
    int? year,
  }) {
    if (candidates.isEmpty) return null;
    final wanted = _normalize(title);
    TmdbCandidate? best;
    var bestScore = 0.0;

    for (final candidate in candidates) {
      final names = {
        _normalize(candidate.title),
        _normalize(candidate.originalTitle),
      }..removeWhere((n) => n.isEmpty);
      if (names.isEmpty) continue;

      var score = 0.0;
      for (final name in names) {
        if (name == wanted) {
          score = 1.0;
          break;
        }
        if (name.contains(wanted) || wanted.contains(name)) {
          score = score < 0.72 ? 0.72 : score;
        }
        score = score < _tokenScore(wanted, name)
            ? _tokenScore(wanted, name)
            : score;
      }

      if (year != null && candidate.year != null) {
        final diff = (year - candidate.year!).abs();
        if (diff == 0) {
          score += 0.15;
        } else if (diff == 1) {
          score += 0.06;
        } else if (diff > 3) {
          score -= 0.2;
        }
      }
      score += (candidate.popularity / 5000).clamp(0.0, 0.05);

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    if (best == null) return null;
    return bestScore >= 0.62 ? best : null;
  }

  static double _tokenScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final aTokens = _tokens(a);
    final bTokens = _tokens(b);
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    final intersection = aTokens.intersection(bTokens).length;
    final union = aTokens.union(bTokens).length;
    return union == 0 ? 0 : (intersection / union) * 0.75;
  }

  static Set<String> _tokens(String value) => value
      .split(RegExp(r'[^0-9a-z\u4e00-\u9fff]+'))
      .where((t) => t.isNotEmpty)
      .toSet();

  static String _normalize(String value) {
    var lower = value.toLowerCase().trim();
    lower = lower.replaceFirst(RegExp(r'^(the|a|an)\s+'), '');
    return lower.replaceAll(RegExp(r'[^0-9a-z\u4e00-\u9fff]+'), '').trim();
  }
}

String? tmdbImageUrl(String? path, {String size = 'w500'}) {
  if (path == null || path.trim().isEmpty) return null;
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return 'https://image.tmdb.org/t/p/$size$trimmed';
}
