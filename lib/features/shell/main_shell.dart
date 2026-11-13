import 'package:flutter/material.dart';
import 'package:luma_tv/core/common/log.dart';
import 'package:luma_tv/widgets/navigation.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/tv_focusable.dart';

final node1 = FocusNode();

final items = [
  NavRailItem(
    label: '首页',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  NavRailItem(
    label: '电影',
    icon: Icons.movie_outlined,
    selectedIcon: Icons.movie_rounded,
  ),
  NavRailItem(
    label: '剧集',
    icon: Icons.tv_outlined,
    selectedIcon: Icons.tv_rounded,
  ),
  NavRailItem(
    label: '媒体库',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
  ),
  NavRailItem(
    label: '设置',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    LibraryScreen(kind: LibraryKind.movies),
    LibraryScreen(kind: LibraryKind.series),
    LibraryScreen(kind: LibraryKind.all),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final controller = context.read<AppController>();
      controller.refreshAccessState();
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
    Dpad.of(context).requestFocus(items[index].focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 左侧导航栏（NavRail）
              DpadRegion(
                memoryKey: "_NavRail",
                // child: _NavRail(selectedIndex: _index, onSelect: _select),
                child: NavRail(items, selectedIndex: _index, onSelect: _select),
              ),
              Expanded(
                child: HomeNavigation(
                  goToTab: _select,
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ),
              // 右侧内容区域
            ],
          ),
          // 底部通知条
          Positioned(
            left: 136,
            right: 28,
            bottom: 22,
            child: IgnorePointer(
              ignoring: controller.notice == null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: controller.notice == null
                    ? const SizedBox.shrink()
                    : Align(
                        key: ValueKey(controller.notice),
                        alignment: Alignment.centerRight,
                        child: _NoticeBar(
                          message: controller.notice!,
                          isError: controller.noticeIsError,
                          onDismiss: controller.dismissNotice,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRail extends StatelessWidget {
  const _NavRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final void Function(int tab) onSelect;

  @override
  Widget build(BuildContext context) {
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
          _NavItem(
            focusNode: FocusNode(),
            label: '首页',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            route: '/',
            selected: selectedIndex == 0,
            onSelect: () => onSelect(0),
          ),
          const SizedBox(height: 12),
          _NavItem(
            focusNode: FocusNode(),
            label: '电影',
            icon: Icons.movie_outlined,
            selectedIcon: Icons.movie_rounded,
            route: '/library/movies',
            selected: selectedIndex == 1,
            onSelect: () => onSelect(1),
          ),
          const SizedBox(height: 12),
          _NavItem(
            focusNode: FocusNode(),
            label: '剧集',
            icon: Icons.tv_outlined,
            selectedIcon: Icons.tv_rounded,
            route: '/library/series',
            selected: selectedIndex == 2,
            onSelect: () => onSelect(2),
          ),
          const SizedBox(height: 12),
          _NavItem(
            focusNode: FocusNode(),
            label: '媒体库',
            icon: Icons.video_library_outlined,
            selectedIcon: Icons.video_library_rounded,
            route: '/library/all',
            selected: selectedIndex == 3,
            onSelect: () => onSelect(3),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          _NavItem(
            focusNode: FocusNode(),
            label: '设置',
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            route: '/settings',
            selected: selectedIndex == 4,
            onSelect: () => onSelect(4),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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

class _NoticeBar extends StatelessWidget {
  const _NoticeBar({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? const Color(0xFFE07373) : const Color(0xFFE9C57E);
    return Container(
      constraints: const BoxConstraints(maxWidth: 620),
      padding: const EdgeInsets.fromLTRB(18, 13, 12, 13),
      decoration: BoxDecoration(
        color: const Color(0xF214161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 11),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFFF4F1EA),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TvIconButton(
            icon: Icons.close_rounded,
            size: 30,
            iconSize: 15,
            onTap: onDismiss,
          ),
        ],
      ),
    );
  }
}
