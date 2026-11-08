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
      if (Platform.isWindows) {
        final root = '${Platform.environment['SystemDrive'] ?? 'C:'}\\';
        return [
          StorageVolume(
            path: root,
            label: '系统磁盘',
            removable: false,
            totalBytes: 0,
            freeBytes: 0,
          ),
        ];
      }
      if (Platform.isLinux) return _linuxVolumes();
      return [
        StorageVolume(
          path: '/',
          label: '系统根目录',
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

  /// 枚举 Linux 上已挂载的磁盘。
  ///
  /// 除了根分区，还会解析 `/proc/mounts` 里的块设备，并扫描
  /// `/media`、`/run/media`、`/mnt` 下的挂载目录，确保 U 盘能显示。
  Future<List<StorageVolume>> _linuxVolumes() async {
    final volumes = <StorageVolume>[];
    final seen = <String>{};

    Future<void> add(String path, String label, bool removable) async {
      if (path.isEmpty || !seen.add(path)) return;
      final stats = await _diskUsage(path);
      volumes.add(
        StorageVolume(
          path: path,
          label: label.isEmpty ? path : label,
          removable: removable,
          totalBytes: stats.$1,
          freeBytes: stats.$2,
        ),
      );
    }

    await add('/', '系统根目录', false);

    final mountPoints = <String>{};
    final devices = <String>{};
    try {
      final lines = await File('/proc/mounts').readAsLines();
      for (final line in lines) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final device = parts[0];
        final mount = parts[1].replaceAll(r'\040', ' ');
        mountPoints.add(mount);
        if (!device.startsWith('/dev/')) continue;
        if (mount == '/') {
          devices.add(device);
          continue;
        }
        if (mount.startsWith('/boot') ||
            mount.startsWith('/snap') ||
            mount.startsWith('/var/snap')) {
          continue;
        }
        // 同一个块设备挂载多次（如 / 和 /home）只显示一次。
        if (!devices.add(device)) continue;
        var label = p.basename(mount);
        if (label.isEmpty || label == '/') label = p.basename(device);
        await add(mount, label, await _isRemovableDevice(device));
      }
    } catch (_) {
      // /proc/mounts 不可读时忽略，仍可扫描常见挂载目录。
    }

    // 桌面环境（udisks/gvfs）常把 U 盘挂在 /media/<用户>/<卷标>。
    // 若条目本身是挂载点就直接加，否则下钻一层；/mnt 直接加。
    for (final base in const ['/media', '/run/media', '/mnt']) {
      final dir = Directory(base);
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list(followLinks: false)) {
          if (entity is! Directory) continue;
          final name = p.basename(entity.path);
          if (base != '/mnt' && !mountPoints.contains(entity.path)) {
            final nested = await entity
                .list(followLinks: false)
                .where((e) => e is Directory)
                .toList();
            if (nested.isNotEmpty) {
              for (final child in nested) {
                await add(child.path, p.basename(child.path), true);
              }
              continue;
            }
          }
          await add(entity.path, name, true);
        }
      } catch (_) {
        // 无权限的挂载目录忽略。
      }
    }

    if (volumes.length > 1) {
      volumes.sort((a, b) {
        if (a.removable != b.removable) return a.removable ? -1 : 1;
        return a.path.compareTo(b.path);
      });
    }
    return volumes;
  }

  /// 用 `df -P -k` 读取总容量和可用容量（字节）。
  Future<(int, int)> _diskUsage(String path) async {
    try {
      final result = await Process.run('df', ['-P', '-k', path]);
      if (result.exitCode != 0) return (0, 0);
      final lines = (result.stdout as String).trim().split('\n');
      if (lines.length < 2) return (0, 0);
      final cols = lines.last.trim().split(RegExp(r'\s+'));
      if (cols.length < 4) return (0, 0);
      final totalKb = int.tryParse(cols[1]) ?? 0;
      final freeKb = int.tryParse(cols[3]) ?? 0;
      return (totalKb * 1024, freeKb * 1024);
    } catch (_) {
      return (0, 0);
    }
  }

  Future<bool> _isRemovableDevice(String device) async {
    try {
      final name = p.basename(device);
      // /dev/sdb1 -> sdb，/dev/nvme0n1p2 -> nvme0n1
      final base = name.replaceFirst(RegExp(r'p?\d+$'), '');
      final flag = File('/sys/block/$base/removable');
      if (await flag.exists()) {
        return (await flag.readAsString()).trim() == '1';
      }
    } catch (_) {
      // Ignore.
    }
    return false;
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
