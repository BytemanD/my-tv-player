import 'package:flutter/material.dart';

class TH0 extends StatelessWidget {
  final String label;
  final Color? color;

  const TH0(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 52, fontWeight: FontWeight.w600, color: color),
    );
  }
}

class TH1 extends StatelessWidget {
  final String label;
  final Color? color;

  const TH1(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, color: color),
    );
  }
}

class TH2 extends StatelessWidget {
  final String label;
  final Color? color;

  const TH2(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: color),
    );
  }
}

class TH3 extends StatelessWidget {
  final String label;
  final Color? color;

  const TH3(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: color),
    );
  }
}

class TH4 extends StatelessWidget {
  final String label;
  final Color? color;

  const TH4(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color),
    );
  }
}

class TTitle extends StatelessWidget {
  final String label;
  final Color? color;

  const TTitle(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: color,
      ),
    );
  }
}

class TSubTitle extends StatelessWidget {
  final String label;
  final Color? color;

  const TSubTitle(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 12.5, color: color));
  }
}

class TChip extends StatelessWidget {
  final String label;
  final Color? color;
  final double boderWidth;
  final bool rounded;
  final RoundedRectangleBorder? shap;

  const TChip(
    this.label, {
    super.key,
    this.color,
    this.boderWidth = 1,
    this.rounded = true,
    this.shap,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: boderWidth > 0
          ? BorderSide(
              color: (color ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.7),
              width: boderWidth,
            )
          : BorderSide.none,
      // shape: rouded ? StadiumBorder() : null,
      shape: shap ?? (rounded ? StadiumBorder() : null),
      backgroundColor: (color ?? Theme.of(context).colorScheme.primary)
          .withValues(alpha: 0.4),
    );
  }
}

class TText extends StatelessWidget {
  final String content;
  final Color? color;

  final double fontSize;
  final double maxWidth;
  final int? maxLines;

  const TText(
    this.content, {
    super.key,
    this.color,
    this.maxLines,
    this.fontSize = 13.5,
    this.maxWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Text(
      content,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      style: TextStyle(fontSize: fontSize, color: color),
    );
    return maxWidth > 0
        ? ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: item,
          )
        : item;
  }
}
