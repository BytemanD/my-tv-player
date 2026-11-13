import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class NavRail extends StatelessWidget {
  final List<NavRailItem> items;
  final int selectedIndex;
  final void Function(int tab) onSelect;

  const NavRail(
    this.items, {
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = items
        .asMap()
        .entries
        .map(
          (entry) => NavItem(
            focusNode: entry.value.focusNode,
            label: entry.value.label,
            icon: entry.value.icon,
            selectedIcon: entry.value.selectedIcon,
            route: '/',
            selected: selectedIndex == entry.key,
            onSelect: () => onSelect(entry.key),
          ),
        )
        .toList();
    return Container(
      width: 104,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          for (NavItem item in widgets) ...[
            Focus(focusNode: item.focusNode, child: item),
          ],
          // ...widgets,
          // _NavItem(
          //   focusNode: FocusNode(),
          //   label: '首页',
          //   icon: Icons.home_outlined,
          //   selectedIcon: Icons.home_rounded,
          //   route: '/',
          //   selected: selectedIndex == 0,
          //   onSelect: () => onSelect(0),
          // ),
          // const SizedBox(height: 12),
          // _NavItem(
          //   focusNode: FocusNode(),
          //   label: '电影',
          //   icon: Icons.movie_outlined,
          //   selectedIcon: Icons.movie_rounded,
          //   route: '/library/movies',
          //   selected: selectedIndex == 1,
          //   onSelect: () => onSelect(1),
          // ),
          // const SizedBox(height: 12),
          // _NavItem(
          //   focusNode: FocusNode(),
          //   label: '剧集',
          //   icon: Icons.tv_outlined,
          //   selectedIcon: Icons.tv_rounded,
          //   route: '/library/series',
          //   selected: selectedIndex == 2,
          //   onSelect: () => onSelect(2),
          // ),
          // const SizedBox(height: 12),
          // _NavItem(
          //   focusNode: FocusNode(),
          //   label: '媒体库',
          //   icon: Icons.video_library_outlined,
          //   selectedIcon: Icons.video_library_rounded,
          //   route: '/library/all',
          //   selected: selectedIndex == 3,
          //   onSelect: () => onSelect(3),
          // ),
          // const Spacer(),
          // const SizedBox(height: 12),
          // _NavItem(
          //   focusNode: FocusNode(),
          //   label: '设置',
          //   icon: Icons.settings_outlined,
          //   selectedIcon: Icons.settings_rounded,
          //   route: '/settings',
          //   selected: selectedIndex == 4,
          //   onSelect: () => onSelect(4),
          // ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class NavRailItem {
  final focusNode = FocusNode();
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  new({required this.label, required this.icon, required this.selectedIcon});
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.selected,
    required this.onSelect,
  });

  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      onSelect: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 18),
        width: 72,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              size: 24,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
