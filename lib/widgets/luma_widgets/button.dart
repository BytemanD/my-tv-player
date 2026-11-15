import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/luma_widgets/_utils.dart';

// enum _Variant { elevated, outlined, filled, text, ghost }

class LButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final double? size;
  final String variant;

  final VoidCallback? onClick;
  final bool autofocus;
  final double borderRadius;
  final bool enabled;

  const LButton({
    super.key,
    this.size,
    this.color,
    this.icon,
    this.label,
    this.variant = "elevated",
    this.borderRadius = 8,
    this.onClick,
    this.enabled = true,
    this.autofocus = false,
  });

  IconButton _iconButton(BuildContext context, {String variant = "elevated"}) {
    final backgroundColor = switch (variant) {
      "elevated" => color ?? Theme.of(context).colorScheme.surfaceContainer,
      "outlined" => Colors.transparent,
      "filled" => color ?? Theme.of(context).colorScheme.primary,
      _ => null,
    };
    final iconColor = switch (variant) {
      "elevated" => color == null ? null : estimateFrontColor(color!),
      "outlined" => color,
      "filled" => Theme.of(context).colorScheme.onPrimary,
      "text" => color,
      _ => null,
    };
    final borderColor = switch (variant) {
      "elevated" => null,
      "outlined" => color ?? Theme.of(context).colorScheme.outline,
      "filled" => color ?? Theme.of(context).colorScheme.primary,
      "text" => null,
      _ => Theme.of(context).colorScheme.outline,
    };
    return IconButton(
      icon: Icon(icon),
      color: iconColor,
      style: IconButton.styleFrom(
        elevation: variant == "elevated" ? 3 : 0,
        // iconSize: 18,
        // minimumSize: const Size(32, 32), // 最小尺寸
        // maximumSize: const Size(32, 32),
        shadowColor: Theme.of(context).shadowColor,
        backgroundColor: backgroundColor,
        side: borderColor != null
            ? BorderSide(color: borderColor, width: 1)
            : null,

        shape: const CircleBorder(),
      ),
      onPressed: enabled ? onClick ?? () {} : null,
    );
  }

  Widget _elevatedButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context);
    }
    if (icon != null) {
      return ElevatedButton.icon(
        // onPressed: onClick,
        onPressed: enabled ? onClick ?? () {} : null,
        icon: Icon(icon),
        label: Text(label ?? ""),
        style: color != null
            ? ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: estimateFrontColor(color!),
              )
            : null,
      );
    }

    return ElevatedButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: color != null
          ? ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: estimateFrontColor(color!),
            )
          : null,
      child: Text(label ?? ""),
    );
  }

  Widget _outlinedButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context, variant: "outlined");
    }
    if (icon != null) {
      return OutlinedButton.icon(
        // onPressed: onClick,
        onPressed: enabled ? onClick ?? () {} : null,
        icon: Icon(icon),
        label: Text(label ?? ""),
        style: color != null
            ? OutlinedButton.styleFrom(
                // backgroundColor: ,
                foregroundColor: color,
                side: color != null
                    ? BorderSide(color: color!, width: 1)
                    : null,
              )
            : null,
      );
    }

    return OutlinedButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: color != null
          ? OutlinedButton.styleFrom(
              foregroundColor: color,
              side: color != null ? BorderSide(color: color!, width: 1) : null,
            )
          : null,
      child: Text(label ?? ""),
    );
  }

  Widget _filledButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context, variant: "filled");
    }
    if (icon != null) {
      return FilledButton.icon(
        // onPressed: onClick,
        onPressed: enabled ? onClick ?? () {} : null,
        icon: Icon(icon),
        label: Text(label ?? ""),
        style: color != null
            ? FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: estimateFrontColor(color!),
              )
            : null,
      );
    }
    return FilledButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: color != null
          ? FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: estimateFrontColor(color!),
            )
          : null,
      child: Text(label ?? ""),
    );
  }

  Widget _textButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context, variant: "text");
    }
    if (icon != null) {
      return TextButton.icon(
        onPressed: enabled ? onClick ?? () {} : null,
        icon: Icon(icon),
        label: Text(label ?? ""),
        style: FilledButton.styleFrom(foregroundColor: color),
      );
    }
    return TextButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: FilledButton.styleFrom(foregroundColor: color), // : null,
      child: Text(label ?? ""),
    );
  }

  Widget _ghostButton(BuildContext context) {
    return _DashedBorderButton(
      onPressed: enabled ? onClick ?? () {} : null,
      color: color ?? Theme.of(context).colorScheme.primary,
      child: _textButton(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      // onFocusChange: (value) => {print("button focuse: ${value}")},
      onSelect: enabled ? (onClick ?? () {}) : null,
      child: Container(
        margin: const EdgeInsets.only(left: 4, right: 4, top: 1, bottom: 1),
        child: switch (variant) {
          "elevated" => _elevatedButton(context),
          "outlined" => _outlinedButton(context),
          "filled" => _filledButton(context),
          "text" => _textButton(context),
          "ghost" => _ghostButton(context),
          _ => _elevatedButton(context),
        },
      ),
    );
  }

  static LButton outlined({
    String? label,
    IconData? icon,
    Color? color,
    double? size,
    VoidCallback? onClick,
    bool autofocus = false,
    double borderRadius = 8,
    bool enabled = true,
  }) {
    return LButton(
      label: label,
      icon: icon,
      color: color,
      size: size,
      onClick: onClick,
      autofocus: autofocus,
      borderRadius: borderRadius,
      enabled: enabled,
      variant: "outlined",
    );
  }

  static LButton filled({
    String? label,
    IconData? icon,
    Color? color,
    double? size,
    VoidCallback? onClick,
    bool autofocus = false,
    double borderRadius = 8,
    bool enabled = true,
  }) {
    return LButton(
      label: label,
      icon: icon,
      color: color,
      size: size,
      onClick: onClick,
      autofocus: autofocus,
      borderRadius: borderRadius,
      enabled: enabled,
      variant: "filled",
    );
  }

  static LButton text({
    String? label,
    IconData? icon,
    Color? color,
    double? size,
    VoidCallback? onClick,
    bool autofocus = false,
    double borderRadius = 8,
    bool enabled = true,
  }) {
    return LButton(
      label: label,
      icon: icon,
      color: color,
      size: size,
      onClick: onClick,
      autofocus: autofocus,
      borderRadius: borderRadius,
      enabled: enabled,
      variant: "text",
    );
  }

  static LButton ghost({
    String? label,
    IconData? icon,
    Color? color,
    double? size,
    VoidCallback? onClick,
    bool autofocus = false,
    double borderRadius = 8,
    bool enabled = true,
  }) {
    return LButton(
      label: label,
      icon: icon,
      color: color,
      size: size,
      onClick: onClick,
      autofocus: autofocus,
      borderRadius: borderRadius,
      enabled: enabled,
      variant: "ghost",
    );
  }
}

class _DashedBorderButton extends StatelessWidget {
  const _DashedBorderButton({
    required this.onPressed,
    required this.child,
    this.color,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? Theme.of(context).colorScheme.outline,
        radius: 45,
        dashLength: 6,
        gapLength: 4,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    // 沿路径按 dashLength + gapLength 切段
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
