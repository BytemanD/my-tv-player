import 'package:flutter/material.dart';

class MenuItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool end;

  new(
    this.id, {
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.end = false,
  });
}

final appMenus = [
  MenuItem(
    "home",
    label: '首页',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  MenuItem(
    "movie",
    label: '电影',
    icon: Icons.movie_outlined,
    selectedIcon: Icons.movie_rounded,
  ),
  MenuItem(
    "tv",
    label: '剧集',
    icon: Icons.tv_outlined,
    selectedIcon: Icons.tv_rounded,
  ),
  MenuItem(
    "labrary",
    label: '媒体库',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
  ),
  MenuItem(
    "settings",
    label: '设置',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    end: true,
  ),
];

class AppMenuController extends ChangeNotifier {
  int index = 0;
  List<MenuItem> get menus => appMenus;

  // new() {}

  void onSelect(int value) {
    index = value;
    notifyListeners();
  }
}
