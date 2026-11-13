import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
// import 'package:luma_tv/core/theme.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/selector.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/common/utils.dart';
import '../../data/models.dart';
import '../../widgets/artwork.dart';
import '../../widgets/media_cards.dart';
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '找不到这个条目',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              DpadFocusable(
                // autofocus: true,
                onSelect: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C22),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    '返回',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: DpadRegion(
              memoryKey: 'detail/${widget.entryKey}',
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
                            TSpace([
                              const TH2('剧集'),
                              TDivider(),
                              TSubTitle('共 ${entry.series!.episodeCount} 集'),
                            ]),
                            TDivider(),
                            TSelect(
                              seasons.map((x) => '第 $x 季').toList(),
                              onChanged: (index) => {
                                setState(() => _season = seasons[index]),
                              },
                            ),
                          ],
                        ),
                      ),
                      TDivider(),
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
          ),
          Positioned(
            top: 28,
            left: 34,
            child: TButton(
              onClick: () => Navigator.of(context).pop(),
              icon: Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.5),
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
                  const Color(0xFF0B0C10).withValues(alpha: 0.2),
                  const Color(0xFF0B0C10).withValues(alpha: 0.6),
                  const Color(0xFF0B0C10),
                  const Color(0xFF0B0C10),
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
                colors: [Color(0xAA0B0C10), Colors.transparent],
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
                            child: TSubTitle('TMDB ${entry.tmdbId}'),
                          ),
                        const TDivider(),
                        TH0(entry.title, color: Colors.white),
                        const TDivider(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            if (entry.rating != null && entry.rating! > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 17,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  TSubTitle(
                                    formatRating(entry.rating),
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            TSubTitle(
                              '${entry.year ?? "-"}',
                              color: Colors.white,
                            ),
                            TSubTitle(
                              isSeries
                                  ? '${entry.series!.seasons.length} 季 · ${entry.series!.episodeCount} 集'
                                  : formatRuntime(entry.runtime),
                              color: Colors.white,
                            ),
                            if (entry.lead.imdbId != null)
                              TSubTitle(
                                entry.lead.imdbId!,
                                color: Colors.white,
                              ),
                          ],
                        ),
                        if (entry.genres.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TSubTitle(
                            entry.genres.take(2).join(' / '),
                            color: Colors.white,
                          ),
                        ],
                        const SizedBox(height: 16),
                        TText(
                          entry.overview?.isNotEmpty == true
                              ? entry.overview!
                              : '暂无简介。',
                          maxLines: 4,
                          maxWidth: 860,
                          color: Colors.white,
                        ),
                        const TDivider(height: 22),
                        TSpace([
                          TButton(
                            autofocus: true,
                            label: _playLabel(),
                            icon: Icons.play_arrow_rounded,
                            onClick: onPlay,
                            color: Theme.of(context).colorScheme.primary
                                .withValues(alpha: 0.5),
                          ),
                          if (onScrape != null)
                            TButton(
                              icon: Icons.auto_awesome_rounded,
                              label: "重新刮削",
                              onClick: onScrape,
                              color: Theme.of(context).colorScheme.secondary
                                  .withValues(alpha: 0.5),
                            ),
                          if (!isSeries)
                            TButton(
                              label: watched ? '标记未看' : '标记已看',
                              icon: watched
                                  ? Icons.replay_rounded
                                  : Icons.check_rounded,
                              onClick: onToggleWatched,
                              color: Theme.of(context).colorScheme.secondary
                                  .withValues(alpha: 0.5),
                            ),
                          if (entry.scrapeState == ScrapeState.pending ||
                              entry.scrapeState == ScrapeState.failed)
                            TSubTitle(
                              entry.scrapeState == ScrapeState.failed
                                  ? '同步未完成'
                                  : '等待同步',
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          const TDivider(height: 8),
                        ], space: 10),
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

class _FileInfo extends StatelessWidget {
  const _FileInfo({required this.media});
  final MediaItem media;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '媒体信息',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
