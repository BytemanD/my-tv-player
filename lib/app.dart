import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/menu_controller.dart';
import 'package:luma_tv/controllers/message_controller.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/core/common/log.dart';
import 'package:luma_tv/core/common/preference.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'data/app_database.dart';
import 'data/media_repository.dart';
import 'data/scanner/media_scanner.dart';
import 'data/settings_service.dart';
import 'data/storage_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/home/home_screen.dart';
import 'widgets/button.dart';
import 'widgets/logo.dart';

class LumaApp extends StatefulWidget {
  const LumaApp({super.key});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  late AppController appController;
  late ThemeController themeController;
  late AppMenuController menuController;

  bool initializing = true;

  Object? _error;
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    logger.i('booting ...');
    final prefs = await loadSharedPreferences();

    final settingService = SettingsService(prefs);
    final database = AppDatabase();
    final repository = MediaRepository(database);
    final storage = StorageService();
    final scanner = MediaScanner();

    appController = AppController(
      settings: settingService,
      storage: storage,
      scanner: scanner,
      database: database,
      repository: repository,
    );
    themeController = ThemeController(settingService);
    await themeController.load();

    menuController = AppMenuController();

    setState(() => _error = null);
    try {
      await appController.initialize();
      if (!mounted) {
        return;
      }
      setState(() => {});
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
    initializing = false;
    logger.i('boot success ...');
    setState(() => {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.i('build ...');
    if (initializing) {
      return _BootstrapFrame(error: _error, onRetry: _boot);
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appController),
        ChangeNotifierProvider(create: (_) => themeController),
        ChangeNotifierProvider(create: (_) => menuController),
      ],
      child: const _LumaMaterialApp(),
    );
  }
}

class _LumaMaterialApp extends StatelessWidget {
  const _LumaMaterialApp();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    ThemeData theme = context.select(
      (ThemeController c) => c.appTheme.themeData,
    );

    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: theme,
      builder: Dpad.wrap(
        theme: const DpadThemeData(
          effects: [DpadScaleEffect(scale: 1.08), DpadGlowEffect()],
          scrollPadding: 48,
        ),
        onBack: () {
          return false;
        },
        onMenu: () {},
        debugOverlay: false,
      ),
      home: controller.settings.onboardingComplete
          ? const MainShell(child: HomeScreen())
          : const OnboardingScreen(),
    );
  }
}

class _BootstrapFrame extends StatelessWidget {
  const _BootstrapFrame({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Container(
          color: const Color(0xFF07080B),
          child: Center(
            child: error == null
                ? const _SplashBody()
                : _ErrorContent(error: error!, onRetry: onRetry),
          ),
        ),
      ),
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 46),
          const SizedBox(height: 22),
          Text(
            '启动失败',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 28),
          TvButton(label: '重试', icon: Icons.refresh_rounded, onTap: onRetry),
        ],
      ),
    );
  }
}

class _SplashBody extends StatelessWidget {
  const _SplashBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LumaLogo(fontSize: 34, markSize: 52),
        const SizedBox(height: 26),
        SizedBox(
          width: 150,
          child: LinearProgressIndicator(
            minHeight: 2,
            color: const Color(0xFFE9C57E),
          ),
        ),
        const SizedBox(height: 18),
        const Text('正在整理你的影院…', style: TextStyle(fontSize: 12.5)),
      ],
    );
  }
}
