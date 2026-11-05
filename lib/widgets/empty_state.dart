import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'logo.dart';
import 'tv_focusable.dart';

class EmptyLibrary extends StatelessWidget {
  const EmptyLibrary({
    super.key,
    required this.onAddFolder,
    required this.onScan,
    this.hasSources = false,
    this.hasAccess = true,
    this.onGrantAccess,
    this.title,
    this.description,
  });

  final VoidCallback onAddFolder;
  final VoidCallback onScan;
  final bool hasSources;
  final bool hasAccess;
  final VoidCallback? onGrantAccess;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LumaMark(size: 64),
            const SizedBox(height: 28),
            Text(
              title ?? (hasSources ? '媒体库还是空的' : '把你的电影，留在墙上'),
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: LumaColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description ??
                  (hasSources
                      ? '目录已经添加，但还没有发现视频。检查权限或重新扫描一次。'
                      : '选择一个本地文件夹或外接磁盘，Luma 会自动扫描视频并刮削海报与元数据。'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.7,
                color: LumaColors.textMuted,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (!hasAccess && onGrantAccess != null)
                  TvButton(
                    label: '授予文件访问权限',
                    icon: Icons.lock_open_rounded,
                    autofocus: true,
                    onTap: onGrantAccess,
                  ),
                TvButton(
                  label: hasSources ? '重新扫描' : '添加媒体目录',
                  icon: hasSources
                      ? Icons.refresh_rounded
                      : Icons.folder_open_rounded,
                  autofocus: hasAccess,
                  onTap: hasSources ? onScan : onAddFolder,
                ),
                if (!hasSources)
                  TvButton(
                    label: '扫描整块磁盘',
                    icon: Icons.storage_rounded,
                    style: TvButtonStyle.outline,
                    onTap: onScan,
                  ),
              ],
            ),
            if (!hasAccess) ...[
              const SizedBox(height: 22),
              Text(
                'Android TV 需要“所有文件访问权限”才能读取外接磁盘中的视频',
                style: TextStyle(fontSize: 12, color: LumaColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
