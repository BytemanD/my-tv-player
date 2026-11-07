import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/app_controller.dart';
import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/storage_service.dart';
import '../../widgets/tv_focusable.dart';

/// 打开自建的文件夹选择器，选中后直接添加并扫描。
Future<void> showAddSourceDialog(
  BuildContext context,
  AppController controller,
) async {
  final path = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _FolderPickerDialog(controller: controller),
  );
  if (path == null) return;
  await controller.addSourceFromPath(path);
}

class _FolderPickerDialog extends StatefulWidget {
  const _FolderPickerDialog({required this.controller});

  final AppController controller;

  @override
  State<_FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<_FolderPickerDialog> {
  List<StorageVolume> _volumes = const [];
  List<StorageEntry> _entries = const [];
  String? _currentPath;
  String? _rootPath;
  bool _loading = true;
  String? _error;

  bool get _atRoot => _currentPath == null;

  /// 已进入某块磁盘的根目录（未再向下进入子文件夹）。
  bool get _atVolumeRoot => _currentPath != null && _currentPath == _rootPath;

  @override
  void initState() {
    super.initState();
    _loadVolumes();
  }

  Future<void> _loadVolumes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final volumes = await widget.controller.storage.volumes();
    if (!mounted) return;
    setState(() {
      _volumes = volumes;
      _loading = false;
    });
  }

  Future<void> _openVolume(StorageVolume volume) async {
    setState(() {
      _rootPath = volume.path;
      _currentPath = volume.path;
    });
    await _loadEntries();
  }

  Future<void> _loadEntries() async {
    final path = _currentPath;
    if (path == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await widget.controller.storage.listDirectories(path);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _loading = false;
        _error = error is FileSystemException
            ? '无法读取该目录，可能没有存储访问权限'
            : '无法读取该目录：$error';
      });
    }
  }

  Future<void> _enter(StorageEntry entry) async {
    setState(() => _currentPath = entry.path);
    await _loadEntries();
  }

  Future<void> _goBack() async {
    final path = _currentPath;
    if (path == null) return;
    if (path == _rootPath) {
      setState(() {
        _currentPath = null;
        _rootPath = null;
        _entries = const [];
        _error = null;
      });
      return;
    }
    final parent = Directory(path).parent.path;
    if (parent == path) {
      setState(() {
        _currentPath = null;
        _rootPath = null;
        _entries = const [];
        _error = null;
      });
      return;
    }
    setState(() => _currentPath = parent);
    await _loadEntries();
  }

  Future<void> _requestAccess({bool allFiles = false}) async {
    await widget.controller.requestStorageAccess(allFiles: allFiles);
    if (!mounted) return;
    if (_atRoot) {
      await _loadVolumes();
    } else {
      await _loadEntries();
    }
  }

  void _confirm() {
    final path = _currentPath;
    if (path == null) return;
    Navigator.of(context).pop(path);
  }


  @override
  Widget build(BuildContext context) {
    final current = _currentPath;
    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(48),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 880,
          constraints: const BoxConstraints(maxHeight: 720),
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '选择媒体目录',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: LumaColors.textOnSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _atRoot
                    ? '先选择一块磁盘，再逐层进入包含视频的文件夹。'
                    : _atVolumeRoot
                    ? '当前位于磁盘根目录，直接确认即可添加整块磁盘；也可以继续进入子文件夹。'
                    : '浏览文件夹，进入包含视频的目录后点击“使用此文件夹”。',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: LumaColors.textMutedOnSurface,
                ),
              ),
              if (!widget.controller.hasStorageAccess)
                Container(
                  margin: const EdgeInsets.only(top: 14),
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
                          '尚未授予“所有文件访问权限”，无法浏览外接磁盘。',
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
                        onTap: _requestAccess,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: LumaColors.backgroundSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LumaColors.lineSoft),
                  ),
                  child: Column(
                    children: [
                      if (!_atRoot)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          child: Row(
                            children: [
                              TvIconButton(
                                icon: Icons.arrow_upward_rounded,
                                tooltip: '上一级',
                                size: 36,
                                iconSize: 18,
                                onTap: _goBack,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  current ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: LumaColors.textMutedOnSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.storage_rounded,
                                size: 18,
                                color: LumaColors.textMutedOnSurface,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '存储设备',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: LumaColors.textOnSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Divider(height: 1, color: LumaColors.lineSoft),
                      Expanded(child: _buildList()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 18,
                    color: _atRoot
                        ? LumaColors.textMutedOnSurface
                        : LumaColors.primary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _atRoot ? '未选择文件夹' : current!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _atRoot
                            ? LumaColors.textMutedOnSurface
                            : LumaColors.textOnSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TvButton(
                    label: '取消',
                    style: TvButtonStyle.ghost,
                    compact: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  TvButton(
                    label: _atVolumeRoot ? '使用整块磁盘' : '使用此文件夹',
                    icon: Icons.check_rounded,
                    compact: true,
                    enabled: !_atRoot,
                    onTap: _atRoot ? null : _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: LumaColors.primary,
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: LumaColors.textMutedOnSurface,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: LumaColors.textMutedOnSurface,
                ),
              ),
              const SizedBox(height: 14),
              TvButton(
                label: '授予所有文件访问权限',
                compact: true,
                onTap: () => _requestAccess(allFiles: true),
              ),
            ],
          ),
        ),
      );
    }

    if (_atRoot) {
      if (_volumes.isEmpty) {
        return Center(
          child: Text(
            '没有检测到可用的存储设备',
            style: TextStyle(
              fontSize: 13,
              color: LumaColors.textMutedOnSurface,
            ),
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _volumes.length,
        itemBuilder: (context, index) {
          final volume = _volumes[index];
          return _EntryRow(
            autofocus: index == 0,
            icon: volume.removable ? Icons.usb_rounded : Icons.storage_rounded,
            title: volume.label.isEmpty ? volume.path : volume.label,
            subtitle: volume.path,
            trailing: volume.totalBytes > 0
                ? '可用 ${formatFileSize(volume.freeBytes)}'
                : null,
            onTap: () => _openVolume(volume),
          );
        },
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Text(
          '该目录下没有子文件夹',
          style: TextStyle(fontSize: 13, color: LumaColors.textMutedOnSurface),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _EntryRow(
          autofocus: index == 0,
          icon: Icons.folder_rounded,
          title: entry.name,
          onTap: () => _enter(entry),
        );
      },
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.autofocus = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      scale: 1.008,
      builder: (context, focused) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: focused ? LumaColors.surfaceHigh : LumaColors.backgroundSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: focused ? LumaColors.primary : LumaColors.lineSoft,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: focused
                    ? LumaColors.primary
                    : LumaColors.textMutedOnSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: LumaColors.textOnSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: LumaColors.textMutedOnSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null && trailing!.isNotEmpty) ...[
                const SizedBox(width: 16),
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 11,
                    color: LumaColors.textMutedOnSurface,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: focused
                    ? LumaColors.primary
                    : LumaColors.textMutedOnSurface,
              ),
            ],
          ),
        );
      },
    );
  }
}
