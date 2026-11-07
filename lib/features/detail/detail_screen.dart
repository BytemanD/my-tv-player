import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/artwork.dart';
import '../../widgets/media_cards.dart';
import '../../widgets/tv_focusable.dart';
import '../player/player_launcher.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.entryKey});
  final String entryKey;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  int? _season;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final entry = controller.entryByKey(widget.entryKey);

    if (entry == null) {
      return Scaffold(
        backgroundColor: LumaColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '找不到这个条目',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              TvButton(
                label: '返回',
                autofocus: true,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final lead = entry.lead;
    final isSeries = entry.isSeries;
    final movie = entry.movie;
    final showProgress = movie?.id == null
        ? null
        : controller.progressMap[movie!.id!];
    final watched = showProgress?.completed ?? false;

    final seasons = isSeries ? entry.series!.seasons : const <int>[];
    final activeSeason = _season ?? (seasons.isNotEmpty ? seasons.first : null);
    final episodes = isSeries
        ? entry.series!.episodes
              .where(
                (e) => activeSeason == null || (e.season ?? 1) == activeSeason,
              )
              .toList()
        : const <MediaItem>[];

    return Scaffold(
      backgroundColor: LumaColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(
                    controller: controller,
                    entry: entry,
                    onPlay: () => _play(context, controller, entry),
                    onToggleWatched: () {
                      if (isSeries) return;
                      if (watched) {
                        controller.markUnwatched(lead);
                      } else {
                        controller.markWatched(lead);
                      }
                    },
                    watched: watched,
                    onScrape: controller.hasTmdbKey
                        ? () => controller.scrapeMedia(lead)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  if (isSeries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 18, 56, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '剧集',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: LumaColors.text,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '共 ${entry.series!.episodeCount} 集',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: LumaColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final season in seasons)
                                TvChip(
                                  label: '第 $season 季',
                                  selected: activeSeason == season,
                                  onTap: () => setState(() => _season = season),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 56),
                      child: Column(
                        children: [
                          for (var i = 0; i < episodes.length; i++)
                            EpisodeRow(
                              media: episodes[i],
                              index: i,
                              autofocus: false,
                              progress: episodes[i].id == null
                                  ? null
                                  : controller.progressMap[episodes[i].id!],
                              watched:
                                  episodes[i].id != null &&
                                  (controller
                                          .progressMap[episodes[i].id!]
                                          ?.completed ??
                                      false),
                              onTap: () => _playEpisode(
                                context,
                                controller,
                                episodes[i],
                              ),
                              onMarkWatched: () =>
                                  _toggleEpisode(controller, episodes[i]),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 22, 56, 0),
                      child: _FileInfo(media: lead),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 28,
            left: 34,
            child: TvIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).pop(),
              tooltip: '返回',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _play(
    BuildContext context,
    AppController controller,
    LibraryEntry entry,
  ) async {
    final media = entry.isSeries
        ? controller.resumeEpisodeForSeries(entry.series!.key)
        : entry.movie;
    if (media != null) await openPlayer(context, controller, media);
  }

  Future<void> _playEpisode(
    BuildContext context,
    AppController controller,
    MediaItem media,
  ) async {
    await openPlayer(
      context,
      controller,
      media,
      queue: controller.queueFor(media),
    );
  }

  Future<void> _toggleEpisode(AppController controller, MediaItem media) async {
    final completed =
        media.id != null &&
        (controller.progressMap[media.id!]?.completed ?? false);
    if (completed) {
      await controller.markUnwatched(media);
    } else {
      await controller.markWatched(media);
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.controller,
    required this.entry,
    required this.onPlay,
    required this.onToggleWatched,
    required this.watched,
    this.onScrape,
  });

  final AppController controller;
  final LibraryEntry entry;
  final VoidCallback onPlay;
  final VoidCallback onToggleWatched;
  final bool watched;
  final VoidCallback? onScrape;

  @override
  Widget build(BuildContext context) {
    final isSeries = entry.isSeries;
    return SizedBox(
      height: 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropImage(
            remotePath: entry.backdropPath,
            localPath: entry.localBackdrop,
            seed: entry.title,
            size: 'w1280',
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x3307080B),
                  Color(0x9907080B),
                  LumaColors.background,
                  LumaColors.background,
                ],
                stops: [0, 0.38, 0.82, 1],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xAA07080B), Colors.transparent],
                stops: [0, 0.55],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 30, 56, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 222,
                  height: 333,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: PosterImage(
                    remotePath: entry.posterPath,
                    localPath: entry.localPoster,
                    seed: entry.title,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.tmdbId != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'TMDB ${entry.tmdbId}',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: LumaColors.textMuted,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          entry.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.04,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (entry.scrapeState == ScrapeState.pending ||
                            entry.scrapeState == ScrapeState.failed)
                          _StatePill(
                            text: entry.scrapeState == ScrapeState.failed
                                ? '同步未完成'
                                : '等待同步',
                            warning: true,
                          ),
                        const SizedBox(height: 14),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            if (entry.rating != null && entry.rating! > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 17,
                                    color: LumaColors.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatRating(entry.rating),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: LumaColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            if (entry.year != null)
                              Text(
                                '${entry.year}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: LumaColors.textDim,
                                ),
                              ),
                            Text(
                              isSeries
                                  ? '${entry.series!.seasons.length} 季 · ${entry.series!.episodeCount} 集'
                                  : formatRuntime(entry.runtime),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: LumaColors.textDim,
                              ),
                            ),
                            if (entry.lead.imdbId != null)
                              Text(
                                entry.lead.imdbId!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LumaColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        if (entry.genres.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final genre in entry.genres.take(4))
                                _StatePill(text: genre, warning: false),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: Text(
                            entry.overview?.isNotEmpty == true
                                ? entry.overview!
                                : '暂无简介。',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.68,
                              color: Color(0xFFB3B5BE),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            TvButton(
                              label: _playLabel(),
                              icon: Icons.play_arrow_rounded,
                              autofocus: true,
                              onTap: onPlay,
                            ),
                            const SizedBox(width: 12),
                            if (!isSeries)
                              TvButton(
                                label: watched ? '标记未看' : '标记已看',
                                icon: watched
                                    ? Icons.replay_rounded
                                    : Icons.check_rounded,
                                style: TvButtonStyle.outline,
                                onTap: onToggleWatched,
                              ),
                            if (onScrape != null) ...[
                              const SizedBox(width: 12),
                              TvButton(
                                label: '重新刮削',
                                icon: Icons.auto_awesome_rounded,
                                style: TvButtonStyle.ghost,
                                onTap: onScrape,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _playLabel() {
    if (entry.isSeries) {
      final episode = controller.resumeEpisodeForSeries(entry.series!.key);
      final progress = episode?.id == null
          ? null
          : controller.progressMap[episode!.id!];
      if (progress != null &&
          progress.fraction > 0.02 &&
          progress.fraction < 0.96 &&
          !progress.completed) {
        return '继续观看';
      }
      return '开始播放';
    }
    final progress = entry.movie?.id == null
        ? null
        : controller.progressMap[entry.movie!.id!];
    if (progress != null &&
        progress.fraction > 0.02 &&
        progress.fraction < 0.96 &&
        !progress.completed) {
      return '继续观看';
    }
    return '立即播放';
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.text, required this.warning});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: warning
            ? LumaColors.accentSoft
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: warning
              ? LumaColors.accentDeep
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: warning ? LumaColors.accent : LumaColors.textDim,
        ),
      ),
    );
  }
}

class _FileInfo extends StatelessWidget {
  const _FileInfo({required this.media});
  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LumaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LumaColors.lineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '媒体信息',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: LumaColors.textOnSurface,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(label: '文件', value: media.fileName),
          _InfoRow(label: '大小', value: formatFileSize(media.size)),
          if (media.runtime != null && media.runtime! > 0)
            _InfoRow(label: '时长', value: formatRuntime(media.runtime)),
          _InfoRow(label: '路径', value: media.path),
          if (media.nfoPath != null)
            _InfoRow(label: 'NFO', value: media.nfoPath!),
          if (media.scrapeError != null)
            _InfoRow(label: '刮削', value: media.scrapeError!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: LumaColors.textMutedOnSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: LumaColors.textDimOnSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
