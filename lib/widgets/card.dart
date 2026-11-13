import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/tv_focusable.dart';

class TCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClick;
  final bool selected;
  final double elevation;
  final double borderRadius;
  final double borderWidth;

  const TCard(
    this.child, {
    super.key,
    this.onClick,
    this.selected = false,
    this.elevation = 0,
    this.borderRadius = 8,
    this.borderWidth = 1.4,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onClick ?? () {},
      child: Card(
        elevation: elevation,
        clipBehavior: Clip.antiAlias,
        color: selected ? Theme.of(context).colorScheme.primary : null,

        child: Padding(
          padding: const EdgeInsets.only(
            top: 12,
            left: 8,
            right: 8,
            bottom: 12,
          ),
          child: child,
        ),
      ),
    );
  }
}
