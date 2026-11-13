import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/widgets/text.dart';

import '../core/formatters.dart';
import '../data/models.dart';
import 'artwork.dart';

class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.entry,
    this.onTap,
    this.autofocus = false,
    this.width = 176,
    this.showMeta = true,
    this.watchFraction = 0,
  });

  final LibraryEntry entry;
  final VoidCallback? onTap;
  final bool autofocus;
  final double width;
  final bool showMeta;
  final double watchFraction;

  @override
  Widget build(BuildContext context) {
    final posterHeight = width * 1.4;
    return SizedBox(
      width: width + 12,
      child: DpadFocusable(
        autofocus: autofocus,
        onSelect: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: width,
                height: posterHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PosterImage(
                      remotePath: entry.posterPath,
                      localPath: entry.localPoster,
                      seed: entry.title,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _RatingPill(rating: entry.rating),
                    ),
                    if (entry.isSeries)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _Badge(label: '${entry.series!.episodeCount} 集'),
                      ),
                    if (watchFraction > 0.02)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          child: LinearProgressIndicator(
                            value: watchFraction,
                            minHeight: 3.5,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.55,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              const Color(0xFFE9C57E),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (showMeta) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 6),
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  _subtitle(entry),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle(LibraryEntry entry) {
    final parts = <String>[];
    if (entry.year != null) parts.add('${entry.year}');
    if (entry.isSeries) {
      parts.add('剧集');
    } else if (entry.runtime != null) {
      parts.add(formatRuntime(entry.runtime));
    } else if (entry.genres.isNotEmpty) {
      parts.add(entry.genres.first);
    }
    return parts.join(' · ');
  }
}

class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.item,
    this.onTap,
    this.autofocus = false,
    this.width = 306,
  });

  final ContinueItem item;
  final VoidCallback? onTap;
  final bool autofocus;
  final double width;

  @override
  Widget build(BuildContext context) {
    final media = item.media;
    final height = width * 0.5625;
    final label = media.isEpisode
        ? '${media.showName} · ${episodeCode(media.season, media.episode)}'
        : media.title;
    return SizedBox(
      width: width + 12,
      child: DpadFocusable(
        // autofocus: autofocus,
        onSelect: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropImage(
                      remotePath: media.stillPath ?? media.backdropPath,
                      localPath: media.localBackdrop,
                      seed: media.title,
                      size: 'w780',
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x22000000),
                            Color(0xE6000000),
                          ],
                          stops: [0.35, 0.62, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            media.isEpisode
                                ? media.displayTitle
                                : '${formatClock(Duration(milliseconds: item.progress.positionMs))} / ${formatClock(Duration(milliseconds: item.progress.durationMs))}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC9CAD0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: item.progress.fraction,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        valueColor: AlwaysStoppedAnimation(
                          const Color(0xFFE9C57E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodeCard extends StatelessWidget {
  const EpisodeCard({
    super.key,
    required this.media,
    this.onTap,
    this.autofocus = false,
    this.width = 252,
    this.progress,
    this.watched = false,
  });

  final MediaItem media;
  final VoidCallback? onTap;
  final bool autofocus;
  final double width;
  final PlaybackProgress? progress;
  final bool watched;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.5625;
    return SizedBox(
      width: width + 12,
      child: DpadFocusable(
        // autofocus: autofocus,
        onSelect: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropImage(
                      remotePath: media.stillPath ?? media.backdropPath,
                      localPath: media.localBackdrop,
                      seed: media.title,
                      size: media.stillPath != null ? 'w300' : 'w780',
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _Badge(
                        label: episodeCode(media.season, media.episode),
                      ),
                    ),
                    if (watched)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context)
                              .extension<SemanticColors>()
                              ?.success,
                        ),
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Text(
                        media.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (progress != null && progress!.fraction > 0.02)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress!.fraction,
                          minHeight: 3,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(
                            const Color(0xFFE9C57E),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              media.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodeRow extends StatelessWidget {
  const EpisodeRow({
    super.key,
    required this.media,
    required this.index,
    this.onTap,
    this.autofocus = false,
    this.progress,
    this.watched = false,
    this.onMarkWatched,
  });

  final MediaItem media;
  final int index;
  final VoidCallback? onTap;
  final bool autofocus;
  final PlaybackProgress? progress;
  final bool watched;
  final VoidCallback? onMarkWatched;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      // autofocus: autofocus,
      onSelect: onTap,
      onLongSelect: () {
        // 长按切换 -> 标记为 已看完/未看完
        onMarkWatched!.call();
      },
      effects: [DpadGlowEffect(), DpadScaleEffect(scale: 0.98)],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 148,
              height: 83,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    BackdropImage(
                      remotePath: media.stillPath ?? media.backdropPath,
                      localPath: media.localBackdrop,
                      seed: media.title,
                      size: media.stillPath != null ? 'w300' : 'w780',
                    ),
                    if (watched)
                      Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context)
                              .extension<SemanticColors>()
                              ?.success,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        episodeCode(media.season, media.episode).isEmpty
                            ? '第 ${index + 1} 集'
                            : episodeCode(media.season, media.episode),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    media.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (media.runtime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatRuntime(media.runtime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
            if (watched)
              TSubTitle(
                '已看完',
                color: Theme.of(context).extension<SemanticColors>()?.success,
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});
  final double? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null || rating! <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12),
          const SizedBox(width: 3),
          Text(
            formatRating(rating),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}
