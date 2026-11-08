import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 豆瓣电影 API v2 客户端
///
/// 用于在 TMDB 找不到影片时作为备用刮削源。
class DoubanClient {
  DoubanClient({required this.apiKey, http.Client? client})
    : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _host = 'api.douban.com';
  static const _basePath = '/v2';

  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, dynamic>> _post(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final elapsed = DateTime.now().difference(_lastRequest);
    if (elapsed < const Duration(milliseconds: 60)) {
      await Future<void>.delayed(const Duration(milliseconds: 60) - elapsed);
    }

    final uri = Uri.https(_host, '$_basePath$path', {
      ...query,
      'apikey': apiKey,
    });

    http.Response? response;
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        _lastRequest = DateTime.now();
        response = await _client
            .post(
              uri,
              body: {'apikey': apiKey},
              headers: {'Accept': 'application/json', 'apikey': apiKey},
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

    if (response == null) {
      throw DoubanException('无法连接豆瓣，请检查网络（$lastError）');
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw DoubanException('豆瓣 API Key 无效', statusCode: response.statusCode);
    }
    if (response.statusCode != 200) {
      throw DoubanException(
        '豆瓣请求失败（HTTP ${response.body}）',
        statusCode: response.statusCode,
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const DoubanException('豆瓣返回了无法解析的数据');
    } on FormatException {
      throw const DoubanException('豆瓣返回了无法解析的数据');
    }
  }

  Future<void> ping() async {
    await _post('/movie/search', {'q': 'test'});
  }

  /// 搜索电影（默认排除剧集条目）
  Future<List<DoubanCandidate>> searchMovie(String title, {int? year}) async {
    final candidates = await _search(title, year: year);
    return candidates.where((c) => c.subtype != 'tv').toList();
  }

  /// 搜索剧集
  Future<List<DoubanCandidate>> searchTv(String title, {int? year}) async {
    final candidates = await _search(title, year: year);
    return candidates.where((c) => c.subtype == 'tv').toList();
  }

  Future<List<DoubanCandidate>> _search(String title, {int? year}) async {
    final json = await _post('/movie/search', {
      'q': title,
      if (year != null) 'year': '$year',
    });
    return parseCandidates(json);
  }

  /// 获取条目详情。
  ///
  /// 搜索接口不返回 `summary`（简介）、`aka`（别名）、`episodes_count`，
  /// 需要再请求一次 `/movie/subject/{id}`。
  Future<DoubanCandidate?> subject(int id) async {
    final json = await _post('/movie/subject/$id');
    return parseSubject(json);
  }

  /// 解析搜索结果。
  ///
  /// 豆瓣返回的 `id`、`year` 等字段类型并不稳定（有时是字符串，有时是数字），
  /// 这里统一做宽松转换，避免 `String` 转 `num` 的运行时崩溃。
  static List<DoubanCandidate> parseCandidates(Map<String, dynamic> json) {
    final subjects = json['subjects'];
    if (subjects is! List) return const [];
    return subjects
        .whereType<Map>()
        .map(_fromItem)
        .where((c) => c.id > 0 && c.title.isNotEmpty)
        .toList();
  }

  /// 解析 `/movie/subject/{id}` 的返回。
  static DoubanCandidate? parseSubject(Map<String, dynamic> json) {
    if (json['id'] == null) return null;
    final item = _fromItem(json);
    return item.id > 0 && item.title.isNotEmpty ? item : null;
  }

  static DoubanCandidate _fromItem(Map raw) {
    final item = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(raw);
    final rating = item['rating'] is Map
        ? Map<String, dynamic>.from(item['rating'] as Map)
        : const <String, dynamic>{};
    final images = item['images'] is Map
        ? Map<String, dynamic>.from(item['images'] as Map)
        : const <String, dynamic>{};
    final casts = item['casts'] is List ? item['casts'] as List : const [];
    final directors = item['directors'] is List
        ? item['directors'] as List
        : const [];
    return DoubanCandidate(
      id: _asInt(item['id']),
      title: _asText(item['title']),
      originalTitle: _asText(item['original_title']),
      subtype: _asText(item['subtype']),
      year: _asYear(item['year']),
      rating: _asDouble(rating['average']),
      posterPath: _imageUrl(images['medium']),
      backdropPath: _imageUrl(images['large']),
      overview: _asNullableText(item['summary']),
      genres: _names(item['genres']),
      casts: casts
          .whereType<Map>()
          .map((c) => _asText(c['name']))
          .where((n) => n.isNotEmpty)
          .toList(),
      directors: directors
          .whereType<Map>()
          .map((d) => _asText(d['name']))
          .where((n) => n.isNotEmpty)
          .toList(),
      episodeCount: _asNullableInt(item['episodes_count']),
      aka: _names(item['aka']),
      alt: _asNullableText(item['alt']),
    );
  }

  static String _asText(Object? value) => value == null ? '' : '$value'.trim();

  static String? _asNullableText(Object? value) {
    final text = _asText(value);
    return text.isEmpty ? null : text;
  }

  /// 豆瓣图片地址处理：
  /// 1. 偶有 http:// 形式，Android 默认禁止明文请求，统一升级为 https；
  /// 2. 搜索接口返回的多是 `/view/photo/s_ratio_poster/public/pXXX.jpg`
  ///    这种低分辨率缩略图，改成 `/view/photo/l/public/pXXX.jpg` 大图。
  static String? _imageUrl(Object? value) {
    var text = _asNullableText(value);
    if (text == null) return null;
    if (text.startsWith('http://') && text.contains('doubanio.com')) {
      text = text.replaceFirst('http://', 'https://');
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.host.endsWith('doubanio.com')) return text;
    final segments = uri.pathSegments.toList();
    final view = segments.indexOf('view');
    if (view >= 0 &&
        segments.length > view + 4 &&
        segments[view + 1] == 'photo' &&
        segments[view + 3] == 'public' &&
        segments[view + 2] != 'l') {
      segments[view + 2] = 'l';
      return uri.replace(pathSegments: segments).toString();
    }
    return text;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_asText(value)) ?? 0;
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(_asText(value));
  }

  static int? _asYear(Object? value) {
    final text = _asText(value);
    if (text.isEmpty) return null;
    final first = text.split('-').first;
    return int.tryParse(first);
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_asText(value));
  }

