import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/common/utils.dart';
import '../../data/models.dart';
import '../../widgets/button.dart';
import '../../widgets/artwork.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shelf.dart';
import '../../widgets/tv_focusable.dart';
import '../detail/detail_screen.dart';
import '../player/player_launcher.dart';
import '../sources/add_source_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();

    if (controller.sources.isEmpty || controller.entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(34, 26, 56, 30),
        child: EmptyLibrary(
          hasSources: controller.sources.isNotEmpty,
          hasAccess: controller.hasStorageAccess,
          onGrantAccess: controller.requestStorageAccess,
          onAddFolder: () => showAddSourceDialog(context, controller),
          onScan: controller.sources.isEmpty
              ? () => showAddSourceDialog(context, controller)
              : controller.scanAll,
          title: controller.sources.isEmpty ? null : '还没有发现视频',
        ),
      );
    }

    final heroEntries = controller.heroEntries;
    final recent = controller.recentEntries.take(14).toList();
    final movies = controller.movieEntries.take(14).toList();
    final series = controller.seriesEntries.take(14).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 26, 56, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!controller.hasStorageAccess) ...[
            _AccessBanner(controller: controller),
            const SizedBox(height: 18),
          ],
          if (heroEntries.isNotEmpty)
            _HeroCarousel(
              controller: controller,
              entries: heroEntries,
              onPlay: (entry) {
                _playFeatured(context, controller, entry);
              },
              onDetails: (entry) => _openDetails(context, entry),
            ),
          if (controller.scanning || controller.scraping) ...[
            const SizedBox(height: 20),
            _ActivityCard(controller: controller),
          ],
          const SizedBox(height: 30),
          if (controller.continueWatching.isNotEmpty) ...[
            MediaShelf(
              title: '继续观看',
              entries: const [],
              continueItems: controller.continueWatching,
              onOpen: (_) {},
              onOpenContinue: (item) =>
                  openPlayer(context, controller, item.media),
            ),
            const SizedBox(height: 24),
          ],
          MediaShelf(
            title: '最近添加',
            entries: recent,
            autofocusFirst: heroEntries.isEmpty,
            onOpen: (entry) => _openDetails(context, entry),
            onSeeAll: () => _openLibrary(context, 3),
          ),
          const SizedBox(height: 12),
          if (movies.isNotEmpty) ...[
            MediaShelf(
              title: '电影',
              entries: movies,
              onOpen: (entry) => _openDetails(context, entry),
              onSeeAll: () => _openLibrary(context, 1),
            ),
            const SizedBox(height: 24),
          ],
          if (series.isNotEmpty) ...[
            MediaShelf(
              title: '剧集',
              entries: series,
              onOpen: (entry) => _openDetails(context, entry),
              onSeeAll: () => {_openLibrary(context, 2)},
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _playFeatured(
    BuildContext context,
    AppController controller,
    LibraryEntry entry,
  ) async {
    final media = entry.isSeries
        ? controller.resumeEpisodeForSeries(entry.series!.key)
        : entry.movie;
    if (media != null) {
      await openPlayer(context, controller, media);
    }
  }

  void _openDetails(BuildContext context, LibraryEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(entryKey: entry.key),
      ),
    );
  }

  void _openLibrary(BuildContext context, int tab) {
    HomeNavigation.of(context).goToTab(tab);
  }
}

class HomeNavigation extends InheritedWidget {
  const HomeNavigation({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final void Function(int tab) goToTab;

  static HomeNavigation of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<HomeNavigation>();
    assert(result != null, 'HomeNavigation is missing');
    return result!;
  }

  @override
  bool updateShouldNotify(HomeNavigation oldWidget) => false;
}

class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({
    required this.controller,
    required this.entries,
    required this.onPlay,
    required this.onDetails,
  });

  final AppController controller;
  final List<LibraryEntry> entries;
  final ValueChanged<LibraryEntry> onPlay;
  final ValueChanged<LibraryEntry> onDetails;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  static const _interval = Duration(seconds: 9);

