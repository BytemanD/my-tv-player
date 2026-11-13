import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// 已弃用：所有 TV 焦点交互直接使用 dpad 包的原生组件，
/// 请直接引用 `package:dpad/dpad.dart`，使用 `DpadFocusable`、`DpadRegion` 等。
///
/// 此文件保留的 Tv* 类全部内部基于 [DpadFocusable] 实现，
/// 获得 beam 遍历、焦点记忆、按键/长按、飞行高亮等 TV 原生导航能力。
export 'package:dpad/dpad.dart'
    show
        Dpad,
        DpadController,
        DpadFocusable,
        DpadFocusState,
        DpadGlowEffect,
        DpadHighlight,
        DpadRegion,
        DpadScaleEffect,
        DpadThemeData;

/// 兼容旧版 API 的焦点包装器。内部基于 [DpadFocusable]，
/// builder 签名为 (context, focused) 以保持与旧代码兼容。
/// 如果提供了 [child]，则直接显示 child（忽略 builder）。
class TvFocusable extends StatelessWidget {
  const TvFocusable({
    super.key,
    this.builder,
    this.child,
    this.onTap,
    this.autofocus = false,
    this.enabled = true,
    this.scale = 1.0,
    this.ensureVisible = true,
    this.onFocusChange,
  });

  final Widget Function(BuildContext context, bool focused)? builder;
  final Widget? child;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool enabled;
  final double scale;
  final bool ensureVisible;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      // autofocus: autofocus,
      onSelect: enabled ? onTap : null,
      child: const SizedBox.shrink(),
      builder: (context, state, _) {
        final focused = state.focused;
        if (ensureVisible && focused) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              Dpad.of(context).ensureVisible();
            } catch (_) {
              Scrollable.ensureVisible(
                context,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: 0.5,
              );
            }
          });
        }
        onFocusChange?.call(focused);
        final content = builder != null ? builder!(context, focused) : child!;
        return AnimatedScale(
          scale: focused ? scale : 1.0,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutCubic,
          child: content,
        );
      },
    );
  }
}

enum TvButtonStyle { filled, outline, ghost }

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
  final double focusElevation;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: TvFocusable(
        // autofocus: autofocus,
        onTap: onTap,
        scale: 1.08,
        builder: (context, focused) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: focused
                  ? Theme.of(context).colorScheme.primary
                  : selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceBright,
              shape: BoxShape.circle,
              border: Border.all(
                color: focused
                    ? Theme.of(context).colorScheme.primary
                    : selected
                    ? Theme.of(context).colorScheme.primaryFixedDim
                    : Theme.of(context).colorScheme.surfaceBright,
              ),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: focused
                  ? Theme.of(context).colorScheme.onPrimary
                  : selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceBright,
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
      // autofocus: autofocus,
      onTap: onTap,
      scale: 1.03,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : focused
                ? Theme.of(context).colorScheme.secondaryFixedDim
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: selected || focused
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
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
                      ? Theme.of(context).colorScheme.onPrimary
                      : focused
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : focused
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
                  ? Theme.of(context).colorScheme.primary
                  : value
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
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
                        // color: Theme.of(context).colorScheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
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
                      ? Theme.of(context).colorScheme.primaryFixedDim
                      : value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(100),
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
                      color: value
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.secondary,
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
