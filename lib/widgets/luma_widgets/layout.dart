import 'package:flutter/widgets.dart';

class CenterWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const CenterWrap(this.children, {super.key, this.spacing = 0});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }

  static CenterWrap small(List<Widget> children) {
    return CenterWrap(children, spacing: 4);
  }

  static CenterWrap medium(List<Widget> children) {
    return CenterWrap(children, spacing: 12);
  }

  static CenterWrap large(List<Widget> children) {
    return CenterWrap(children, spacing: 16);
  }

  static CenterWrap xarge(List<Widget> children) {
    return CenterWrap(children, spacing: 24);
  }
}
