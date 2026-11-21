import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/menu_controller.dart';
import 'package:luma_tv/widgets/logo.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:provider/provider.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<StatefulWidget> createState() => _AppHeader();
}

class _AppHeader extends State<AppHeader> {
  int focusIndex = 0;

  @override
  Widget build(BuildContext context) {
    final menuController = context.read<AppMenuController>();
    int menuIndex = context.select<AppMenuController, int>(
      (controller) => controller.index,
    );
    bool setFocus = (focusIndex != menuIndex);
    focusIndex = menuIndex;
    final widgets = menuController.menus.asMap().entries.map((entry) {
      final selected = entry.key == menuIndex;
      final item = LButton.filled(
        label: entry.value.label,
        frontColor: Theme.of(context).colorScheme.secondary,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        icon: selected ? entry.value.selectedIcon : entry.value.icon,
        // selectedIcon: entry.value.selectedIcon,
        // route: '/',
        onClick: () => {
          menuController.onSelect(entry.key),
          focusIndex = menuIndex,
        },
        // selected: entry.key == menuIndex,
        // onSelect: () => {menuController.onSelect(entry.key)},
        focuse: ((entry.key == menuIndex) && setFocus) ? true : null,
      );
      return item;
    }).toList();

    return Row(
      children: [
        LumaLogo(),
        const SizedBox(width: 100),
        // NavRail(),
        ...widgets.take(widgets.length - 1),
        const Spacer(),
        widgets[widgets.length - 1],
      ],
    );
  }
}
