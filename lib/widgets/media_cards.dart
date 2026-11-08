import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/models.dart';
import 'artwork.dart';
import 'tv_focusable.dart';

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
    final posterHeight = width * 1.5;
    return SizedBox(
      width: width + 12,
      child: TvFocusable(
        autofocus: autofocus,
        onTap: onTap,
        scale: 1.055,
        builder: (context, focused) {
          final radius = BorderRadius.circular(14);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: focused
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    width: focused ? 2.6 : 2,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: LumaColors.primary.withValues(alpha: 0.14),
                            blurRadius: 34,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
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
                        borderRadius: radius,
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
                          child: _Badge(
                            label: '${entry.series!.episodeCount} 集',
                          ),
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
                                LumaColors.primary,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: focused ? 1 : 0,
                            duration: const Duration(milliseconds: 160),
                            child: Center(
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: LumaColors.primary.withValues(
                                    alpha: 0.94,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF221A0B),
                                  size: 32,
                                ),
                              ),
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
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: focused ? LumaColors.primary : LumaColors.text,
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
                    style: TextStyle(fontSize: 12, color: LumaColors.textMuted),
                  ),
                ),
              ],
            ],
          );
        },
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
      child: TvFocusable(
        autofocus: autofocus,
        onTap: onTap,
        scale: 1.04,
        builder: (context, focused) {
          final radius = BorderRadius.circular(14);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: focused
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    width: focused ? 2.6 : 2,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 1,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: LumaColors.primary.withValues(alpha: 0.14),
                            blurRadius: 34,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
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
                          valueColor: AlwaysStoppedAnimation(LumaColors.accent),
                        ),
                      ),
                      if (focused) const Center(child: _PlayBadge()),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
      child: TvFocusable(
        autofocus: autofocus,
        onTap: onTap,
        scale: 1.045,
        builder: (context, focused) {
          final radius = BorderRadius.circular(12);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: focused ? LumaColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BackdropImage(
                        remotePath: media.stillPath ?? media.backdropPath,
                        localPath: media.localBackdrop,
                        seed: media.title,
                        size: media.stillPath != null ? 'w300' : 'w780',
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: watched ? 0.55 : 0,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC000000)],
                            stops: [0.45, 1],
                          ),
                        ),
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
                            color: LumaColors.primary,
                            size: 20,
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
                              LumaColors.accent,
                            ),
                          ),
                        ),
                      if (focused) const Center(child: _PlayBadge(size: 42)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                media.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: focused ? LumaColors.primary : LumaColors.textDim,
                ),
              ),
            ],
          );
        },
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
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      scale: 1.008,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: focused ? LumaColors.surfaceHigh : LumaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: focused ? LumaColors.primary : LumaColors.lineSoft,
            ),
          ),
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
                      Container(
                        color: Colors.black.withValues(
                          alpha: watched ? 0.5 : 0,
                        ),
                      ),
                      if (focused)
                        const Center(child: _PlayBadge(size: 38))
                      else if (watched)
                        Center(
                          child: Icon(
                            Icons.check_circle,
                            color: LumaColors.primary,
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
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: LumaColors.primary,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (watched)
                          Text(
                            '已看完',
                            style: TextStyle(
                              fontSize: 11,
                              color: LumaColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      media.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: LumaColors.text,
                      ),
                    ),
                    if (media.runtime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        formatRuntime(media.runtime),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: LumaColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onMarkWatched != null) ...[
                const SizedBox(width: 12),
                TvIconButton(
                  icon: watched ? Icons.replay_rounded : Icons.check_rounded,
                  tooltip: watched ? '标记未看' : '标记已看',
                  onTap: onMarkWatched,
                  size: 38,
                  iconSize: 18,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: LumaColors.primary.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16),
        ],
      ),
      child: Icon(
        Icons.play_arrow_rounded,
        color: LumaColors.onPrimary,
        size: size * 0.6,
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
          Icon(Icons.star_rounded, size: 12, color: LumaColors.accent),
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
