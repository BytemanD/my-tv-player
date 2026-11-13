import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';

class TSwitch extends StatefulWidget {
  final String? title;
  final String? subTitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const TSwitch(
    this.onChanged, {
    super.key,
    this.title,
    this.subTitle,
    this.value = true,
  });

  @override
  State<StatefulWidget> createState() => _TSwitchState();
}

class _TSwitchState extends State<TSwitch> {
  bool value = false;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      // autofocus: true,
      effects: [DpadGlowEffect(), DpadScaleEffect(scale: 0.98)],
      onSelect: () => setState(() {
        value = !value;
        widget.onChanged(value);
      }),
      child: Row(
        children: [
          Expanded(
            child: TSpace(
              [TH4(widget.title ?? ""), TSubTitle(widget.subTitle ?? "")],
              vertical: true,
              alighment: WrapCrossAlignment.start,
            ),
          ),
          // const SizedBox(width: 116),
          Switch(value: value, onChanged: null),
        ],
      ),
    );
  }
}
