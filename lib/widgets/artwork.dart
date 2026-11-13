import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/scraper/tmdb_client.dart';

/// 豆瓣图片站有防盗链：不带 Referer 会返回 418。
/// 其他图源（TMDB / 本地 NFO 远程图）不需要额外请求头。
Map<String, String>? imageRequestHeaders(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  if (host == 'doubanio.com' || host.endsWith('.doubanio.com')) {
    return const {
      'Referer': 'https://movie.douban.com/',
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
    };
  }
  return null;
}

final Set<String> _loggedImageRequests = <String>{};
final Set<String> _loggedImageFailures = <String>{};

void _logImageRequest(String url, Map<String, String>? headers) {
  if (!_loggedImageRequests.add(url)) return;
  final headerText = headers == null
      ? '(无额外请求头)'
      : headers.entries.map((e) => '${e.key}: ${e.value}').join(' | ');
  debugPrint('[IMG] GET $url');
  debugPrint('[IMG] headers: $headerText');
}

void _logImageFailure(String url, Object error) {
  if (!_loggedImageFailures.add('$url|$error')) return;
  debugPrint('[IMG] 失败 $url -> $error');
}

/// 豆瓣旧数据里可能还存着 `/view/photo/s_ratio_poster/public/` 缩略图，
/// 显示时统一升级成 `/view/photo/l/public/` 大图，避免必须重刮。
String upgradeDoubanImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.host.endsWith('doubanio.com')) return url;
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
  return url;
}

/// 带自定义请求头下载图片。
///
/// 关键点：必须用 `headers.set` 覆盖 Dart 默认的 `User-Agent`。
/// 豆瓣图站会拦截 `Dart/...` UA；`Image.network` 内部用 `headers.add`，
/// 覆盖不掉默认 UA，所以会一直 418。
Future<Uint8List> _downloadWithHeaders(
  String url,
  Map<String, String> headers,
) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    headers.forEach((name, value) => request.headers.set(name, value));
    request.headers.set(
      HttpHeaders.acceptHeader,
      'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    );
    final response = await request.close();
    debugPrint('[IMG] HTTP ${response.statusCode} $url');
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'statusCode ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    return bytes;
  } finally {
    client.close();
  }
}

/// 需要自定义请求头（豆瓣防盗链）的图片单独下载并缓存字节。
class _HeaderImage extends StatefulWidget {
  const _HeaderImage({
    required this.url,
    required this.headers,
    required this.fit,
    required this.fallback,
  });

  final String url;
  final Map<String, String> headers;
  final BoxFit fit;
  final Widget Function() fallback;

  @override
  State<_HeaderImage> createState() => _HeaderImageState();
}

class _HeaderImageState extends State<_HeaderImage> {
  static final Map<String, Uint8List> _bytesCache = <String, Uint8List>{};

  late Future<Uint8List> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _HeaderImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _future = _load();
    }
  }

  Future<Uint8List> _load() async {
    final cached = _bytesCache[widget.url];
    if (cached != null) return cached;
    final bytes = await _downloadWithHeaders(widget.url, widget.headers);
    _bytesCache[widget.url] = bytes;
    if (_bytesCache.length > 120) {
      _bytesCache.remove(_bytesCache.keys.first);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _logImageFailure(widget.url, snapshot.error!);
          return widget.fallback();
        }
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback();
        return Image.memory(
          bytes,
          fit: widget.fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          errorBuilder: (_, error, _) {
            _logImageFailure(widget.url, '解码失败：$error');
            return widget.fallback();
          },
        );
      },
    );
  }
}

/// 需要自定义请求头（豆瓣防盗链）的图片走自建下载器；
/// 其他图源继续走 CachedNetworkImage，保留磁盘缓存。
Widget _remoteImage({
  required String url,
  required BoxFit fit,
  required Widget Function() fallback,
}) {
  final resolved = upgradeDoubanImageUrl(url);
  final resolvedHeaders = imageRequestHeaders(resolved);
  _logImageRequest(resolved, resolvedHeaders);
  if (resolvedHeaders != null) {
    return _HeaderImage(
      url: resolved,
      headers: resolvedHeaders,
      fit: fit,
      fallback: fallback,
    );
  }
  return CachedNetworkImage(
    imageUrl: resolved,
    fit: fit,
    width: double.infinity,
    height: double.infinity,
    fadeInDuration: const Duration(milliseconds: 260),
    placeholder: (_, _) => fallback(),
    errorWidget: (_, _, error) {
      _logImageFailure(resolved, error);
      return fallback();
    },
  );
}

class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    this.remotePath,
    this.localPath,
    required this.seed,
    this.fit = BoxFit.cover,
    this.size = 'w500',
    this.borderRadius = BorderRadius.zero,
  });

  final String? remotePath;
  final String? localPath;
  final String seed;
  final BoxFit fit;
  final String size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: _build());
  }

  Widget _build() {
    if (localPath != null && localPath!.isNotEmpty) {
      final file = File(localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _fallback(),
        );
      }
    }
    final url = tmdbImageUrl(remotePath, size: size);
    if (url == null) {
      if (_loggedImageFailures.add('skip|$seed')) {
        debugPrint('[IMG] 跳过：remotePath 为空 (seed=$seed)');
      }
      return _fallback();
    }
    return _remoteImage(url: url, fit: fit, fallback: _fallback);
  }

  Widget _fallback() {
    final colors = fallbackGradient(seed)
        .map((value) => Color(value))
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.local_movies_outlined,
              size: 90,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Center(
            child: Text(
              initials(seed),
              style: TextStyle(
                // fontFamily: LumaTheme.displayFont,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.30),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class BackdropImage extends StatelessWidget {
  const BackdropImage({
    super.key,
    this.remotePath,
    this.localPath,
    required this.seed,
    this.fit = BoxFit.cover,
    this.size = 'w1280',
  });

  final String? remotePath;
  final String? localPath;
  final String seed;
  final BoxFit fit;
  final String size;

  @override
  Widget build(BuildContext context) {
    if (localPath != null && localPath!.isNotEmpty) {
      final file = File(localPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) =>
              PosterImage(seed: seed, remotePath: remotePath),
        );
      }
    }
    final url = tmdbImageUrl(remotePath, size: size);
    if (url == null) {
      return PosterImage(seed: seed, fit: fit);
    }
    return _remoteImage(
      url: url,
      fit: fit,
      fallback: () => PosterImage(seed: seed, fit: fit),
    );
  }
}

class PosterSkeleton extends StatelessWidget {
  const PosterSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
    );
  }
}
