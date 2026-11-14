import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/controllers/message_controller.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/data/library_source.dart';
import 'package:luma_tv/data/settings_service.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/card.dart';
import 'package:luma_tv/widgets/dialog.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/selector.dart';
import 'package:luma_tv/widgets/sheet.dart';
import 'package:luma_tv/widgets/space.dart';
import 'package:luma_tv/widgets/switch.dart';
import 'package:luma_tv/widgets/text.dart';
import 'package:provider/provider.dart';

class TvUI extends StatelessWidget {
  const TvUI({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return TSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TH4("主题"),
          TSubTitle('选择整体气质，后续会陆续上线更多主题'),
          TDivider(height: 8),
          TSpace([
            for (final option in themeController.getThemes())
              TCard(
                TSpace(
                  [
                    TH4(
                      option.name,
                      color: themeController.appTheme.id == option.id
                          ? Theme.of(context).colorScheme.secondary
                          : null,
                    ),
                    TSubTitle(
                      option.hint,
                      color: themeController.appTheme.id == option.id
                          ? Colors.white
                          : null,
                    ),
                  ],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                ),
                selected: themeController.appTheme.id == option.id,
                onClick: () async {
                  // controller.setTheme(option.id)
                  await themeController.setTheme(option.id);
                },
              ),
          ]),
          TLine(),
          TSwitch(
            (dark) async {
              await themeController.setDark(dark);
            },
            value: themeController.appTheme.dark,
            title: "深色",
            subTitle: "启用深色模式",
          ),
        ],
      ),
    );
  }
}

class TvMeta extends StatelessWidget {
  final AppController controller;

