import 'package:flutter/material.dart';

class TDivider extends StatelessWidget {
  final double height;
  final double width;

  const TDivider({super.key, this.height = 16, this.width = 16});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height, width: width);
  }
}

class TLine extends StatelessWidget {
  final double indent;

  const TLine({super.key, this.indent = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(top: indent, bottom: indent),
      color: Theme.of(context).colorScheme.surfaceDim,
    );
  }
}
