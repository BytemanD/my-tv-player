import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/tv_focusable.dart';
import '../../widgets/nav_rail.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

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
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              NavRail(
                selectedIndex: _index,
                onSelect: _select,
                onLogoFocus: () => _select(0),
              ),
              Expanded(
                child: HomeNavigation(
                  goToTab: _select,
                  child: IndexedStack(index: _index, children: _pages),
                ),
              ),
            ],
          ),
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
    final accent = isError ? LumaColors.danger : LumaColors.primary;
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
                color: LumaColors.text,
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
