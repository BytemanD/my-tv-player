import 'package:flutter/material.dart';
import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/controllers/message_controller.dart';
import 'package:luma_tv/controllers/theme_controller.dart';
import 'package:luma_tv/data/library_source.dart';
import 'package:luma_tv/data/settings_service.dart';
import 'package:luma_tv/widgets/card.dart';
import 'package:luma_tv/widgets/dialog.dart';
import 'package:luma_tv/widgets/luma_widgets/divider.dart';
import 'package:luma_tv/widgets/luma_widgets/button.dart';
import 'package:luma_tv/widgets/luma_widgets/chip.dart';
import 'package:luma_tv/widgets/luma_widgets/selector.dart';
import 'package:luma_tv/widgets/luma_widgets/switch.dart';
import 'package:luma_tv/widgets/luma_widgets/text.dart';
import 'package:luma_tv/widgets/luma_widgets/sheet.dart';
import 'package:luma_tv/widgets/luma_widgets/space.dart';
import 'package:provider/provider.dart';

class TvUI extends StatelessWidget {
  const TvUI({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.read<ThemeController>();
    return LSheet(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LH4("主题"),
          LSubTitle('选择整体气质，后续会陆续上线更多主题'),
          TDivider(height: 8),
          LSpace([
            for (final option in themeController.getThemes())
              TCard(
                LSpace(
                  [
                    LH4(
                      option.name,
                      color: themeController.appTheme.id == option.id
                          ? Theme.of(context).colorScheme.secondary
                          : null,
                    ),
                    LSubTitle(
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
                  await themeController.setTheme(option.id);
                },
              ),
          ]),
          Divider(thickness: 1),
          LSwitch(
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
    return LSheet(
      Column(
        children: [
          Row(
            children: [
              LSpace(
                [LH4("TMDB API Key"), LSubTitle('主刮削源，未配置时无法获取海报与元数据')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LChip.filled(
                controller.hasTmdbKey ? '已配置' : '未配置',
                color: controller.hasTmdbKey
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          Divider(thickness: 1),
          Row(
            children: [
              LSpace(
                [LH4("豆瓣 API Key（备用）"), LSubTitle('TMDB 找不到时自动尝试豆瓣')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LChip.filled(
                controller.hasDoubanKey ? '已配置' : '未配置',
                color: controller.hasTmdbKey
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          Divider(thickness: 1),
          Row(
            children: [
              if (controller.scraping)
                LSpace(
                  [LH4("正在刮削"), LSubTitle('NFO 与本地海报会优先于网络刮削结果。')],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                )
              else
                LSpace(
                  [LH4("状态"), LSubTitle('NFO 与本地海报会优先于网络刮削结果。')],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                ),
              LButton(
                label: "重新刮削全部",
                autofocus: true,
                icon: Icons.radar_rounded,
                onClick: () => {controller.scrapeAll()},
              ),
            ],
          ),
          Divider(thickness: 1),
          Row(
            children: [
              LSpace(
                [LH4("元数据语言"), LSubTitle('影响 TMDB 返回的标题、简介与剧集信息')],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LSelector(
                TmdbLanguage.values.map((x) => x.label).toList(),
                onSelect: (i) => {
                  controller.setLanguage(TmdbLanguage.values[i]),
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TvScan extends StatelessWidget {
  const TvScan({super.key});
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
    final controller = context.read<AppController>();
    final autoScrape = context.select<AppController, bool>(
      (controller) => controller.settings.autoScrape,
    );
    final autoScanOnStart = context.select<AppController, bool>(
      (controller) => controller.settings.autoScanOnStart,
    );
    return LSheet(
      Column(
        children: [
          LSwitch(
            controller.setAutoScanOnStart,
            value: autoScanOnStart,
            title: "启动时自动扫描",
            subTitle: "打开应用后检查所有媒体目录是否有新文件",
          ),
          Divider(thickness: 1),

          LSwitch(
            controller.setAutoScrape,
            value: autoScrape,
            title: "扫描后自动刮削",
            subTitle: "发现新视频后自动向 TMDB 获取海报与元数据",
          ),
          Divider(thickness: 1),
          Row(
            children: [
              if (controller.scanning)
                LSpace(
                  [
                    LH4('正在扫描「${controller.scanSourceName}」'),
                    LSubTitle(
                      '已发现 ${controller.scanFound} 个视频 · ${controller.scanCurrent}',
                    ),
                  ],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                )
              else
                LSpace(
                  [
                    LH4("状态"),
                    LSubTitle(
                      controller.lastScanAt == null
                          ? '尚未扫描过媒体库'
                          : '上次扫描：${_formatMoment(controller.lastScanAt!)}',
                    ),
                  ],
                  vertical: true,
                  alighment: WrapCrossAlignment.start,
                  isExpanded: true,
                ),

              LButton(
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
  const TvPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();
    final autoLoadSubtitles = context.select<AppController, bool>(
      (controller) => controller.settings.autoLoadSubtitles,
    );
    final autoPlayNext = context.select<AppController, bool>(
      (controller) => controller.settings.autoPlayNext,
    );
    final rememberPlaybackSpeed = context.select<AppController, bool>(
      (controller) => controller.settings.rememberPlaybackSpeed,
    );

    return LSheet(
      Column(
        children: [
          LSwitch(
            controller.setAutoLoadSubtitles,
            value: autoLoadSubtitles,
            title: "自动加载同名字幕",
            subTitle: "播放时自动寻找与视频同名的 .srt / .ass 字幕",
          ),
          Divider(thickness: 1),
          LSwitch(
            controller.setAutoPlayNext,
            value: autoPlayNext,
            title: "自动播放下一集",
            subTitle: "当前剧集结束后继续播放下一集",
          ),
          Divider(thickness: 1),
          LSwitch(
            controller.setRememberPlaybackSpeed,
            value: rememberPlaybackSpeed,
            title: "记住播放速度",
            subTitle: "打开后，下一个视频将沿用上一次切换的播放速度",
          ),
        ],
      ),
    );
  }
}

class TvMediaSource extends StatelessWidget {
  const TvMediaSource({super.key});

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
    final controller = context.read<AppController>();
    final granted = context.select<AppController, bool>(
      (controller) => controller.hasStorageAccess,
    );
    final sources = context.select<AppController, List<LibrarySource>>(
      (controller) => controller.sources,
    );

    return LSheet(
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
              LSpace(
                [
                  LH4(granted ? '已获得所有文件访问权限' : '尚未授予所有文件访问权限'),
                  LSubTitle(
                    granted
                        ? '可以读取本地存储与外接 USB 磁盘中的视频'
                        : 'Android TV 读取外接磁盘需要此权限',
                  ),
                ],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LButton(
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
          Divider(thickness: 1),
          if (sources.isEmpty) ...[
            LH4(
              "还没有添加媒体目录",
              color: Theme.of(context).extension<SemanticColors>()?.danger,
            ),
            Divider(thickness: 1),
          ] else ...[
            ...sources.map((source) {
              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined),
                      const TDivider(),
                      Expanded(child: LSubTitle(source.path)),
                      LButton(
                        icon: Icons.remove_circle_outline_rounded,
                        color: Theme.of(context)
                            .extension<SemanticColors>()
                            ?.danger,
                        onClick: () =>
                            _removeSource(context, controller, source),
                      ),
                    ],
                  ),
                  const Divider(thickness: 0.5, indent: 38),
                ],
              );
            }),
          ],
          Row(
            children: [
              Expanded(
                child: LButton(
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
  const TvData({super.key});

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
      messageController.success("媒体库已清空");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AppController>();

    return LSheet(
      Column(
        children: [
          Row(
            children: [
              LSpace(
                [LH4('清空媒体库'), LSubTitle("移除所有影片、剧集与播放进度，不会删除硬盘上的视频文件")],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LButton(
                label: '清空',
                icon: Icons.delete_outline_rounded,
                color: Theme.of(context).extension<SemanticColors>()?.danger,
                onClick: () {
                  _confirmClear(context, controller);
                },
              ),
            ],
          ),
          Divider(thickness: 1),
          Row(
            children: [
              LSpace(
                [LH4('引导'), LSubTitle("进入应用欢迎页")],
                vertical: true,
                alighment: WrapCrossAlignment.start,
                isExpanded: true,
              ),
              LButton(
                label: '进入',
                // icon: Icons.mediation,
                onClick: controller.notCompleteOnboarding,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
