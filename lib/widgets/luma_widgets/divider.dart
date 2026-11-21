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
