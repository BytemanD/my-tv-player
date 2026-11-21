import 'package:flutter/material.dart';

class LSpace extends StatelessWidget {
  final List<Widget> children;
  final bool vertical;
  final WrapCrossAlignment alighment;
  final double space;
  final bool isExpanded;

  const LSpace(
    this.children, {
    super.key,
    this.vertical = false,
    this.alighment = WrapCrossAlignment.center,
    this.space = 4,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Wrap(
      spacing: space,
      runSpacing: space,
      crossAxisAlignment: alighment,
      direction: vertical ? Axis.vertical : Axis.horizontal,
      children: children,
    );
    return isExpanded ? Expanded(child: item) : item;
  }
}
