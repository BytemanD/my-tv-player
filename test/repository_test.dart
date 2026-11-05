import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/data/app_database.dart';
import 'package:luma_tv/data/media_repository.dart';
import 'package:luma_tv/data/models.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late MediaRepository repository;

  setUp(() async {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = MediaRepository(database);
  });

  tearDown(() => database.close());

  MediaItem movie(String path, {String title = 'A Movie'}) {
    return MediaItem(
      sourceId: 0,
      path: path,
      fileName: p.basename(path),
      size: 1024 * 1024 * 800,
      modifiedAt: 1,
      kind: MediaKind.movie,
      title: title,
      year: 2020,
      addedAt: 1,
      updatedAt: 1,
    );
  }

  MediaItem episode(
    String path, {
    required String seriesKey,
    required String show,
    required int season,
    required int number,
  }) {
    return MediaItem(
      sourceId: 0,
      path: path,
      fileName: p.basename(path),
      size: 1024 * 1024 * 500,
      modifiedAt: 1,
      kind: MediaKind.episode,
      title: show,
      year: 2021,
      season: season,
      episode: number,
      seriesKey: seriesKey,
      seriesTitle: show,
      addedAt: 1,
      updatedAt: 1,
    );
  }

  test('stores sources and applies a recursive scan result', () async {
    final sourceId = await repository.addSource(
      path: '/storage/usb/Movies',
      name: 'USB 磁盘',
    );
    expect(await repository.sources(), hasLength(1));

    final applied = await repository.applyScan(sourceId, [
      movie('/storage/usb/Movies/Inception.2010.mkv', title: 'Inception'),
      movie('/storage/usb/Movies/Arrival.2016.mkv', title: 'Arrival'),
      episode(
        '/storage/usb/Shows/Show.S01E01.mkv',
        seriesKey: 'name:show:2021',
        show: 'Show',
        season: 1,
        number: 1,
      ),
      episode(
        '/storage/usb/Shows/Show.S01E02.mkv',
        seriesKey: 'name:show:2021',
        show: 'Show',
        season: 1,
        number: 2,
      ),
    ]);

    expect(applied.added, 4);
    expect(applied.removed, 0);
    final all = await repository.allMedia();
    expect(all, hasLength(4));

    final stats = await repository.stats();
    expect(stats.movies, 2);
    expect(stats.episodes, 2);
    expect(stats.series, 1);
  });

  test('rescan removes missing files and preserves scraped metadata', () async {
    final sourceId = await repository.addSource(path: '/media', name: '本地');
    await repository.applyScan(sourceId, [
      movie('/media/a.mkv', title: 'Raw A'),
      movie('/media/b.mkv', title: 'Raw B'),
    ]);

    final scanned = await repository.allMedia();
    final a = scanned.firstWhere((m) => m.path == '/media/a.mkv');
    await repository.applyMetadata(
      a.id!,
      const ScrapedMetadata(
        title: 'Scraped A',
        posterPath: '/poster.jpg',
        tmdbId: 12345,
      ),
    );
    await repository.setScrapeState(a.id!, ScrapeState.done);

    final applied = await repository.applyScan(sourceId, [
      movie('/media/a.mkv', title: 'Raw A changed'),
    ]);

    expect(applied.added, 0);
    expect(applied.removed, 1);
    final after = await repository.allMedia();
    expect(after, hasLength(1));
    expect(after.single.title, 'Scraped A');
    expect(after.single.posterPath, '/poster.jpg');
    expect(after.single.scrapeState, ScrapeState.done);
  });

  test('saves progress and exposes continue watching', () async {
    final sourceId = await repository.addSource(path: '/media', name: '本地');
    await repository.applyScan(sourceId, [movie('/media/a.mkv')]);
    final media = (await repository.allMedia()).single;

    await repository.saveProgress(
      mediaId: media.id!,
      positionMs: 10 * 60 * 1000,
      durationMs: 120 * 60 * 1000,
    );

    final progress = await repository.progressFor(media.id!);
    expect(progress, isNotNull);
    expect(progress!.fraction, closeTo(1 / 12, 0.0001));

    final continueItems = await repository.continueWatching();
    expect(continueItems, hasLength(1));
    expect(continueItems.single.media.id, media.id);

    await repository.markCompleted(media.id!, durationMs: 120 * 60 * 1000);
    expect(await repository.continueWatching(), isEmpty);
    final stats = await repository.stats();
    expect(stats.progress, 0);
  });

  test('removing a source cascades to its media', () async {
    final sourceId = await repository.addSource(path: '/media', name: '本地');
    await repository.applyScan(sourceId, [movie('/media/a.mkv')]);
    expect(await repository.allMedia(), hasLength(1));

    await repository.removeSource(sourceId);
    expect(await repository.sources(), isEmpty);
    expect(await repository.allMedia(), isEmpty);
  });
}
