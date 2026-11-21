import 'package:flutter/material.dart';

class Dot extends StatelessWidget {
  final String char;
  final Color? color;

  const Dot({super.key, this.char = "·", this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Text(char, style: TextStyle(color: color)),
    );
  }
}
