import 'package:flutter/material.dart';
import 'package:luma_tv/core/common/log.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:luma_tv/widgets/tv_focusable.dart';

class TSelect extends StatefulWidget {
  final List<String> items;
  final ValueChanged<int>? onChanged;
  final String? label;

  const TSelect(this.items, {super.key, this.onChanged, this.label});

  @override
  State<StatefulWidget> createState() => _TSelect();
}

class _TSelect extends State<TSelect> {
  int value = 0;
  int focuse = 0;
  Map<int, bool> focusMap = {};

  @override
  Widget build(BuildContext context) {
    logger.i("build selector, focuse: $focuse, value: $value");
    return TSpace([
      if (widget.label != null) ...[TSubTitle(widget.label!), TDivider()],
      for (int i = 0; i < widget.items.length; i++)
        DpadFocusable(
          // autofocus: value == i,
          onFocusChange: (value) => {focusMap[i] = value, setState(() {})},
          child: TChip(
            widget.items[i],
            // rounded: false,
            color: value == i
                ? null
                : (focusMap[i] ?? false
                      ? Theme.of(context).colorScheme.primaryFixed
                      : Colors.grey),
            boderWidth: 0,
            shap: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? Radius.circular(10) : Radius.zero,
                right: i == widget.items.length - 1
                    ? Radius.circular(10)
                    : Radius.zero,
              ),
            ),
          ),
          onSelect: () => {
            setState(() {
              value = i;
              widget.onChanged?.call(value);
            }),
          },
        ),
    ], space: 1);
  }
}
