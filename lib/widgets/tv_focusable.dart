import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

typedef FocusedWidgetBuilder = Widget Function(
  BuildContext context,
  bool focused,
);

/// 焦点时统一的 elevation 阴影：深色投影 + 主题色光晕。
///
/// [elevation] 为 0 或负数时返回 null，即不显示焦点阴影。
List<BoxShadow>? tvFocusShadow(Color glowColor, double elevation) {
  if (elevation <= 0) return null;
  return [
    // 深色投影，制造“浮起来”的 elevation 效果。
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.42),
      blurRadius: elevation * 2,
      spreadRadius: elevation * 0.05,
      offset: Offset(0, elevation * 0.6),
    ),
    // 主题色光晕，让焦点在深色 TV 界面上更明显。
    BoxShadow(
      color: glowColor.withValues(alpha: 0.28),
      blurRadius: elevation * 3,
      spreadRadius: elevation * 0.12,
    ),
  ];
}

class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.builder,
    this.onTap,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.scale = 1.0,
    this.ensureVisible = true,
    this.onFocusChange,
  });

  final FocusedWidgetBuilder builder;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final double scale;
  final bool ensureVisible;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _node;
  bool _ownsNode = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node = widget.focusNode ?? FocusNode(debugLabel: 'TvFocusable');
    _ownsNode = widget.focusNode == null;
  }

  @override
  void didUpdateWidget(covariant TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsNode) _node.dispose();
      _node = widget.focusNode ?? FocusNode(debugLabel: 'TvFocusable');
      _ownsNode = widget.focusNode == null;
    }
  }

  @override
  void dispose() {
    if (_ownsNode) _node.dispose();
    super.dispose();
  }

  void _onFocus(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
    widget.onFocusChange?.call(value);
    if (value && widget.ensureVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focused) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _focused ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
        child: widget.builder(context, _focused),
      ),
    );

    if (!widget.enabled) return content;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: FocusableActionDetector(
        autofocus: widget.autofocus,
        focusNode: _node,
        onFocusChange: _onFocus,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: content,
      ),
    );
  }
}

enum TvButtonStyle { filled, outline, ghost }

