import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/library_controller.dart';
import 'package:luma_tv/data/library_source.dart';
import 'package:luma_tv/widgets/dialog.dart';
import 'package:luma_tv/widgets/luma_widgets/divider.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:luma_tv/widgets/luma_widgets/selector.dart';
import 'package:luma_tv/widgets/luma_widgets/space.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../data/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_cards.dart';
import '../detail/detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Widget filterPanel(AppController controller, LibraryKind kind) {
    final libraryController = context.read<LibraryController>();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(34, 14, 56, 12),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LSelector(
                  LibraryKind.values.map((x) => x.label).toList(),
                  label: "类型:",
                  variant: "text",
                  value: LibraryKind.values.indexOf(kind),
                  onSelect: (index) =>
                      libraryController.setKind(LibraryKind.values[index]),
                ),
                const Spacer(),
                LButton(
                  icon: Icons.refresh_rounded,
                  autofocus: true,
                  color: Theme.of(context).colorScheme.primary,
                  onClick: controller.scanAll,
                ),
              ],
            ),
            TDivider(height: 4),
            Row(
              children: [
                LSpace([
                  LSelector(
                    LibrarySort.values.map((x) => x.label).toList(),
                    label: "排序:",
                    variant: "text",
                    value: LibrarySort.values.indexOf(libraryController.sort),
                    onSelect: (value) =>
                        libraryController.setSort(LibrarySort.values[value]),
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget emptyContainer(
    AppController controller,
    List<LibrarySource> sources,
    bool hasStorageAccess,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 56),
        child: EmptyLibrary(
          hasSources: sources.isNotEmpty,
          hasAccess: hasStorageAccess,
          onGrantAccess: controller.requestStorageAccess,
          onAddFolder: () => showAddSourceDialog(context, controller),
          onScan: controller.scanAll,
          title: '这里还没有内容',
          description: sources.isEmpty
              ? '添加一个媒体目录，Luma 会自动扫描视频并刮削海报与元数据。'
              : '没有符合当前筛选条件的条目。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final sources = context.select<AppController, List<LibrarySource>>(
      (c) => c.sources,
    );
    final hasStorageAccess = context.select<AppController, bool>(
      (c) => c.hasStorageAccess,
    );

    final kind = context.select<LibraryController, LibraryKind>((c) => c.kind);
    context.select<AppController, List<LibraryEntry>>((c) => c.entries);
    final entries = _sorted(controller.getEntriesByKind(kind));
    final medias = CustomScrollView(
      slivers: [
        filterPanel(controller, kind),
        if (entries.isEmpty)
          emptyContainer(controller, sources, hasStorageAccess)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(34, 12, 56, 46),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = (width / 115).floor().clamp(3, 10);
                const spacing = 1.0;
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
                        showMeta: false,
                        width: cardWidth.clamp(100, 140),
                        // autofocus: index == 0,
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

    return Scaffold(body: medias, bottomSheet: LStrong('${entries.length} 部'));
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

  List<LibraryEntry> _sorted(List<LibraryEntry> input) {
    final sort = context.select<LibraryController, LibrarySort>(
      (controller) => controller.sort,
    );

    final list = [...input];
    switch (sort) {
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
