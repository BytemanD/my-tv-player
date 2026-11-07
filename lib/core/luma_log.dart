import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// 统一的日志入口。
///
/// 开发时输出全部级别，发布包只保留警告及以上，避免刷屏。
/// 用法：`LumaLog.of('Scrape').info('...')`。
class LumaLog {
  LumaLog._();

  static bool _initialized = false;

  /// 初始化根 Logger，`main()` 启动时调用一次即可。
  static void init() {
    if (_initialized) return;
    _initialized = true;

    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      final level = record.level.name.padRight(7);
      debugPrint('[$level] ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        debugPrint('        error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('        at ${record.stackTrace}');
      }
    });
  }

  /// 获取指定名称的 Logger（如 `Luma.Scrape`）。
  static Logger of(String name) => Logger(name);
}
