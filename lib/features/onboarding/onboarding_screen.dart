import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/tv_focusable.dart';
import '../sources/add_source_dialog.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().refreshAccessState();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppController>().refreshAccessState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _OnboardingBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 980;
                final content = SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 74 : 40,
                    wide ? 54 : 34,
                    wide ? 74 : 40,
                    wide ? 46 : 34,
                  ),
                  child: wide
                      ? Row(
                          children: [
                            Expanded(
                              flex: 10,
                              child: _CopyColumn(controller: controller),
                            ),
                            const SizedBox(width: 54),
                            const Expanded(flex: 8, child: _PosterStudy()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CopyColumn(controller: controller),
                            const SizedBox(height: 34),
                            const Center(child: _PosterStudy(compact: true)),
                          ],
                        ),
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: content,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.5),
          radius: 1.25,
          colors: [Color(0xFF15130D), Color(0xFF0A0B0F), LumaColors.background],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -160,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LumaColors.accent.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -180,
            bottom: -220,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3C5A78).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyColumn extends StatelessWidget {
  const _CopyColumn({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final hasSources = controller.sources.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LumaLogo(fontSize: 20, markSize: 30),
        const SizedBox(height: 38),
        Text(
          '把影院，\n留在家里。',
          style: TextStyle(
            fontFamily: LumaTheme.displayFont,
            fontSize: 64,
            height: 1.02,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.4,
            color: LumaColors.text,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            '选择本地文件夹或外接 USB 磁盘，Luma 会递归扫描视频、识别电影与剧集，'
            '再从 TMDB 取回海报、评分与简介，整理成一面安静的海报墙。',
            style: TextStyle(
              fontSize: 15,
              height: 1.75,
              color: LumaColors.textDim,
            ),
          ),
        ),
        const SizedBox(height: 30),
        _Step(
          index: '01',
          title: '授予文件访问权限',
          detail: 'Android TV 需要“所有文件访问权限”才能读取外接磁盘',
          done: controller.hasStorageAccess,
        ),
        _Step(
          index: '02',
          title: '添加媒体目录',
          detail: '文件夹或整块磁盘都可以，支持多层子目录',
          done: hasSources,
        ),
        _Step(
          index: '03',
          title: '自动刮削与播放',
          detail: '同名 NFO 与字幕会被识别，播放进度自动保存',
          done: controller.entries.isNotEmpty,
          last: true,
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!controller.hasStorageAccess)
              TvButton(
                label: '授予文件访问权限',
                icon: Icons.lock_open_rounded,
                style: TvButtonStyle.outline,
                onTap: controller.requestStorageAccess,
              ),
            TvButton(
              label: hasSources ? '再添加一个目录' : '添加媒体目录',
              icon: Icons.folder_open_rounded,
              autofocus: true,
              onTap: () => showAddSourceDialog(context, controller),
            ),
            if (hasSources)
              TvButton(
                label: '进入 Luma',
                icon: Icons.arrow_forward_rounded,
                style: TvButtonStyle.filled,
                onTap: controller.completeOnboarding,
              )
            else
              TvButton(
                label: '先看看界面',
                style: TvButtonStyle.ghost,
                onTap: controller.completeOnboarding,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              controller.hasStorageAccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              size: 15,
              color: controller.hasStorageAccess
                  ? LumaColors.success
                  : LumaColors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              controller.hasStorageAccess
                  ? '文件访问权限已就绪'
                  : '稍后也可以在「设置 → 媒体来源」中授权',
              style: TextStyle(fontSize: 11.5, color: LumaColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.title,
    required this.detail,
    required this.done,
    this.last = false,
  });

  final String index;
  final String title;
  final String detail;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? LumaColors.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: done ? LumaColors.accent : LumaColors.line,
              ),
            ),
            child: Text(
              index,
              style: TextStyle(
                fontFamily: LumaTheme.displayFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: done ? LumaColors.accent : LumaColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: LumaColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: LumaColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterStudy extends StatelessWidget {
  const _PosterStudy({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 360.0 : 420.0;
    final height = compact ? 300.0 : 470.0;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: width * 0.02,
            top: height * 0.16,
            child: Transform.rotate(
              angle: -0.075,
              child: const _MockPoster(
                width: 152,
                height: 228,
                colors: [Color(0xFF1C2B38), Color(0xFF0E141B)],
              ),
            ),
          ),
          Positioned(
            right: width * 0.02,
            top: height * 0.10,
            child: Transform.rotate(
              angle: 0.085,
              child: const _MockPoster(
                width: 152,
                height: 228,
                colors: [Color(0xFF33271A), Color(0xFF151009)],
              ),
            ),
          ),
          Positioned(
            top: height * 0.24,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: LumaColors.accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 46,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: LumaColors.accent.withValues(alpha: 0.16),
                    blurRadius: 60,
                  ),
                ],
              ),
              child: const _MockPoster(
                width: 176,
                height: 264,
                colors: [Color(0xFF4A3A1E), Color(0xFF12100B)],
                label: 'LUMA',
              ),
            ),
          ),
          Positioned(
            bottom: height * 0.02,
            right: width * 0.06,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xE612141A),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: LumaColors.line),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: LumaColors.accent,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '自动识别 · 自动刮削',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 0.3,
                      color: LumaColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockPoster extends StatelessWidget {
  const _MockPoster({
    required this.width,
    required this.height,
    required this.colors,
    this.label,
  });

  final double width;
  final double height;
  final List<Color> colors;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -14,
            child: Icon(
              Icons.local_movies_outlined,
              size: width * 0.52,
              color: Colors.white.withValues(alpha: 0.035),
            ),
          ),
          Center(
            child: label == null
                ? Icon(
                    Icons.play_circle_outline_rounded,
                    size: 30,
                    color: Colors.white.withValues(alpha: 0.18),
                  )
                : LumaWordmark(
                    fontSize: 15,
                    letterSpacing: 3.4,
                    color: LumaColors.accent.withValues(alpha: 0.9),
                  ),
          ),
        ],
      ),
    );
  }
}
