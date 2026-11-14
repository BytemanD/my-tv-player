import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

enum Variant { elevated, outlined, filled, text, ghost }

class LButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? color;
  final double? size;
  final Variant variant;

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
    this.variant = Variant.elevated,
    this.borderRadius = 8,
    this.onClick,
    this.enabled = true,
    this.autofocus = false,
  });

  IconButton _iconButton(
    BuildContext context, {
    Variant variant = Variant.elevated,
  }) {
    final backgroundColor = switch (variant) {
      Variant.elevated =>
        color ?? Theme.of(context).colorScheme.surfaceContainer,
      Variant.outlined => Colors.transparent,
      Variant.filled => color ?? Theme.of(context).colorScheme.primary,
      _ => null,
    };
    final iconColor = switch (variant) {
      Variant.elevated => color == null ? null : Colors.white,
      Variant.outlined => color,
      Variant.filled => Theme.of(context).colorScheme.onPrimary,
      Variant.text => color,
      _ => null,
    };
    final borderColor = switch (variant) {
      Variant.elevated => null,
      Variant.outlined => color ?? Theme.of(context).colorScheme.outline,
      Variant.filled => color ?? Theme.of(context).colorScheme.primary,
      Variant.text => null,
      _ => Theme.of(context).colorScheme.outline,
    };
    return IconButton(
      icon: Icon(icon),
      color: iconColor,
      style: IconButton.styleFrom(
        elevation: variant == Variant.elevated ? 3 : 0,
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
                foregroundColor: Colors.white,
              )
            : null,
        // style: _buttonStyle(context),
      );
    }

    return ElevatedButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: color != null
          ? ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            )
          : null,
      child: Text(label ?? ""),
    );
  }

  Widget _outlinedButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context, variant: Variant.outlined);
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
      return _iconButton(context, variant: Variant.filled);
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
                foregroundColor: Colors.white,
              )
            : null,
        // style: _buttonStyle(context),
      );
    }
    return FilledButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: color != null
          ? FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            )
          : null,
      child: Text(label ?? ""),
    );
  }

  Widget _textButton(BuildContext context) {
    if (icon != null && label == null) {
      return _iconButton(context, variant: Variant.text);
    }
    if (icon != null) {
      return TextButton.icon(
        onPressed: enabled ? onClick ?? () {} : null,
        icon: Icon(icon),
        label: Text(label ?? ""),
        style: FilledButton.styleFrom(foregroundColor: color),
        // style: _buttonStyle(context),
      );
    }
    return TextButton(
      onPressed: enabled ? onClick ?? () {} : null,
      style: FilledButton.styleFrom(foregroundColor: color), // : null,
      child: Text(label ?? ""),
    );
  }

  Widget _ghostButton(BuildContext context) {
    return DashedBorderButton(
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
          Variant.elevated => _elevatedButton(context),
          Variant.outlined => _outlinedButton(context),
          Variant.filled => _filledButton(context),
          Variant.text => _textButton(context),
          Variant.ghost => _ghostButton(context),
        },
      ),
    );
  }
}

class DashedBorderButton extends StatelessWidget {
  const DashedBorderButton({
    super.key,
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
