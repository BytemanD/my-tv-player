import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/scraper/tmdb_client.dart';

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
    if (url == null) return _fallback();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 260),
      placeholder: (_, _) => _fallback(),
      errorWidget: (_, _, _) => _fallback(),
    );
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
                fontFamily: LumaTheme.displayFont,
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
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (_, _) => PosterImage(seed: seed, fit: fit),
      errorWidget: (_, _, _) => PosterImage(seed: seed, fit: fit),
    );
  }
}

class PosterSkeleton extends StatelessWidget {
  const PosterSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: LumaColors.surfaceHigh);
  }
}
