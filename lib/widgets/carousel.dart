import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/core/formatters.dart';
import 'package:luma_tv/data/models.dart';
import 'package:luma_tv/widgets/artwork.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/spliter.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:luma_tv/widgets/tv_focusable.dart';

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
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
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
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0B0C10),
                      const Color(0xFF0B0C10).withValues(alpha: 0.77),
                      const Color(0xFF0B0C10).withValues(alpha: 0.20),
                      const Color(0xFF0B0C10).withValues(alpha: 0),
                    ],
                    stops: const [0, 0.36, 0.7, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0B0C10).withValues(alpha: 0),
                      const Color(0xFF0B0C10).withValues(alpha: 0.40),
                      const Color(0xFF0B0C10).withValues(alpha: 0.90),
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
                      onClick: () => _next(-1),
                      color: Theme.of(context).colorScheme.secondary
                          .withValues(alpha: 0.3),
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
                      onClick: () => _next(),
                      color: Theme.of(context).colorScheme.secondary
                          .withValues(alpha: 0.3),
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
                    TH0(current.title, color: Colors.white),
                    TDivider(height: 12),
                    Row(children: _buildMetaRow(current)),
                    TDivider(height: 14),
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
    return DpadFocusable(
      onSelect: onTap,
      child: Container(
        width: active ? 26 : 6,
        height: 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: active ? const Color(0xFFE9C57E) : Colors.white38,
        ),
      ),
    );
  }
}
