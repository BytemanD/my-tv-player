import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../core/theme.dart';
import '../../data/library_source.dart';
import '../../data/settings_service.dart';
import '../../widgets/tv_focusable.dart';
import '../sources/add_source_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 56, 54),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.6,
                    color: LumaColors.text,
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    '扫描、刮削与播放偏好',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: LumaColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section(
              title: '外观',
              children: [
                _Panel(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主题',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: LumaColors.textOnSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '选择整体气质，后续会陆续上线更多主题',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LumaColors.textMutedOnSurface,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final option in LumaThemes.all)
                              _ThemeOptionTile(
                                option: option,
                                selected:
                                    controller.settings.themeId == option.id,
                                onTap: () => controller.setTheme(option.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _Hairline(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '模式',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: LumaColors.textOnSurface,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '关闭为浅色，打开为深色；每个主题独立记忆模式',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: LumaColors.textMutedOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            TvSwitchToggle(
                              value: controller.settings.themeMode == 'dark',
                              label: controller.settings.themeMode == 'dark'
                                  ? '深色'
                                  : '浅色',
                              onChanged: (dark) => controller.setThemeMode(
                                dark ? 'dark' : 'light',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Section(
              title: '刮削与元数据',
              children: [
                _Panel(
                  child: Column(
                    children: [
                      _KeyRow(
                        configured: controller.hasTmdbKey,
                        onTap: () => _editKey(context, controller),
                      ),
                      const _Hairline(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '元数据语言',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: LumaColors.textOnSurface,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    '影响 TMDB 返回的标题、简介与剧集信息',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: LumaColors.textMutedOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Wrap(
                              spacing: 7,
                              children: [
                                for (final language in TmdbLanguage.values)
                                  TvChip(
                                    label: language.label,
                                    selected:
                                        controller.settings.language ==
                                        language,
                                    onTap: () =>
                                        controller.setLanguage(language),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const _Hairline(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'NFO 与本地海报会优先于网络刮削结果。',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: LumaColors.textMutedOnSurface,
                                ),
                              ),
                            ),
                            TvButton(
                              label: '重新刮削全部',
                              icon: Icons.auto_awesome_rounded,
                              compact: true,
                              style: TvButtonStyle.outline,
                              enabled:
                                  !controller.isBusy &&
                                  controller.hasTmdbKey &&
                                  controller.entries.isNotEmpty,
                              onTap: () => controller.scrapeAll(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Section(
              title: '扫描',
              children: [
                _Panel(
                  child: Column(
                    children: [
                      TvSwitch(
                        title: '启动时自动扫描',
                        description: '打开应用后检查所有媒体目录是否有新文件',
                        value: controller.settings.autoScanOnStart,
                        onChanged: controller.setAutoScanOnStart,
                      ),
                      const _Hairline(),
                      TvSwitch(
                        title: '扫描后自动刮削',
                        description: '发现新视频后自动向 TMDB 获取海报与元数据',
                        value: controller.settings.autoScrape,
                        onChanged: controller.setAutoScrape,
                      ),
                      const _Hairline(),
                      if (controller.scanning)
                        _ActivityRow(
                          title: '正在扫描「${controller.scanSourceName}」',
                          detail:
                              '已发现 ${controller.scanFound} 个视频 · ${controller.scanCurrent}',
                          value: null,
                        )
                      else if (controller.scraping)
                        _ActivityRow(
                          title:
                              '正在刮削元数据 ${controller.scrapeProgress.done}/${controller.scrapeProgress.total}',
                          detail: controller.scrapeProgress.current,
                          value: controller.scrapeProgress.fraction,
                          onCancel: controller.cancelScrape,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.lastScanAt == null
                                      ? '尚未扫描过媒体库'
                                      : '上次扫描：${_formatMoment(controller.lastScanAt!)}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: LumaColors.textMutedOnSurface,
                                  ),
                                ),
                              ),
                              TvButton(
                                label: '立即扫描',
                                icon: Icons.radar_rounded,
                                compact: true,
                                enabled:
                                    !controller.isBusy &&
                                    controller.sources.isNotEmpty,
                                onTap: () => controller.scanAll(),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Section(
              title: '播放',
              children: [
                _Panel(
                  child: Column(
                    children: [
                      TvSwitch(
                        title: '自动加载同名字幕',
                        description: '播放时自动寻找与视频同名的 .srt / .ass 字幕',
                        value: controller.settings.autoLoadSubtitles,
                        onChanged: controller.setAutoLoadSubtitles,
                      ),
                      const _Hairline(),
                      TvSwitch(
                        title: '自动播放下一集',
                        description: '当前剧集结束后继续播放下一集',
                        value: controller.settings.autoPlayNext,
                        onChanged: controller.setAutoPlayNext,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Section(
              title: '媒体来源',
              trailing: TvButton(
                label: '添加目录',
                icon: Icons.add_rounded,
                compact: true,
                style: TvButtonStyle.filled,
                onTap: () => showAddSourceDialog(context, controller),
              ),
              children: [
                _Panel(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _PermissionRow(controller: controller),
                      if (controller.sources.isEmpty) ...[
                        const _Hairline(indent: 18),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 28),
                          child: Center(
                            child: Text(
                              '还没有添加媒体目录',
                              style: TextStyle(
                                fontSize: 13,
                                color: LumaColors.textMutedOnSurface,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        for (var i = 0; i < controller.sources.length; i++) ...[
                          const _Hairline(indent: 18),
                          _SourceRow(
                            source: controller.sources[i],
                            onRemove: () => _removeSource(
                              context,
                              controller,
                              controller.sources[i],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _Section(
              title: '数据',
              children: [
                _Panel(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '清空媒体库',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: LumaColors.textOnSurface,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '移除所有影片、剧集与播放进度，不会删除硬盘上的视频文件',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: LumaColors.textMutedOnSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      TvButton(
                        label: '清空',
                        icon: Icons.delete_outline_rounded,
                        compact: true,
                        style: TvButtonStyle.filled,
                        backgroundColor: LumaColors.danger.withValues(
                          alpha: 0.40,
                        ),
                        enabled: controller.entries.isNotEmpty,
                        onTap: () => _confirmClear(context, controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Center(
              child: Column(
                children: [
                  Text(
                    'Luma 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      color: LumaColors.textMutedOnSurface,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    '海报与元数据由 TMDB 提供。本产品使用 TMDB API，但未获得 TMDB 认可或认证。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: LumaColors.textMutedOnSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editKey(BuildContext context, AppController controller) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _TmdbKeyDialog(controller: controller),
    );
  }

  Future<void> _removeSource(
    BuildContext context,
    AppController controller,
    LibrarySource source,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
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

  Future<void> _confirmClear(
    BuildContext context,
    AppController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
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

  static String _formatMoment(DateTime moment) {
    final now = DateTime.now();
    final diff = now.difference(moment);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${moment.year}/${moment.month.toString().padLeft(2, '0')}/${moment.day.toString().padLeft(2, '0')} '
        '${moment.hour.toString().padLeft(2, '0')}:${moment.minute.toString().padLeft(2, '0')}';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.2,
                  color: LumaColors.textMutedOnSurface,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: LumaColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        // border: Border.all(color: LumaColors.lineSoft),
      ),
      child: child,
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({this.indent = 0});
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: LumaColors.lineSoft,
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.configured, required this.onTap});

  final bool configured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: configured
                  ? LumaColors.primarySoft
                  : LumaColors.surfaceHigh,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              configured ? Icons.key_rounded : Icons.key_off_rounded,
              size: 20,
              color: configured
                  ? LumaColors.primary
                  : LumaColors.textMutedOnSurface,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TMDB API Key',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: LumaColors.textOnSurface,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: configured
                            ? LumaColors.success.withValues(alpha: 0.12)
                            : LumaColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        configured ? '已配置' : '未配置',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: configured
                              ? LumaColors.success
                              : LumaColors.textMutedOnSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  configured
                      ? '用于搜索影片、剧集、海报与简介'
                      : '在 themoviedb.org 免费申请后填入，才能自动刮削',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LumaColors.textMutedOnSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          TvButton(
            label: configured ? '更换' : '配置',
            icon: Icons.tune_rounded,
            compact: true,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source, required this.onRemove});

  final LibrarySource source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lastScan = source.lastScanAt == null
        ? '尚未扫描'
        : '上次扫描 ${SettingsScreen._formatMoment(DateTime.fromMillisecondsSinceEpoch(source.lastScanAt!))}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 21,
            color: LumaColors.textMutedOnSurface,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: LumaColors.textOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${source.path} · $lastScan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: LumaColors.textMutedOnSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TvIconButton(
            icon: Icons.remove_circle_outline_rounded,
            size: 38,
            iconSize: 18,
            tooltip: '移除',
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final granted = controller.hasStorageAccess;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        children: [
          Icon(
            granted ? Icons.verified_user_outlined : Icons.lock_outline_rounded,
            size: 20,
            color: granted ? LumaColors.success : LumaColors.primary,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  granted ? '已获得所有文件访问权限' : '尚未授予所有文件访问权限',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: LumaColors.textOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  granted ? '可以读取本地存储与外接 USB 磁盘中的视频' : 'Android TV 读取外接磁盘需要此权限',
                  style: TextStyle(
                    fontSize: 12,
                    color: LumaColors.textMutedOnSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TvButton(
            label: granted ? '重新检查' : '去授权',
            compact: true,
            style: TvButtonStyle.filled,
            onTap: () async {
              if (!granted) {
                await controller.requestStorageAccess();
              } else {
                await controller.refreshAccessState();
                controller.showNotice('文件访问权限正常');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.detail,
    required this.value,
    this.onCancel,
  });

  final String title;
  final String detail;
  final double? value;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: LumaColors.textOnSurface,
                  ),
                ),
              ),
              if (onCancel != null)
                TvButton(
                  label: '停止',
                  compact: true,
                  style: TvButtonStyle.ghost,
                  onTap: onCancel,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: LumaColors.textMutedOnSurface,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: value,
              backgroundColor: LumaColors.line,
              color: LumaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TmdbKeyDialog extends StatefulWidget {
  const _TmdbKeyDialog({required this.controller});

  final AppController controller;

  @override
  State<_TmdbKeyDialog> createState() => _TmdbKeyDialogState();
}

class _TmdbKeyDialogState extends State<_TmdbKeyDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.settings.tmdbApiKey,
  );
  bool _busy = false;
  bool _obscure = true;
  String? _result;
  bool _resultIsError = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await widget.controller.testTmdbConnection(_text.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
      _resultIsError = !result.contains('成功');
    });
  }

  Future<void> _save() async {
    final key = _text.text.trim();
    await widget.controller.setTmdbApiKey(key);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.controller.showNotice(
      key.isEmpty ? '已清除 TMDB API Key' : 'TMDB API Key 已保存',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(48),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 760,
        padding: const EdgeInsets.fromLTRB(30, 28, 30, 24),
        decoration: BoxDecoration(
          color: LumaColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: LumaColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 60,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TMDB API Key',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: LumaColors.textOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在 themoviedb.org 注册账号，进入 Settings → API 申请免费 Key。Key 仅保存在本机。',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: LumaColors.textMutedOnSurface,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _text,
              autofocus: true,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _save(),
              style: TextStyle(fontSize: 15, color: LumaColors.textOnSurface),
              decoration: InputDecoration(
                hintText: '粘贴 API Key（v3 auth）',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 19),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                  ),
                  color: LumaColors.textMutedOnSurface,
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    _resultIsError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline,
                    size: 17,
                    color: _resultIsError
                        ? LumaColors.danger
                        : LumaColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _result!,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _resultIsError
                            ? LumaColors.danger
                            : LumaColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                TvButton(
                  label: _busy ? '测试中…' : '测试连接',
                  icon: Icons.wifi_tethering_rounded,
                  style: TvButtonStyle.outline,
                  compact: true,
                  enabled: !_busy && _text.text.trim().isNotEmpty,
                  onTap: _test,
                ),
                const Spacer(),
                TvButton(
                  label: '取消',
                  style: TvButtonStyle.ghost,
                  compact: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                TvButton(
                  label: '保存',
                  icon: Icons.check_rounded,
                  compact: true,
                  enabled: !_busy,
                  onTap: _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(48),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
        decoration: BoxDecoration(
          color: LumaColors.surface,
          borderRadius: BorderRadius.circular(20),
          // border: Border.all(color: LumaColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  destructive
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  size: 22,
                  color: destructive ? LumaColors.danger : LumaColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: LumaColors.textOnSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.65,
                color: LumaColors.textDimOnSurface,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Spacer(),
                TvButton(
                  label: '取消',
                  style: TvButtonStyle.ghost,
                  compact: true,
                  onTap: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 10),
                TvButton(
                  label: confirmLabel,
                  style: destructive
                      ? TvButtonStyle.outline
                      : TvButtonStyle.filled,
                  compact: true,
                  autofocus: true,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final LumaThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      scale: 1.04,
      builder: (context, focused) {
        final active = selected || focused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 128,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active
                ? LumaColors.primarySoft
                : LumaColors.surfaceHigh.withValues(alpha: 1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? LumaColors.primary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: ColoredBox(color: option.swatches[0]),
                            ),
                            Expanded(
                              flex: 3,
                              child: ColoredBox(color: option.swatches[1]),
                            ),
                            Expanded(
                              flex: 2,
                              child: ColoredBox(color: option.swatches[2]),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: LumaColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Color(0xFF21190A),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                option.name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? LumaColors.primary
                      : LumaColors.textOnSurface,
                ),
              ),
              Text(
                option.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: LumaColors.textMutedOnSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
