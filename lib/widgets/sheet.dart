import 'package:flutter/material.dart';

class TSheet extends StatelessWidget {
  final double height;
  final double width;

  final Widget child;

  const TSheet(this.child, {super.key, this.height = 16, this.width = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
      // color: Theme.of(context).colorScheme.surfaceContainer,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        // border: Border.all(color: LumaColors.lineSoft),
      ),
      child: child,
    );
  }
}
