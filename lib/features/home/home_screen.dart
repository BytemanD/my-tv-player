import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/carousel.dart';
import 'package:luma_tv/widgets/dialog.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../data/models.dart';
import '../../widgets/button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shelf.dart';
import '../detail/detail_screen.dart';
import '../player/player_launcher.dart';

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
            HeroCarousel(
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
            TButton(label: '停止', onClick: controller.cancelScrape),
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
