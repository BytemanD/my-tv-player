import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_cards.dart';
import '../../widgets/tv_focusable.dart';
import '../detail/detail_screen.dart';
import '../sources/add_source_dialog.dart';

enum LibraryKind { all, movies, series }

enum LibrarySort {
  recent('最近添加'),
  title('名称'),
  year('年份'),
  rating('评分');

  const LibrarySort(this.label);
  final String label;
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.kind = LibraryKind.all});

  final LibraryKind kind;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibrarySort _sort = LibrarySort.recent;
  LibraryKind? _filter;

  LibraryKind get _activeFilter => _filter ?? widget.kind;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final all = _entries(controller);
    final entries = _sorted(all);

    final title = switch (widget.kind) {
      LibraryKind.movies => '电影',
      LibraryKind.series => '剧集',
      LibraryKind.all => '媒体库',
    };

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(34, 30, 56, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: LumaColors.text,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${entries.length} 部',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: LumaColors.textMuted,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TvButton(
                      label: '添加目录',
                      icon: Icons.add_rounded,
                      style: TvButtonStyle.filled,
                      backgroundColor: LumaColors.primary.withValues(
                        alpha: 0.40,
                      ),
                      compact: true,
                      onTap: () => showAddSourceDialog(context, controller),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (widget.kind == LibraryKind.all) ...[
                      for (final kind in LibraryKind.values) ...[
                        TvChip(
                          label: switch (kind) {
                            LibraryKind.all => '全部',
                            LibraryKind.movies => '电影',
                            LibraryKind.series => '剧集',
                          },
                          selected: _activeFilter == kind,
                          onTap: () => setState(() => _filter = kind),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const SizedBox(width: 16),
                    ],
                    Text(
                      '排序',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: LumaColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    for (final sort in LibrarySort.values) ...[
                      TvChip(
                        label: sort.label,
                        selected: _sort == sort,
                        onTap: () => setState(() => _sort = sort),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    TvIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: '重新扫描',
                      onTap: controller.scanAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: EmptyLibrary(
                hasSources: controller.sources.isNotEmpty,
                hasAccess: controller.hasStorageAccess,
                onGrantAccess: controller.requestStorageAccess,
                onAddFolder: () => showAddSourceDialog(context, controller),
                onScan: controller.scanAll,
                title: '这里还没有内容',
                description: controller.sources.isEmpty
                    ? '添加一个媒体目录，Luma 会自动扫描视频并刮削海报。'
                    : '没有符合当前筛选条件的条目。',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(34, 12, 56, 46),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = (width / 215).floor().clamp(3, 10);
                const spacing = 12.0;
                final cellWidth = (width - spacing * (columns - 1)) / columns;
                final cardWidth = cellWidth - 12;
                final rowHeight = cardWidth * 1.5 + 48;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: 16,
                    mainAxisExtent: rowHeight,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final entry = entries[index];
                    return Align(
                      alignment: Alignment.topLeft,
                      child: PosterCard(
                        entry: entry,
                        width: cardWidth.clamp(140, 230),
                        autofocus: index == 0,
                        watchFraction: _fractionFor(controller, entry),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailScreen(entryKey: entry.key),
                          ),
                        ),
                      ),
                    );
                  }, childCount: entries.length),
                );
              },
            ),
          ),
      ],
    );
  }

  double _fractionFor(AppController controller, LibraryEntry entry) {
    if (entry.isSeries) {
      final episode = controller.resumeEpisodeForSeries(entry.series!.key);
      if (episode?.id == null) return 0;
      return controller.progressMap[episode!.id!]?.fraction ?? 0;
    }
    final id = entry.movie?.id;
    if (id == null) return 0;
    return controller.progressMap[id]?.fraction ?? 0;
  }

  List<LibraryEntry> _entries(AppController controller) {
    final kind = _activeFilter;
    final source = switch (kind) {
      LibraryKind.movies => controller.movieEntries,
      LibraryKind.series => controller.seriesEntries,
      LibraryKind.all => controller.entries,
    };
    return [...source];
  }

  List<LibraryEntry> _sorted(List<LibraryEntry> input) {
    final list = [...input];
    switch (_sort) {
      case LibrarySort.recent:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      case LibrarySort.title:
        list.sort((a, b) => a.title.compareTo(b.title));
      case LibrarySort.year:
        list.sort((a, b) {
          final ay = a.year ?? 9999;
          final by = b.year ?? 9999;
          return ay.compareTo(by);
        });
      case LibrarySort.rating:
        list.sort((a, b) {
          final ar = a.rating ?? 0;
          final br = b.rating ?? 0;
          return br.compareTo(ar);
        });
    }
    return list;
  }
}
