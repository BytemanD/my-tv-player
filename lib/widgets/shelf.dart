import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../data/models.dart';
import 'media_cards.dart';
import 'tv_focusable.dart';

class MediaShelf extends StatelessWidget {
  const MediaShelf({
    super.key,
    required this.title,
    required this.entries,
    required this.onOpen,
    this.onSeeAll,
    this.autofocusFirst = false,
    this.continueItems,
    this.onOpenContinue,
    this.height,
  });

  final String title;
  final List<LibraryEntry> entries;
  final void Function(LibraryEntry entry) onOpen;
  final void Function(ContinueItem item)? onOpenContinue;
  final VoidCallback? onSeeAll;
  final bool autofocusFirst;
  final List<ContinueItem>? continueItems;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final isContinue = continueItems != null;
    final itemCount = isContinue ? continueItems!.length : entries.length;
    if (itemCount == 0) return const SizedBox.shrink();
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final inheritedTextStyle = DefaultTextStyle.of(context).style;
    final maxMetaHeight = entries.fold<double>(0, (maxHeight, entry) {
      final titlePainter = TextPainter(
        text: TextSpan(
          text: entry.title.isEmpty ? ' ' : entry.title,
          style: inheritedTextStyle.merge(
            const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
          ),
        ),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: 168);
      final subtitle = _subtitle(entry);
      final subtitlePainter = TextPainter(
        text: TextSpan(
          text: subtitle.isEmpty ? ' ' : subtitle,
          style: inheritedTextStyle.merge(const TextStyle(fontSize: 12)),
        ),
        maxLines: 1,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: 168);
      final metaHeight = titlePainter.height + subtitlePainter.height;
      return metaHeight > maxHeight ? metaHeight : maxHeight;
    });
    final posterShelfHeight = 264 + 10 + 3 + maxMetaHeight + 12 + 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 8, bottom: 8),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: LumaColors.text,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$itemCount',
                style: TextStyle(fontSize: 12, color: LumaColors.textMuted),
              ),
              const Spacer(),
              if (onSeeAll != null)
                TvButton(
                  label: '查看全部',
                  style: TvButtonStyle.ghost,
                  compact: true,
                  onTap: onSeeAll,
                ),
            ],
          ),
        ),
        SizedBox(
          height: height ?? (isContinue ? 190 : posterShelfHeight),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (isContinue) {
                return ContinueCard(
                  item: continueItems![index],
                  autofocus: autofocusFirst && index == 0,
                  onTap: () {
                    final item = continueItems![index];
                    if (onOpenContinue != null) {
                      onOpenContinue!(item);
                    } else {
                      onOpen(LibraryEntry.movie(item.media));
                    }
                  },
                );
              }
              return PosterCard(
                entry: entries[index],
                autofocus: autofocusFirst && index == 0,
                onTap: () => onOpen(entries[index]),
              );
            },
          ),
        ),
      ],
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

class EpisodeShelf extends StatelessWidget {
  const EpisodeShelf({
    super.key,
    required this.episodes,
    required this.onOpen,
    this.progressMap = const {},
    this.autofocusFirst = false,
  });

  final List<MediaItem> episodes;
  final void Function(MediaItem media) onOpen;
  final Map<int, PlaybackProgress> progressMap;
  final bool autofocusFirst;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        itemCount: episodes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final media = episodes[index];
          return EpisodeCard(
            media: media,
            autofocus: autofocusFirst && index == 0,
            progress: media.id == null ? null : progressMap[media.id],
            watched: progressMap[media.id]?.completed ?? false,
            onTap: () => onOpen(media),
          );
        },
      ),
    );
  }
}
