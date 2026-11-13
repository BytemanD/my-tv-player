import 'package:flutter/material.dart';
// import 'package:luma_tv/core/luma_colors.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/selector.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../data/models.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/media_cards.dart';
import '../detail/detail_screen.dart';
import '../sources/add_source_dialog.dart';

enum LibraryKind {
  all('全部'),
  movies('电影'),
  series("剧集");

  const LibraryKind(this.label);
  final String label;
}

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
  final FocusNode _focusNode = FocusNode();

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
                TSpace([
                  TH1(title),
                  TDivider(),
                  TSubTitle('${entries.length} 部'),
                ]),
                TDivider(),

                Row(
                  children: [
                    if (widget.kind == LibraryKind.all)
                      Row(
                        children: [
                          TSelect(
                            LibraryKind.values.map((x) => x.label).toList(),
                            onChanged: (index) => setState(() {
                              _filter = LibraryKind.values[index];
                            }),
                          ),
                          TDivider(),
                        ],
                      ),
                    TDivider(width: 20),
                    TSpace([
                      TSelect(
                        LibrarySort.values.map((x) => x.label).toList(),
                        label: "排序",
                        onChanged: (value) => setState(() {
                          _sort = LibrarySort.values[value];
                        }),
                      ),
                    ]),

                    const Spacer(),
                    TButton(
                      icon: Icons.refresh_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      onClick: controller.scanAll,
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
                    ? '添加一个媒体目录，Luma 会自动扫描视频并刮削海报与元数据。'
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
