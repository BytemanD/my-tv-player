import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/controllers/app_controller.dart';
import 'package:luma_tv/core/theme.dart';
import 'package:luma_tv/data/app_database.dart';
import 'package:luma_tv/data/models.dart';
import 'package:luma_tv/data/media_repository.dart';
import 'package:luma_tv/data/scanner/media_scanner.dart';
import 'package:luma_tv/data/settings_service.dart';
import 'package:luma_tv/data/storage_service.dart';
import 'package:luma_tv/features/onboarding/onboarding_screen.dart';
import 'package:luma_tv/features/shell/main_shell.dart';
import 'package:luma_tv/widgets/shelf.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late AppDatabase database;
  late AppController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsService.load();
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    controller = AppController(
      database: database,
      repository: MediaRepository(database),
      settings: settings,
      storage: StorageService(),
      scanner: MediaScanner(),
    );
    await controller.initialize();
  });

  tearDown(() async {
    await controller.close();
  });

  Future<void> pumpAt720p(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppController>.value(
        value: controller,
        child: MaterialApp(theme: LumaTheme.build(), home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('onboarding renders on a 720p TV', (tester) async {
    await pumpAt720p(tester, const OnboardingScreen());
    expect(find.text('把影院，\n留在家里。'), findsOneWidget);
    expect(find.text('添加媒体目录'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('main shell lays out every tab on a 720p TV', (tester) async {
    await pumpAt720p(tester, const MainShell());
    expect(find.text('首页'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('把你的电影，留在墙上'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('poster shelf fits with enlarged text', (tester) async {
    final entry = LibraryEntry.movie(
      MediaItem(
        sourceId: 1,
        path: '/media/movie.mp4',
        fileName: 'movie.mp4',
        size: 3 * 1024 * 1024,
        modifiedAt: 0,
        kind: MediaKind.movie,
        title: 'A Movie',
        addedAt: 0,
        updatedAt: 0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: MediaShelf(title: '电影', entries: [entry], onOpen: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