  const TvMeta(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      Column(
        children: [
          Row(
            children: [
              TSpace(
                [TH4("TMDB API Key"), TSubTitle('主刮削源，未配置时无法获取海报与元数据')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),

              TChip(
                controller.hasTmdbKey ? '已配置' : '未配置',
                boderWidth: 0,
                color: controller.hasTmdbKey
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          TLine(),
          Row(
            children: [
              TSpace(
                [TH4("豆瓣 API Key（备用）"), TSubTitle('TMDB 找不到时自动尝试豆瓣')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              TChip(
                controller.hasDoubanKey ? '已配置' : '未配置',
                boderWidth: 0,
                color: controller.hasTmdbKey
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          TLine(),
          Row(
            children: [
              TSpace(
                [TH4("元数据语言"), TSubTitle('影响 TMDB 返回的标题、简介与剧集信息')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              TSelect(
                [for (final x in TmdbLanguage.values) x.label],
                onChanged: (i) => {
                  controller.setLanguage(TmdbLanguage.values[i]),
                },
              ),
            ],
          ),
          TLine(),
          Row(
            children: [
              if (controller.scraping)
                TSpace(
                  [TH4("正在刮削"), TSubTitle('NFO 与本地海报会优先于网络刮削结果。')],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                )
              else
                TSpace(
                  [TH4("状态"), TSubTitle('NFO 与本地海报会优先于网络刮削结果。')],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                ),

              TButton(
                label: "重新刮削全部",
                icon: Icons.radar_rounded,
                onClick: () => {controller.scrapeAll()},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TvScan extends StatelessWidget {
  final AppController controller;

  const TvScan(this.controller, {super.key});
  static String _formatMoment(DateTime moment) {
    final now = DateTime.now();
    final diff = now.difference(moment);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${moment.year}/${moment.month.toString().padLeft(2, '0')}/${moment.day.toString().padLeft(2, '0')} '
        '${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context);
    return TSheet(
      Column(
        children: [
          TSwitch(
            controller.setAutoScanOnStart,
            value: controller.settings.autoScanOnStart,
            title: "启动时自动扫描",
            subTitle: "打开应用后检查所有媒体目录是否有新文件",
          ),
          TLine(),

          TSwitch(
            controller.setAutoScrape,
            value: controller.settings.autoScrape,
            title: "扫描后自动刮削",
            subTitle: "发现新视频后自动向 TMDB 获取海报与元数据",
          ),
          TLine(),
          Row(
            children: [
              if (controller.scanning)
                TSpace(
                  [
                    TH4('正在扫描「${controller.scanSourceName}」'),
                    TSubTitle(
                      '已发现 ${controller.scanFound} 个视频 · ${controller.scanCurrent}',
                    ),
                  ],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                )
              else
                TSpace(
                  [
                    TH4("状态"),
                    TSubTitle(
                      controller.lastScanAt == null
                          ? '尚未扫描过媒体库'
                          : '上次扫描：${_formatMoment(controller.lastScanAt!)}',
                    ),
                  ],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                ),

              TButton(
                label: "立即扫描",
                icon: Icons.auto_awesome_rounded,
                onClick: () async {
                  await controller.scanAll();
                  // scaffoldMessengerKey.currentState?.showSnackBar(
                  //   const SnackBar(content: Text('全局提示')),
                  // );

                  messageController.success("扫描完成");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TvPlayer extends StatelessWidget {
  final AppController controller;

  const TvPlayer(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      Column(
        children: [
          TSwitch(
            controller.setAutoLoadSubtitles,
            value: controller.settings.autoLoadSubtitles,
            title: "自动加载同名字幕",
            subTitle: "播放时自动寻找与视频同名的 .srt / .ass 字幕",
          ),
          TLine(),
          TSwitch(
            controller.setAutoPlayNext,
            value: controller.settings.autoPlayNext,
            title: "自动播放下一集",
            subTitle: "当前剧集结束后继续播放下一集",
          ),
          TLine(),
          TSwitch(
            controller.setRememberPlaybackSpeed,
            value: controller.settings.rememberPlaybackSpeed,
            title: "记住播放速度",
            subTitle: "打开后，下一个视频将沿用上一次切换的播放速度",
          ),
        ],
      ),
    );
  }
}

class TvMediaSource extends StatelessWidget {
  final AppController controller;

  const TvMediaSource(this.controller, {super.key});

  Future<void> showAddSourceDialog(
    BuildContext context,
    AppController controller,
  ) async {
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FolderPickerDialog(controller: controller),
    );
    if (path == null) return;
    await controller.addSourceFromPath(path);
  }

  Future<void> _removeSource(
    BuildContext context,
    AppController controller,
    LibrarySource source,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: '移除媒体目录？',
        message: '将移除「${source.name}」及其中的全部影片记录，不会删除硬盘上的文件。',
        confirmLabel: '移除',
        destructive: true,
      ),
    );
    if (confirmed == true) {
      await controller.removeSource(source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = controller.hasStorageAccess;
    return TSheet(
      Column(
        children: [
          Row(
            children: [
              Icon(
                granted
                    ? Icons.verified_user_outlined
                    : Icons.lock_outline_rounded,
                size: 20,
                color: granted
                    ? Theme.of(context).extension<SemanticColors>()?.success
                    : Theme.of(context).extension<SemanticColors>()?.danger,
              ),
              TDivider(),
              TSpace(
                [
                  TH4(granted ? '已获得所有文件访问权限' : '尚未授予所有文件访问权限'),
                  TSubTitle(
                    granted
                        ? '可以读取本地存储与外接 USB 磁盘中的视频'
                        : 'Android TV 读取外接磁盘需要此权限',
                  ),
                ],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              TButton(
                label: granted ? '重新检查' : '去授权',
                onClick: () async {
                  if (!granted) {
                    await controller.requestStorageAccess();
                  } else {
                    controller.refreshAccessState();
                    controller.showNotice('文件访问权限正常');
                  }
                },
              ),
            ],
          ),
          TLine(),
          if (controller.sources.isEmpty) ...[
            TH4(
              "还没有添加媒体目录",
              color: Theme.of(context).extension<SemanticColors>()?.danger,
            ),
            TLine(),
          ] else ...[
            for (var i = 0; i < controller.sources.length; i++) ...[
              Row(
                children: [
                  Icon(Icons.folder_outlined),
                  TDivider(),
                  Expanded(
                    child: TSpace(
                      [
                        TH4(controller.sources[i].name),
                        TSubTitle(controller.sources[i].path),
                      ],
                      vertical: true,
                      alighment: WrapCrossAlignment.start,
                    ),
                  ),
                  TButton(
                    icon: Icons.remove_circle_outline_rounded,
                    color: Theme.of(context)
                        .extension<SemanticColors>()
                        ?.danger,
                    onClick: () => _removeSource(
                      context,
                      controller,
                      controller.sources[i],
                    ),
                  ),
                ],
              ),
              const TLine(indent: 18),
            ],
          ],
          Row(
            children: [
              Expanded(
                child: TButton(
                  label: "添加目录",
                  icon: Icons.add_rounded,
                  onClick: () => showAddSourceDialog(context, controller),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TvData extends StatelessWidget {
  final AppController controller;

  const TvData(this.controller, {super.key});

  Future<void> showAddSourceDialog(
    BuildContext context,
    AppController controller,
  ) async {
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => FolderPickerDialog(controller: controller),
    );
    if (path == null) return;
    await controller.addSourceFromPath(path);
  }

  Future<void> _confirmClear(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ConfirmDialog(
        title: '清空媒体库？',
        message: '所有影片、剧集与播放进度都会被移除。硬盘上的视频文件不会受影响。',
        confirmLabel: '清空媒体库',
        destructive: true,
      ),
    );
    if (confirmed == true) {
      await controller.clearLibrary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TSheet(
      Column(
        children: [
          Row(
            children: [
              TSpace(
                [TH4('清空媒体库'), TSubTitle("移除所有影片、剧集与播放进度，不会删除硬盘上的视频文件")],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              TButton(
                label: '清空',
                icon: Icons.delete_outline_rounded,
                color: Theme.of(context).extension<SemanticColors>()?.danger,
                onClick: () {
                  _confirmClear(context, controller);
                },
              ),
            ],
          ),
          TLine(),
          Row(
            children: [
              TSpace(
                [TH4('引导'), TSubTitle("进入应用欢迎页")],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              TButton(
                label: '进入',
                // icon: Icons.mediation,
                onClick: () {
                  controller.notCompleteOnboarding();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
