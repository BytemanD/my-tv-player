import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'logo.dart';
import 'tv_focusable.dart';

class NavDestination {
  const NavDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const navDestinations = [
  NavDestination('首页', Icons.home_outlined, Icons.home_rounded),
  NavDestination('电影', Icons.movie_outlined, Icons.movie_rounded),
  NavDestination('剧集', Icons.tv_outlined, Icons.tv_rounded),
  NavDestination(
    '媒体库',
    Icons.video_library_outlined,
    Icons.video_library_rounded,
  ),
  NavDestination('设置', Icons.settings_outlined, Icons.settings_rounded),
];

class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.onLogoFocus,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogoFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      decoration: BoxDecoration(
        color: LumaColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(26),
        // border: Border.all(color: LumaColors.lineSoft),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          TvFocusable(
            onTap: onLogoFocus,
            scale: 1.05,
            ensureVisible: false,
            builder: (context, focused) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LumaMark(
                size: 34,
                color: focused ? Colors.white : LumaColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(width: 24, height: 1, color: LumaColors.lineSoft),
          const SizedBox(height: 14),
          for (var i = 0; i < navDestinations.length; i++) ...[
            if (i == navDestinations.length - 1)
              const Spacer()
            else
              const SizedBox(height: 2),
            _NavItem(
              destination: navDestinations[i],
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
          ],
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      scale: 1.04,
      ensureVisible: false,
      builder: (context, focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          padding: const EdgeInsets.symmetric(vertical: 20),
          width: 80,
          decoration: BoxDecoration(
            color: selected
                ? LumaColors.primary
                : focused
                ? LumaColors.surfaceHigh
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 24,
                color: selected
                    ? LumaColors.accent
                    : focused
                    ? LumaColors.accentSoft
                    : LumaColors.textMutedOnSurface,
              ),
              const SizedBox(height: 6),
              Text(
                destination.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                  color: selected
                      ? LumaColors.accent
                      : focused
                      ? LumaColors.accent
                      : LumaColors.textMutedOnSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
