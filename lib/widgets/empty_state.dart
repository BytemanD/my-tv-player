import 'package:flutter/material.dart';
import 'package:luma_tv/widgets/button.dart';
import 'package:luma_tv/widgets/divider.dart';
import 'package:luma_tv/widgets/text.dart';

import 'logo.dart';

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
            const TDivider(height: 28),
            TH3(title ?? (hasSources ? '媒体库还是空的' : '把你的电影，留在墙上')),
            const TDivider(height: 12),
            TText(
              description ??
                  (hasSources
                      ? '目录已经添加，但还没有发现视频。检查权限或重新扫描一次。'
                      : '选择一个本地文件夹或外接磁盘，Luma 会自动扫描视频并刮削海报与元数据。'),
              // textAlign: TextAlign.center,
              // style: TextStyle(
              //   fontSize: 14.5,
              //   height: 1.7,
              //   // color: Theme.of(context).colorScheme.textMuted,
              // ),
            ),
            const TDivider(height: 30),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (!hasAccess && onGrantAccess != null)
                  TButton(
                    label: '授予文件访问权限',
                    icon: Icons.lock_open_rounded,
                    onClick: onGrantAccess!,
                  ),
                TButton(
                  label: hasSources ? '重新扫描' : '添加媒体目录',
                  icon: hasSources
                      ? Icons.refresh_rounded
                      : Icons.folder_open_rounded,
                  onClick: hasSources ? onScan : onAddFolder,
                ),
                if (!hasSources)
                  TButton(
                    label: '扫描整块磁盘',
                    icon: Icons.storage_rounded,
                    autofocus: false,
                    onClick: onScan,
                  ),
              ],
            ),
            if (!hasAccess) ...[
              const TDivider(height: 22),
              TText('Android TV 需要“所有文件访问权限”才能读取外接磁盘中的视频'),
            ],
          ],
        ),
      ),
    );
  }
}
