import 'package:flutter/material.dart';

import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/core/common/utils.dart';
import 'package:luma_tv/data/models.dart';
import 'package:luma_tv/widgets/artwork.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/luma_widgets/carousel.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/spliter.dart';
import 'package:luma_tv/widgets/text.dart';

/* 
  轮播海报墙
*/
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
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
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  @override
  Widget build(BuildContext context) {
    return LCarousel([
      for (LibraryEntry item in widget.entries) ...[
        CarouselItem(
          _buildContent(item),
          imageWidget: BackdropImage(
            key: ValueKey<String>(item.key),
            remotePath: item.backdropPath,
            localPath: item.localBackdrop,
            seed: item.title,
          ),
        ),
      ],
    ]);
  }

  Widget _buildContent(LibraryEntry current) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TH0(current.title, color: Colors.white),
        TDivider(height: 12),
        Row(children: _buildMetaRow(current)),
        TDivider(height: 4),
        const SizedBox(height: 14),
        TText(
          current.overview ?? "暂无简介",
          maxWidth: 780,
          maxLines: 4,
          color: Colors.white,
        ),
        TDivider(),
        TSpace([
          TButton(
            label: isContinue ? '继续观看' : '立即播放',
            icon: Icons.play_arrow_rounded,
            color: Theme.of(context).colorScheme.primary,
            onClick: () => widget.onPlay(current),
          ),
          TButton(
            label: '详情',
            icon: Icons.info_outline_rounded,
            onClick: () => widget.onDetails(current),
            // onTap: () => widget.onDetails(current),
            // backgroundColor: const Color(0xFF1A1C22),
          ),
        ], space: 16),
      ],
    );
  }

  List<Widget> _buildMetaRow(LibraryEntry current) {
    final list = <Widget>[];
    if (current.rating != null && current.rating! > 0) {
      list.add(const Icon(Icons.star_rounded, size: 17, color: Colors.amber));
      list.add(const SizedBox(width: 5));
      list.add(TSubTitle(current.rating.toString(), color: Colors.white));
      list.add(const Dot(color: Colors.white));
    }
    if (current.year != null) {
      list.add(TSubTitle('${current.year}', color: Colors.white));
      list.add(const Dot(color: Colors.white));
    }
    list.add(
      TSubTitle(
        current.isSeries
            ? '${current.series!.seasons.length} 季 · ${current.series!.episodeCount} 集'
            : formatRuntime(current.runtime),
        color: Colors.white,
      ),
    );
    if (current.genres.isNotEmpty) {
      list.add(const Dot(color: Colors.white));
      list.add(
        TSubTitle(current.genres.take(2).join(' / '), color: Colors.white),
      );
    }
    return list;
  }
}
