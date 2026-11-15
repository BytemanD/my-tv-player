import 'dart:async';

import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';

class CarouselItem {
  Widget content;
  String? image;
  CarouselItem(this.content, {this.image});
}

class LCarousel extends StatefulWidget {
  final List<CarouselItem> items;
  final double height;
  final bool autoPlay;
  final int playInterval;
  final double borderRadius;
  const LCarousel(
    this.items, {
    super.key,
    this.autoPlay = true,
    this.playInterval = 5,
    this.height = 414,
    this.borderRadius = 26,
  });

  @override
  State<LCarousel> createState() => _LCarousel();
}

class _LCarousel extends State<LCarousel> {
  int _current = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    if (!widget.autoPlay) {
      return;
    }
    _timer?.cancel();
    if (_paused || widget.items.length <= 1) return;
    _timer = Timer.periodic(
      Duration(seconds: widget.playInterval),
      (_) => _next(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    setState(
      () =>
          _current = (_current - 1 + widget.items.length) % widget.items.length,
    );
  }

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: _mainWidget(context),
      ),
    );
  }

  Widget _mainWidget(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 2000),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(_current),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(child: _getBackgroudIamage(context)),
              ),
              // 内容
              Positioned(
                left: 70,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: widget.items[_current].content,
                ),
              ),
              // 操作
              Positioned.fill(
                left: 12,
                right: 12,
                bottom: 10,
                child: SizedBox(
                  height: widget.height,
                  // padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      const Spacer(),
                      _getControllPanel(context),
                      const Spacer(),
                      // LChip("xxxxxxxxx"),
                      _getCarouselDot(context),
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

  Widget _getBackgroudIamage(BuildContext context) {
    return widget.items[_current].image != null
        ? Image.network(widget.items[_current].image!, fit: BoxFit.cover)
        : SizedBox();
  }

  Widget _getControllPanel(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);
    return Row(
      children: [
        LButton(icon: Icons.chevron_left_rounded, color: color, onClick: _next),
        Spacer(),
        LButton(
          icon: Icons.chevron_right_rounded,
          color: color,
          onClick: () {
            setState(() => _current = (_current + 1) % widget.items.length);
          },
        ),
      ],
    );
  }

  Widget _getCarouselDot(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CarouselDot(active: i == _current),
          ],
        ],
      ),
    );
  }
}

class _CarouselDot extends StatelessWidget {
  final bool active;

  const _CarouselDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      width: active ? 26 : 6,
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: Theme.of(context).colorScheme.primary
            .withValues(alpha: active ? 1 : 0.5),
      ),
    );
  }
}
