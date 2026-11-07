import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/luma_log.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LumaLog.init();

  // sqflite only ships a mobile implementation; on desktop previews use the
  // bundled SQLite via FFI so the same repository code can run unchanged.
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Load .env file for runtime configuration (e.g. TMDB_API_KEY).
  // Create .env in project root with: TMDB_API_KEY=your_key
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // .env 文件不存在是正常的，可通过 dart-define 或设置页配置 API Key
  }

  MediaKit.ensureInitialized();
  runApp(const LumaApp());
}
