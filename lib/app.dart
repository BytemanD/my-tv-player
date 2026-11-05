import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/app_controller.dart';
import 'core/formatters.dart';
import 'core/theme.dart';
import 'data/app_database.dart';
import 'data/media_repository.dart';
import 'data/scanner/media_scanner.dart';
import 'data/settings_service.dart';
import 'data/storage_service.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/main_shell.dart';
import 'widgets/logo.dart';
import 'widgets/tv_focusable.dart';

/// Boots the app services, then swaps the splash for the real UI.
class LumaApp extends StatefulWidget {
  const LumaApp({super.key});

  @override
  State<LumaApp> createState() => _LumaAppState();
}

class _LumaAppState extends State<LumaApp> {
  AppController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    setState(() => _error = null);
    try {
      final settings = await SettingsService.load();
      LumaColors.apply(
        settings.themeId,
        settings.themeMode == 'light' ? Brightness.light : Brightness.dark,
      );
      final database = AppDatabase();
      final repository = MediaRepository(database);
      final controller = AppController(
        database: database,
        repository: repository,
        settings: settings,
        storage: StorageService(),
        scanner: MediaScanner(),
      );
      await controller.initialize();
      if (!mounted) {
        await controller.close();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _BootstrapFrame(error: _error, onRetry: _boot);
    }
    return ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const _LumaMaterialApp(),
    );
  }
}

class _LumaMaterialApp extends StatelessWidget {
  const _LumaMaterialApp();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      theme: LumaTheme.build(),
      home: controller.settings.onboardingComplete
          ? const MainShell()
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
      theme: LumaTheme.build(),
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.15),
              radius: 1.1,
              colors: [Color(0xFF12141A), LumaColors.background],
            ),
          ),
          child: Center(
            child: error == null
                ? const _SplashBody()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 46,
                          color: LumaColors.danger,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          '启动失败',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: LumaColors.text,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cleanError(error!),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            color: LumaColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TvButton(
                          label: '重试',
                          icon: Icons.refresh_rounded,
                          autofocus: true,
                          onTap: onRetry,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
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
            backgroundColor: LumaColors.lineSoft,
            color: LumaColors.accent,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '正在整理你的影院…',
          style: TextStyle(fontSize: 12.5, color: LumaColors.textMuted),
        ),
      ],
    );
  }
}
