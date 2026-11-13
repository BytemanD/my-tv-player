import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TButton extends StatelessWidget {
  final double? size;
  final Color? color;
  final IconData? icon;
  final String? label;
  // filled, outlined,

  final VoidCallback? onClick;
  final bool autofocus;
  final double borderRadius;
  final bool enabled;

  const TButton({
    super.key,
    this.size,
    this.color,
    this.icon,
    this.label,
    this.borderRadius = 8,
    this.onClick,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      // onFocusChange: (value) => {print("button focuse: ${value}")},
      onSelect: enabled ? (onClick ?? () {}) : null,
      child: icon != null
          ? label != null
                ? ElevatedButton.icon(
                    // onPressed: onClick,
                    onPressed: enabled ? (onClick ?? () {}) : null,
                    icon: Icon(icon),
                    label: Text(label ?? ""),
                    style: color != null
                        ? ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    // style: _buttonStyle(context),
                  )
                : IconButton(
                    onPressed: enabled ? (onClick ?? () {}) : null,
                    icon: Icon(icon),
                    color: Colors.white,
                    style: color != null
                        ? IconButton.styleFrom(backgroundColor: color)
                        : null,
                  )
          : ElevatedButton(
              onPressed: enabled ? (onClick ?? () {}) : null,
              // style: _buttonStyle(context),
              style: color != null
                  ? ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: Text(label ?? ""),
            ),
    );
  }
}

/// 兼容旧代码：TvButton 委托给 TButton。
/// 旧调用：TvButton(label, icon, autofocus, onTap, backgroundColor, style, compact)
/// 新对应：TButton(label, icon, color=backgroundColor, onClick=onTap)
class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    this.label = '',
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.autofocus = false,
    this.enabled = true,
    this.compact = false,
    this.square = false,
    this.focusElevation = 10,
    this.style,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool autofocus;
  final bool enabled;
  final bool compact;
  final bool square;
  final double focusElevation;
  final dynamic style;

  @override
  Widget build(BuildContext context) {
    return TButton(
      label: label,
      icon: icon,
      color: backgroundColor,
      onClick: onTap,
      enabled: enabled,
    );
  }
}
