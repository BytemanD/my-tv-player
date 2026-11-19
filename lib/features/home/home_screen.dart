import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/library_controller.dart';
import 'package:luma_tv/controllers/menu_controller.dart';
import 'package:provider/provider.dart';

import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/data/library_source.dart';
import 'package:luma_tv/data/models.dart';
import 'package:luma_tv/features/detail/detail_screen.dart';
import 'package:luma_tv/features/player/player_launcher.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/carousel.dart';
import 'package:luma_tv/widgets/dialog.dart';
import 'package:luma_tv/widgets/empty_state.dart';
import 'package:luma_tv/widgets/shelf.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final sources = context.select<AppController, List<LibrarySource>>(
      (controller) => controller.sources,
    );
    final entries = context.select<AppController, List<LibraryEntry>>(
      (controller) => controller.entries,
    );
    final hasStorageAccess = context.select<AppController, bool>(
      (controller) => controller.hasStorageAccess,
    );
    final heroEntries = context.select<AppController, List<LibraryEntry>>(
      (controller) => controller.heroEntries,
    );

    final recentEntries = context.select<AppController, List<LibraryEntry>>(
      (controller) => controller.recentEntries,
    );
    final movieEntries = context.select<AppController, List<LibraryEntry>>(
      (controller) => controller.movieEntries,
    );
    final seriesEntries = context.select<AppController, List<LibraryEntry>>(
      (controller) => controller.seriesEntries,
    );
    final scanning = context.select<AppController, bool>(
      (controller) => controller.scanning,
    );
    final scraping = context.select<AppController, bool>(
      (controller) => controller.scraping,
    );
    final continueWatching = context.select<AppController, List<ContinueItem>>(
      (controller) => controller.continueWatching,
    );
    if (sources.isEmpty || entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(34, 26, 56, 30),
        child: EmptyLibrary(
          hasSources: sources.isNotEmpty,
          hasAccess: hasStorageAccess,
          onGrantAccess: controller.requestStorageAccess,
          onAddFolder: () => showAddSourceDialog(context, controller),
          onScan: sources.isEmpty
              ? () => showAddSourceDialog(context, controller)
              : controller.scanAll,
          title: seriesEntries.isEmpty ? null : '还没有发现视频',
        ),
      );
    }

    // final heroEntries = controller.heroEntries;
    final recent = recentEntries.take(14).toList();
    final movies = movieEntries.take(14).toList();
    final series = seriesEntries.take(14).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 26, 56, 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasStorageAccess) ...[
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
          if (scanning || scraping) ...[
            const SizedBox(height: 20),
            _ActivityCard(controller: controller),
          ],
          const SizedBox(height: 30),
          if (continueWatching.isNotEmpty) ...[
            MediaShelf(
              title: '继续观看',
              entries: const [],
              continueItems: continueWatching,
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
            onSeeAll: () => _openLibrary(context, LibraryKind.all),
          ),
          const SizedBox(height: 12),
          if (movies.isNotEmpty) ...[
            MediaShelf(
              title: '电影',
              entries: movies,
              onOpen: (entry) => _openDetails(context, entry),
              onSeeAll: () => _openLibrary(context, LibraryKind.movies),
            ),
            const SizedBox(height: 24),
          ],
          if (series.isNotEmpty) ...[
            MediaShelf(
              title: '剧集',
              entries: series,
              onOpen: (entry) => _openDetails(context, entry),
              onSeeAll: () => _openLibrary(context, LibraryKind.series),
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

  void _openLibrary(BuildContext context, LibraryKind kind) {
    final menuController = context.read<AppMenuController>();
    final libraryController = context.read<LibraryController>();
    menuController.onSelect(1);
    libraryController.setKind(kind);
    if (kind == LibraryKind.all) {
      libraryController.setSort(LibrarySort.recent);
    }
  }
}

class HomeNavigation extends InheritedWidget {
  const HomeNavigation({super.key, required super.child});

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
          TButton(
            label: '去授权',
            // compact: true,
            onClick: controller.requestStorageAccess,
          ),
        ],
      ),
    );
  }
}
