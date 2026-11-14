import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/text.dart';

class TSwitch extends StatelessWidget {
  const TSwitch(
    this.onChanged, {
    super.key,
    this.title,
    this.subTitle,
    this.value = false,
  });

  final String? title;
  final String? subTitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      effects: const [DpadGlowEffect(), DpadScaleEffect(scale: 0.98)],
      onSelect: () => onChanged(!value), // 直接取反通知父级
      child: Row(
        children: [
          Expanded(
            child: TSpace(
              [TH4(title ?? ''), TSubTitle(subTitle ?? '')],
              vertical: true,
              alighment: WrapCrossAlignment.start,
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.onPrimary,
            onChanged: onChanged,
          ), // 直接绑父级回调
        ],
      ),
    );
  }
}
