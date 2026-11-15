import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';

class LSwitch extends StatefulWidget {
  final String? title;
  final String? subTitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LSwitch(
    this.onChanged, {
    super.key,
    this.title,
    this.subTitle,
    this.value = false,
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
            child: TSpace(
              [TH4(widget.title ?? ''), TSubTitle(widget.subTitle ?? '')],
              vertical: true,
              alighment: WrapCrossAlignment.start,
            ),
          ),
          Switch(
            value: _value,
            activeThumbColor: Theme.of(context).colorScheme.onPrimary,
            onChanged: widget.onChanged,
          ), // 直接绑父级回调
        ],
      ),
    );
  }
}
