import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/menu_controller.dart';
import 'package:provider/provider.dart';

class NavRail extends StatelessWidget {
  const NavRail({super.key});

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<AppMenuController>();
    final widgets = menuController.menus.asMap().entries.map((entry) {
      final item = Focus(
        focusNode: FocusNode(),
        child: _NavItem(
          label: entry.value.label,
          icon: entry.value.icon,
          selectedIcon: entry.value.selectedIcon,
          route: '/',
          selected: entry.key == menuController.index,
          onSelect: () => {menuController.onSelect(entry.key)},
        ),
      );
      if (entry.key == menuController.index) {
        item.focusNode?.requestFocus();
      }
      return Focus(focusNode: FocusNode(), child: item);
    }).toList();

    return Container(
      width: 104,
      margin: const EdgeInsets.fromLTRB(18, 18, 0, 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          ...widgets.take(widgets.length - 1),
          const Spacer(),
          widgets.last,
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.selected,
    required this.onSelect,
  });

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
      // autofocus: true,
      // focusNode: focusNode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 18),
        width: 72,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHigh,
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
