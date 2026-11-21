import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/_utils.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';

class LSelector extends StatefulWidget {
  final List<String> items;
  final ValueChanged<int>? onSelect;
  final String? label;
  final double radius;
  final Color? color;
  final Color? labelColor;
  final int? value;
  final String variant;

  const LSelector(
    this.items, {
    super.key,
    this.onSelect,
    this.label,
    this.color,
    this.labelColor,
    this.radius = 8,
    this.value,
    this.variant = "defalut",
  });

  @override
  State<StatefulWidget> createState() => _LSelect();
}

class _LSelect extends State<LSelector> {
  int _selected = 0;
  Map<int, bool> focusState = {};

  RoundedRectangleBorder? _getSide(bool isFirst, bool isLast) {
    return widget.variant == "text"
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? Radius.circular(widget.radius) : Radius.zero,
              right: isLast ? Radius.circular(widget.radius) : Radius.zero,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value != null) {
      _selected = widget.value!;
    }
    Color selectColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return Wrap(
      // spacing: 1,
      children: [
        if (widget.label != null) ...[
          LText(widget.label ?? ""),
          const SizedBox(width: 4),
        ],
        ...List.generate(widget.items.length, (index) {
          return DpadFocusable(
            onSelect: () => {
              setState(() => _selected = index),
              widget.onSelect?.call(_selected),
            },
            onFocusChange: (v) => setState(() => focusState[index] = v),
            // excludeChildFocus: false,
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(widget.items[index]),
              selected: _selected == index,
              selectedColor: selectColor,
              labelStyle: widget.labelColor != null
                  ? TextStyle(color: Colors.white)
                  : (_selected == index
                        ? TextStyle(color: estimateFrontColor(selectColor))
                        : null),
              visualDensity: VisualDensity.comfortable,
              shape: _getSide(index == 0, index == widget.items.length - 1),
              side: widget.variant == "text" ? BorderSide.none : null,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: focusState[index] == true
                  ? selectColor.withValues(alpha: 0.5)
                  : null,
              onSelected: (v) => {
                if (v)
                  {
                    setState(() => _selected = index),
                    widget.onSelect?.call(_selected),
                  },
              },
            ),
          );
        }),
      ],
    );
  }
}
