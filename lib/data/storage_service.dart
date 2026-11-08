import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class StorageVolume {
  const StorageVolume({
    required this.path,
    required this.label,
    required this.removable,
    required this.totalBytes,
    required this.freeBytes,
  });

  final String path;
  final String label;
  final bool removable;
  final int totalBytes;
  final int freeBytes;

  factory StorageVolume.fromMap(Map<Object?, Object?> map) {
    return StorageVolume(
      path: map['path'] as String? ?? '',
      label: map['label'] as String? ?? '',
      removable: map['removable'] as bool? ?? false,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class StorageEntry {
  const StorageEntry({required this.name, required this.path});

  final String name;
  final String path;
}

class StorageService {
  static const MethodChannel _channel = MethodChannel('luma/storage');

  /// Desktop builds (used for UI previews) can read the filesystem directly and
  /// pick folders with the GTK/Qt dialog instead of the Android SAF bridge.
  static bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  Future<bool> hasAllFilesAccess() async {
    if (_isDesktop) return true;
    try {
      return await _channel.invokeMethod<bool>('hasAllFilesAccess') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // Running on a non-Android host (tests / desktop preview).
      return false;
    }
  }

  /// Returns a status code from the native side ("already_granted",
  /// "opened_manage_app", "opened_manage_all", "opened_app_details",
  /// "runtime_requested", "unsupported") so the UI can say what happened.
  Future<String> requestAllFilesAccess() async {
    if (_isDesktop) return 'already_granted';
    try {
      return await _channel.invokeMethod<String>('requestAllFilesAccess') ??
          'unsupported';
    } on PlatformException {
      return 'unsupported';
    } on MissingPluginException {
      return 'unsupported';
    }
  }

  /// Requests the normal runtime storage permission (READ_EXTERNAL_STORAGE /
  /// READ_MEDIA_VIDEO). This shows a standard system dialog ("Allow this app to
  /// access photos, media, and files on your device?") instead of sending the
  /// user to the hard-to-find "All-files-access" settings page. Returns
  /// "already_granted", "runtime_requested", "granted", "denied", or
  /// "unsupported".
  Future<String> requestStoragePermission() async {
    if (_isDesktop) return 'already_granted';
    try {
      return await _channel.invokeMethod<String>('requestStoragePermission') ??
          'unsupported';
    } on PlatformException {
      return 'unsupported';
    } on MissingPluginException {
      return 'unsupported';
    }
  }

  /// 列出目录下的子文件夹，供自建文件选择器使用。
  ///
  /// 隐藏以 `.` 开头的系统目录，按名称排序。权限不足时会抛出
  /// [FileSystemException]，由界面提示用户授权。
  Future<List<StorageEntry>> listDirectories(String path) async {
    final dir = Directory(path);
    final entities = await dir.list(followLinks: false).toList();
    final dirs = <StorageEntry>[];
    for (final entity in entities) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      dirs.add(StorageEntry(name: name, path: entity.path));
    }
    dirs.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return dirs;
  }

  Future<List<StorageVolume>> volumes() async {
    if (_isDesktop) {
      final root = Platform.isWindows
          ? '${Platform.environment['SystemDrive'] ?? 'C:'}\\'
          : '/';
      return [
        StorageVolume(
          path: root,
          label: Platform.isWindows ? '系统磁盘' : '系统根目录',
          removable: false,
          totalBytes: 0,
          freeBytes: 0,
        ),
      ];
    }
    try {
      final value =
          await _channel.invokeListMethod<Object?>('getStorageVolumes') ?? [];
      return value
          .whereType<Map<Object?, Object?>>()
          .map(StorageVolume.fromMap)
          .where((v) => v.path.isNotEmpty)
          .toList();
    } on PlatformException {
      return const [];
    } on MissingPluginException {
      return const [];
    }
  }

  Future<void> openAppSettings() async {
    if (_isDesktop) return;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } on PlatformException {
      // Ignore.
    } on MissingPluginException {
      // Ignore.
    }
  }
}
