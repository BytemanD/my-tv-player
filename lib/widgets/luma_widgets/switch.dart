import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/space.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';

class LSwitch extends StatefulWidget {
  final String? title;
  final String? subTitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;

  const LSwitch(
    this.onChanged, {
    super.key,
    this.title,
    this.subTitle,
    this.value = false,
    this.color,
  });

  @override
  State<StatefulWidget> createState() => _LSwitch();
}

class _LSwitch extends State<LSwitch> {
  bool _value = false;
  @override
  Widget build(BuildContext context) {
    // _value = widget.value;
    return DpadFocusable(
      onSelect: () {
        setState(() {
          _value = !_value;
          widget.onChanged(_value);
        });
      },
      child: Row(
        children: [
          Expanded(
            child: LSpace(
              [LH4(widget.title ?? ''), LSubTitle(widget.subTitle ?? '')],
              vertical: true,
              alighment: WrapCrossAlignment.start,
            ),
          ),
          Switch(
            value: _value,
            activeTrackColor:
                widget.color ?? Theme.of(context).colorScheme.primary,
            activeThumbColor: Theme.of(context).colorScheme.onPrimaryContainer,
            // activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: widget.onChanged,
          ), // 直接绑父级回调
        ],
      ),
    );
  }
}
