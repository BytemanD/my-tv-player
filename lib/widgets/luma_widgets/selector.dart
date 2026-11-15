import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';

class LSelector extends StatefulWidget {
  final List<String> items;
  final ValueChanged<int>? onSelect;
  final String? label;
  final double radius;
  final Color? color;
  final Color? labelColor;

  const LSelector(
    this.items, {
    super.key,
    this.onSelect,
    this.label,
    this.color,
    this.labelColor,
    this.radius = 8,
  });

  @override
  State<StatefulWidget> createState() => _LSelect();
}

class _LSelect extends State<LSelector> {
  int _selected = 0;

  void emit() {
    if (widget.onSelect != null) {
      widget.onSelect!(_selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // spacing: 1,
      children: [
        if (widget.label != null) ...[
          LText(widget.label ?? ""),
          const SizedBox(width: 4),
        ],
        ...List.generate(widget.items.length, (index) {
          final isFirst = index == 0;
          final isLast = index == widget.items.length - 1;
          return ChoiceChip(
            showCheckmark: false,
            label: Text(widget.items[index]),
            selected: _selected == index,
            selectedColor: widget.color,
            labelStyle: widget.labelColor != null
                ? TextStyle(color: Colors.white)
                : null,
            visualDensity: VisualDensity.comfortable,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: isFirst ? Radius.circular(widget.radius) : Radius.zero,
                right: isLast ? Radius.circular(widget.radius) : Radius.zero,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onSelected: (bool selected) {
              if (selected) {
                _selected = index;
                emit();
              }
              setState(() => {});
            },
          );
        }),
      ],
    );
  }
}
