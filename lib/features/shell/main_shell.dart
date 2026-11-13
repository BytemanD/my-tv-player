import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/menu_controller.dart';
import 'package:luma_tv/controllers/message_controller.dart';
import 'package:luma_tv/widgets/navigation.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../home/home_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/tv_focusable.dart';

final node1 = FocusNode();

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
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

  @override
  Widget build(BuildContext context) {
    final menuController = context.watch<AppMenuController>();
    messageController.init(context);

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // 左侧导航栏（NavRail）
              DpadRegion(child: NavRail()),
              Expanded(
                child: HomeNavigation(
                  goToTab: menuController.onSelect,
                  child: IndexedStack(
                    index: menuController.index,
                    children: _pages,
                  ),
                ),
              ),
              // 右侧内容区域
            ],
          ),
        ],
      ),
    );
  }
}
