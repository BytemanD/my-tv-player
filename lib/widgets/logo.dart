import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class LumaMark extends StatelessWidget {
  const LumaMark({super.key, this.size = 40, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? LumaColors.accent;
    return CustomPaint(
      size: Size.square(size),
      painter: _LumaMarkPainter(resolved),
    );
  }
}

class _LumaMarkPainter extends CustomPainter {
  const _LumaMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..color = color;
    canvas.drawCircle(center, radius - ring.strokeWidth / 2, ring);

    // A stylised projector aperture: filled lens with a light beam cut-out.
    final lens = Paint()..color = color;
    canvas.drawCircle(center, radius * 0.30, lens);

    final beam = Path()
      ..moveTo(center.dx + radius * 0.06, center.dy - radius * 0.22)
      ..lineTo(center.dx + radius * 0.64, center.dy - radius * 0.52)
      ..lineTo(center.dx + radius * 0.64, center.dy + radius * 0.52)
      ..lineTo(center.dx + radius * 0.06, center.dy + radius * 0.22)
      ..close();
    canvas.drawPath(beam, Paint()..color = color.withValues(alpha: 0.22));

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.035
      ..color = color.withValues(alpha: 0.9);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.68),
      -math.pi * 0.72,
      math.pi * 0.44,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(covariant _LumaMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class LumaWordmark extends StatelessWidget {
  const LumaWordmark({
    super.key,
    this.fontSize = 22,
    this.color,
    this.letterSpacing = 6,
  });

  final double fontSize;
  final Color? color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(
      'LUMA',
      style: TextStyle(
        fontFamily: LumaTheme.displayFont,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: letterSpacing,
        color: color ?? LumaColors.text,
        height: 1,
      ),
    );
  }
}

class LumaLogo extends StatelessWidget {
  const LumaLogo({super.key, this.fontSize = 22, this.markSize = 34});

  final double fontSize;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LumaMark(size: markSize),
        SizedBox(width: markSize * 0.30),
        LumaWordmark(fontSize: fontSize),
      ],
    );
  }
}
