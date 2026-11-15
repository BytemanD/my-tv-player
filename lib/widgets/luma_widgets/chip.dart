import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/_utils.dart';

class LChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? iconColor;
  final bool rounded;
  // none, filled, text
  final String variant;
  final IconData? icon;

  const LChip(
    this.label, {
    super.key,
    this.color,
    this.iconColor,
    this.icon,
    this.rounded = false,
    this.variant = "outlined",
  });

  Chip _ountlined(BuildContext context, {BorderSide? side}) {
    return Chip(
      avatar: icon != null ? Icon(icon!, color: iconColor ?? color) : null,
      label: Text(label),
      labelStyle: TextStyle(color: color),
      // labelStyle: TextStyle(color: Colors.white),
      shape: rounded ? StadiumBorder() : null,
      side: side ?? (color != null ? BorderSide(color: color!) : null),
      // side: BorderSide.none,
    );
  }

  Chip _filled(BuildContext context) {
    final backgroundColor = color ?? Theme.of(context).colorScheme.primary;
    final textColor = estimateFrontColor(backgroundColor);

    return Chip(
      avatar: icon != null ? Icon(icon!, color: textColor) : null,
      label: Text(label),
      labelStyle: TextStyle(color: textColor),
      shape: StadiumBorder().copyWith(side: BorderSide(color: backgroundColor)),
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2),
      child: switch (variant) {
        "filled" => _filled(context),
        "text" => _ountlined(context, side: BorderSide.none),
        _ => _ountlined(context),
      },
    );
  }

  static LChip filled(
    String label, {
    IconData? icon,
    Color? color,
    Color? iconColor,
    bool rounded = false,
  }) {
    return LChip(
      label,
      icon: icon,
      color: color,
      variant: "filled",
      iconColor: iconColor,
      rounded: rounded,
    );
  }

  static LChip text(
    String label, {
    IconData? icon,
    Color? color,
    Color? iconColor,
  }) {
    return LChip(
      label,
      icon: icon,
      color: color,
      variant: "text",
      iconColor: iconColor,
    );
  }
}

class LPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const LPill(this.label, this.value, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final widgetColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      margin: EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(
              label,
              style: TextStyle(color: estimateFrontColor(widgetColor)),
            ),
            backgroundColor: widgetColor,
            side: BorderSide(color: widgetColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(20),
                right: Radius.zero,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            labelPadding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Chip(
            label: Text(value),
            // avatar: Text("data"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                left: Radius.zero,
                right: Radius.circular(20),
              ),
            ),
            side: BorderSide(color: widgetColor),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            labelPadding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