class TvButton extends StatelessWidget {
  const TvButton({
    super.key,
    this.label = '',
    this.icon,
    this.onTap,
    this.style = TvButtonStyle.filled,
    this.backgroundColor,
    this.autofocus = false,
    this.enabled = true,
    this.compact = false,
    this.square = false,
    this.focusElevation = 10,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final TvButtonStyle style;
  final Color? backgroundColor;
  final bool autofocus;
  final bool enabled;
  final bool compact;
  final bool square;

  /// 获得遥控器焦点时的阴影强度。设为 0 可关闭焦点阴影。
  final double focusElevation;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      enabled: enabled,
      onTap: onTap,
      scale: 1.04,
      builder: (context, focused) {
        final hasCustomColor = backgroundColor != null;
        final foreground = switch (style) {
          TvButtonStyle.filled =>
            hasCustomColor ? Colors.white : LumaColors.onPrimary,
          TvButtonStyle.outline =>
            focused ? LumaColors.onPrimary : LumaColors.textOnSurface,
          TvButtonStyle.ghost => LumaColors.textOnSurface,
        };
        final background = switch (style) {
          TvButtonStyle.filled => backgroundColor ?? LumaColors.primary,
          TvButtonStyle.outline =>
            focused ? LumaColors.primary : Colors.transparent,
          TvButtonStyle.ghost =>
            focused ? LumaColors.surfaceHigh : Colors.transparent,
        };
        final borderColor = switch (style) {
          TvButtonStyle.filled => Colors.transparent,
          TvButtonStyle.outline =>
            focused ? LumaColors.primary : LumaColors.line,
          TvButtonStyle.ghost =>
            focused ? LumaColors.accentSoft : Colors.transparent,
        };
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: square && label.isEmpty
              ? BoxConstraints.tightFor(
                  width: compact ? 44.0 : 52.0,
                  height: compact ? 44.0 : 52.0,
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: square && label.isEmpty
                ? 0
                : compact
                ? 18
                : 26,
            vertical: square && label.isEmpty
                ? 0
                : compact
                ? 11
                : 14,
          ),
          decoration: BoxDecoration(
            color: background,
            shape: square && label.isEmpty
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: square && label.isEmpty
                ? null
                : BorderRadius.circular(100),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: focused
                ? tvFocusShadow(
                    backgroundColor ?? LumaColors.primary,
                    focusElevation,
                  )
                : null,
          ),
          child: square && label.isEmpty
              ? Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: compact ? 18 : 20, color: foreground),
                      ],
                    ],
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: compact ? 18 : 20, color: foreground),
                      const SizedBox(width: 9),
                    ],
                    if (label.isNotEmpty)
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: compact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          color: enabled ? foreground : LumaColors.textMuted,
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class TvIconButton extends StatelessWidget {
  const TvIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.autofocus = false,
    this.size = 44,
    this.iconSize = 20,
    this.selected = false,
    this.focusElevation = 10,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool autofocus;
  final double size;
  final double iconSize;
  final bool selected;

  /// 获得遥控器焦点时的阴影强度。设为 0 可关闭焦点阴影。
  final double focusElevation;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: TvFocusable(
        autofocus: autofocus,
        onTap: onTap,
        scale: 1.08,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: focused
                  ? LumaColors.primary
                  : selected
                  ? LumaColors.primarySoft
                  : LumaColors.surfaceHigh,
              shape: BoxShape.circle,
              border: Border.all(
                color: focused
                    ? LumaColors.primary
                    : selected
                    ? LumaColors.primaryDeep
                    : LumaColors.line,
              ),
              boxShadow: focused
                  ? tvFocusShadow(LumaColors.primary, focusElevation)
                  : null,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: focused
                  ? LumaColors.onPrimary
                  : selected
                  ? LumaColors.primary
                  : LumaColors.textDim,
            ),
          );
        },
      ),
    );
  }
}

class TvChip extends StatelessWidget {
  const TvChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
    this.autofocus = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      scale: 1.03,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? LumaColors.primary
                : focused
                ? LumaColors.accentSoft
                : LumaColors.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected
                  ? LumaColors.primary
                  : focused
                  ? LumaColors.accent
                  : LumaColors.primarySoft,
              width: selected || focused ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? LumaColors.onPrimary
                      : focused
                      ? LumaColors.accent
                      : LumaColors.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? LumaColors.onPrimary
                      : focused
                      ? LumaColors.accent
                      : LumaColors.textDim,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Standalone toggle switch (off = light, on = dark). Use when the host row
/// already carries its own label/description.
class TvSwitchToggle extends StatelessWidget {
  const TvSwitchToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.focusElevation = 10,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;

  /// 获得遥控器焦点时的阴影强度。设为 0 可关闭焦点阴影。
  final double focusElevation;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label ?? (value ? '深色' : '浅色'),
      child: TvFocusable(
        onTap: () => onChanged(!value),
        scale: 1.1,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 54,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: focused
                  ? LumaColors.primaryDeep
                  : value
                  ? LumaColors.primary
                  : LumaColors.line,
              borderRadius: BorderRadius.circular(100),
              boxShadow: focused
                  ? tvFocusShadow(LumaColors.primary, focusElevation)
                  : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? LumaColors.onPrimary : LumaColors.textDim,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TvSwitch extends StatelessWidget {
  const TvSwitch({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.focusElevation = 10,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// 获得遥控器焦点时的阴影强度。设为 0 可关闭焦点阴影。
  final double focusElevation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: LumaColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 只有开关本身可聚焦，与媒体来源区的按钮焦点保持一致。
          TvFocusable(
            onTap: () => onChanged(!value),
            scale: 1.1,
            builder: (context, focused) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 46,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: focused
                      ? LumaColors.primaryDeep
                      : value
                      ? LumaColors.primary
                      : LumaColors.line,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: focused
                      ? tvFocusShadow(LumaColors.primary, focusElevation)
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: value ? LumaColors.onPrimary : LumaColors.textDim,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