  Timer? _timer;
  int _index = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant _HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.entries.length) _index = 0;
    if (oldWidget.entries.length != widget.entries.length) {
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (_paused || widget.entries.length <= 1) return;
    _timer = Timer.periodic(_interval, (_) => _next());
  }

  void _next([int delta = 1]) {
    final length = widget.entries.length;
    if (length <= 1) return;
    setState(() => _index = (_index + delta + length) % length);
    _restartTimer();
  }

  void _goTo(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    _restartTimer();
  }

  LibraryEntry get _current =>
      widget.entries[_index.clamp(0, widget.entries.length - 1)];

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final continuing = current.isSeries
        ? widget.controller.resumeEpisodeForSeries(current.series!.key)
        : current.movie;
    final isContinue =
        continuing != null &&
        (current.isSeries
            ? (widget.controller.progressMap[continuing.id]?.fraction ?? 0) >
                  0.02
            : (widget.controller.progressMap[continuing.id]?.fraction ?? 0) >
                  0.02);

    return MouseRegion(
      onEnter: (_) {
        _paused = true;
        _timer?.cancel();
      },
      onExit: (_) {
        _paused = false;
        _restartTimer();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 414,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                switchInCurve: Curves.easeInOut,
                child: BackdropImage(
                  key: ValueKey<String>(current.key),
                  remotePath: current.backdropPath,
                  localPath: current.localBackdrop,
                  seed: current.title,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [Colors.black87, Colors.transparent],
                    stops: const [0, 0.1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.35, 0.72, 1],
                  ),
                ),
              ),
              if (widget.entries.length > 1) ...[
                Positioned(
                  left: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TButton(
                      icon: Icons.chevron_left_rounded,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.5),
                      size: 40,
                      onClick: () => _next(-1),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TButton(
                      icon: Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.primary
                          .withValues(alpha: 0.5),
                      size: 40,
                      onClick: () => _next(),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(46, 38, 46, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: TH0(current.title, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (current.rating != null && current.rating! > 0) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 17,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 5),
                          TSubTitle(
                            formatRating(current.rating),
                            color: Colors.white,
                          ),
                          const _Dot(),
                        ],
                        if (current.year != null) ...[
                          TSubTitle('${current.year}', color: Colors.white),
                          const _Dot(),
                        ],
                        TSubTitle(
                          current.isSeries
                              ? '${current.series!.seasons.length} 季 · ${current.series!.episodeCount} 集'
                              : formatRuntime(current.runtime),
                          color: Colors.white,
                        ),
                        if (current.genres.isNotEmpty) ...[
                          const _Dot(),
                          TSubTitle(
                            current.genres.take(2).join(' / '),
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (current.overview != null)
                      TText(
                        current.overview ?? "暂无简介",
                        color: Colors.white,
                        maxLines: 3,
                        maxWidth: 780,
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TButton(
                          label: isContinue ? '继续观看' : '立即播放',
                          icon: Icons.play_arrow_rounded,
                          onClick: () => widget.onPlay(current),
                        ),
                        const SizedBox(width: 12),
                        TvButton(
                          label: '详情',
                          icon: Icons.info_outline_rounded,
                          style: TvButtonStyle.filled,
                          onTap: () => widget.onDetails(current),
                        ),
                        const Spacer(),
                        if (current.scrapeState == ScrapeState.pending ||
                            current.scrapeState == ScrapeState.failed)
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_outlined, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                widget.controller.hasTmdbKey
                                    ? '等待刮削'
                                    : '未配置 TMDB',
                                style: TextStyle(fontSize: 11.5),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.entries.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.entries.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _HeroDot(active: i == _index, onTap: () => _goTo(i)),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroDot extends StatelessWidget {
  const _HeroDot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          width: active ? 26 : 6,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Theme.of(context).colorScheme.primary
                .withValues(alpha: active ? 1 : 0.5),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text('·', style: TextStyle(fontSize: 14)),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final scanning = controller.scanning;
    final progress = controller.scrapeProgress;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scanning
                      ? '正在扫描「${controller.scanSourceName}」 · 已发现 ${controller.scanFound} 个视频'
                      : '正在刮削元数据 · ${progress.done}/${progress.total}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  scanning
                      ? (controller.scanCurrent.isEmpty
                            ? '正在读取目录…'
                            : controller.scanCurrent)
                      : (progress.current.isEmpty ? '准备中…' : progress.current),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!scanning && progress.total > 0) ...[
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 4,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            TvButton(
              label: '停止',
              style: TvButtonStyle.ghost,
              compact: true,
              onTap: controller.cancelScrape,
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Luma 还没有文件访问权限，扫描和播放可能无法读取外接磁盘。')),
          TvButton(
            label: '去授权',
            compact: true,
            onTap: controller.requestStorageAccess,
          ),
        ],
      ),
    );
  }
}
