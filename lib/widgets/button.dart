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
