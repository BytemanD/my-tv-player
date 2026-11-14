import 'package:flutter/material.dart';

class LText extends StatelessWidget {
  final String content;

  final TextStyle? style;
  final Color? color;
  final int? maxLines;
  final double maxWidth;

  const LText(
    this.content, {
    super.key,
    this.color,
    this.maxLines,
    this.maxWidth = 0,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Text(
      content,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      style: style?.copyWith(color: color) ?? TextStyle(color: color),
    );
    return Container(
      margin: EdgeInsets.all(2),
      child: maxWidth > 0
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: item,
            )
          : item,
    );
  }
}

class LH0 extends StatelessWidget {
  final String content;
  final Color? color;

  const LH0(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return LText(
      content,
      style: TextStyle(fontSize: 42, fontWeight: FontWeight.w500),
      color: color,
    );
  }
}

class LH1 extends StatelessWidget {
  final String content;
  final Color? color;

  const LH1(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return LText(
      content,
      style: Theme.of(context).textTheme.headlineLarge,
      color: color,
    );
  }
}

class LH2 extends StatelessWidget {
  final String content;
  final Color? color;

  const LH2(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return LText(
      content,
      style: Theme.of(context).textTheme.headlineMedium,
      color: color,
    );
  }
}

class LH3 extends StatelessWidget {
  final String content;
  final Color? color;

  const LH3(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return LText(
      content,
      style: Theme.of(context).textTheme.headlineSmall,
      color: color,
    );
  }
}

class LH4 extends StatelessWidget {
  final String content;
  final Color? color;

  const LH4(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return LText(
      content,
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      color: color,
    );
  }
}

class LTitle extends StatelessWidget {
  final String content;
  final Color? color;

  const LTitle(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      content.toUpperCase(),
      style: Theme.of(context).textTheme.titleLarge!.copyWith(color: color),
    );
  }
}

class LSubTitle extends StatelessWidget {
  final String content;
  final Color? color;

  const LSubTitle(this.content, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(color: color),
    );
  }
}
