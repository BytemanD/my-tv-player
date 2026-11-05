import 'dart:io';

import 'package:file_selector/file_selector.dart';
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

class PickedFolder {
  const PickedFolder({
    required this.path,
    required this.uri,
    required this.name,
    required this.accessible,
  });

  final String? path;
  final String? uri;
  final String name;
  final bool accessible;

  factory PickedFolder.fromMap(Map<Object?, Object?> map) {
    return PickedFolder(
      path: map['path'] as String?,
      uri: map['uri'] as String?,
      name: map['name'] as String? ?? '媒体目录',
      accessible: map['accessible'] as bool? ?? false,
    );
  }
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

  Future<PickedFolder?> pickFolder() async {
    if (_isDesktop) {
      final path = await getDirectoryPath(confirmButtonText: '选择此文件夹');
      if (path == null) return null;
      final name = p.basename(path);
      return PickedFolder(
        path: path,
        uri: null,
        name: name.isEmpty ? path : name,
        accessible: true,
      );
    }
    try {
      final value = await _channel.invokeMapMethod<Object?, Object?>(
        'pickFolder',
      );
      if (value == null) return null;
      return PickedFolder.fromMap(value);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<List<StorageVolume>> volumes() async {
    if (_isDesktop) return const [];
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
