import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/storage_service.dart';
import '../../widgets/tv_focusable.dart';

Future<void> showAddSourceDialog(
  BuildContext context,
  AppController controller,
) async {
  final action = await showDialog<_AddAction>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _AddSourceDialog(controller: controller),
  );
  if (action == null) return;
  if (action.pickFolder) {
    await controller.addSourceFromPicker();
  } else if (action.volume != null) {
    await controller.addVolumeSource(action.volume!);
  }
}

class _AddAction {
  const _AddAction.pickFolder() : pickFolder = true, volume = null;
  const _AddAction.volume(this.volume) : pickFolder = false;
  final bool pickFolder;
  final StorageVolume? volume;
}

class _AddSourceDialog extends StatefulWidget {
  const _AddSourceDialog({required this.controller});
  final AppController controller;

  @override
  State<_AddSourceDialog> createState() => _AddSourceDialogState();
}

class _AddSourceDialogState extends State<_AddSourceDialog> {
  List<StorageVolume> _volumes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final volumes = await widget.controller.storage.volumes();
    if (!mounted) return;
    setState(() {
      _volumes = volumes;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(48),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 760,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.fromLTRB(30, 26, 30, 26),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '添加媒体目录',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: LumaColors.textOnSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择一个文件夹，或直接添加整块磁盘。Luma 会递归扫描其中的视频，识别电影和剧集。',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: LumaColors.textMutedOnSurface,
              ),
            ),
            const SizedBox(height: 20),
            if (!widget.controller.hasStorageAccess)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LumaColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LumaColors.primaryDeep),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: LumaColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '尚未授予“所有文件访问权限”，扫描外接磁盘前需要先授权。',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: LumaColors.textDimOnSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TvButton(
                      label: '去授权',
                      compact: true,
                      onTap: () async {
                        await widget.controller.requestStorageAccess();
                      },
                    ),
                  ],
                ),
              ),
            TvButton(
              label: '选择文件夹…',
              icon: Icons.folder_open_rounded,
              autofocus: true,
              onTap: () =>
                  Navigator.of(context).pop(const _AddAction.pickFolder()),
            ),
            const SizedBox(height: 22),
            Text(
              '整块磁盘',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.3,
                color: LumaColors.textMutedOnSurface,
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: LumaColors.primary,
                    ),
                  ),
                ),
              )
            else if (_volumes.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '没有检测到可用的存储设备',
                  style: TextStyle(
                    fontSize: 13,
                    color: LumaColors.textMutedOnSurface,
                  ),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final volume in _volumes)
                        TvFocusable(
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(_AddAction.volume(volume)),
                          scale: 1.008,
                          builder: (context, focused) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: focused
                                    ? LumaColors.surfaceHigh
                                    : LumaColors.backgroundSoft,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: focused
                                      ? LumaColors.primary
                                      : LumaColors.lineSoft,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    volume.removable
                                        ? Icons.usb_rounded
                                        : Icons.storage_rounded,
                                    size: 22,
                                    color: focused
                                        ? LumaColors.primary
                                        : LumaColors.textMutedOnSurface,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          volume.label.isEmpty
                                              ? volume.path
                                              : volume.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: LumaColors.textOnSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          volume.path,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                LumaColors.textMutedOnSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    volume.totalBytes > 0
                                        ? '可用 ${formatFileSize(volume.freeBytes)}'
                                        : '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: LumaColors.textMutedOnSurface,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