  static List<String>? _names(Object? value) {
    if (value is! List) return null;
    final names = value.map(_asText).where((name) => name.isNotEmpty).toList();
    return names.isEmpty ? null : names;
  }

  void dispose() => _client.close();
}

class DoubanException implements Exception {
  const DoubanException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class DoubanCandidate {
  const DoubanCandidate({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.subtype = '',
    this.year,
    this.rating,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.genres,
    this.casts,
    this.directors,
    this.episodeCount,
    this.aka,
    this.alt,
  });

  final int id;
  final String title;
  final String originalTitle;

  /// 豆瓣条目类型：`movie` / `tv`。
  final String subtype;
  final int? year;
  final double? rating;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final List<String>? genres;
  final List<String>? casts;
  final List<String>? directors;

  /// 剧集总集数（详情接口返回，电影为 null）。
  final int? episodeCount;

  /// 别名列表（详情接口返回）。
  final List<String>? aka;
  final String? alt;

  /// 详情接口可能缺少搜索接口已有的字段（例如海报），
  /// 用另一条候选补全，已有值优先。
  DoubanCandidate mergedWith(DoubanCandidate other) {
    return DoubanCandidate(
      id: id,
      title: title,
      originalTitle: originalTitle,
      subtype: subtype,
      year: year ?? other.year,
      rating: rating ?? other.rating,
      posterPath: posterPath ?? other.posterPath,
      backdropPath: backdropPath ?? other.backdropPath,
      overview: overview ?? other.overview,
      genres: genres ?? other.genres,
      casts: casts ?? other.casts,
      directors: directors ?? other.directors,
      episodeCount: episodeCount ?? other.episodeCount,
      aka: aka ?? other.aka,
      alt: alt ?? other.alt,
    );
  }
}

/// 豆瓣匹配器，复用 TMDB 匹配逻辑
class DoubanMatcher {
  static DoubanCandidate? best(
    List<DoubanCandidate> candidates, {
    required String title,
    int? year,
  }) {
    if (candidates.isEmpty) return null;
    final wanted = _normalize(title);
    DoubanCandidate? best;
    var bestScore = 0.0;

    for (var index = 0; index < candidates.length; index++) {
      final candidate = candidates[index];
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
      score += (candidate.rating ?? 0).clamp(0.0, 10) / 200;

      // 豆瓣搜索本身按相关度排序，靠前的结果更可信，给予少量加权。
      score += (candidates.length - index) / (candidates.length * 8);

      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    if (best != null && bestScore >= 0.62) return best;

    // 中英文标题差异很大时（如 "If Wishes Could Kill" 对应 "夺命许愿"），
    // 标题相似度为 0，但豆瓣的搜索排序仍然可靠，此时按以下规则兜底：
    // 1. 只有一个结果，直接采用；
    // 2. 有年份时，优先取年份相同（±1）的结果；
    // 3. 第一条结果年份吻合时采用第一条。
    if (candidates.length == 1) return candidates.first;
    if (year != null) {
      for (final candidate in candidates) {
        final candidateYear = candidate.year;
        if (candidateYear != null && (candidateYear - year).abs() <= 1) {
          return candidate;
        }
      }
    }
    // 拉丁文片名（如英文名）常常对应中文/日文/韩文豆瓣标题，
    // 文本相似度天然为 0，这时直接相信豆瓣的相关度排序。
    if (!_hasCjk(wanted)) return candidates.first;
    return null;
  }

  static bool _hasCjk(String value) =>
      RegExp(r'[\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]').hasMatch(value);

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
