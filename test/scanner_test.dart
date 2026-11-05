import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/data/library_source.dart';
import 'package:luma_tv/data/models.dart';
import 'package:luma_tv/data/scanner/media_scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('luma_scan_');
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  Future<File> video(String path) async {
    final file = File(p.join(root.path, path));
    await file.parent.create(recursive: true);
    final handle = await file.open(mode: FileMode.write);
    await handle.truncate(3 * 1024 * 1024);
    await handle.close();
    return file;
  }

  test('walks nested folders and applies NFO metadata', () async {
    await video('Shows/Demo/Season 01/Demo.S01E02.mkv');
    File(p.join(root.path, 'Shows/Demo/Season 01/Demo.S01E02.nfo'))
        .writeAsStringSync('''
          <episodedetails>
            <title>The Beginning</title>
            <showtitle>Demo Show</showtitle>
            <season>1</season>
            <episode>2</episode>
            <plot>Pilot plot.</plot>
          </episodedetails>
        ''');

    final result = await MediaScanner().scan(
      LibrarySource(id: 1, path: root.path, name: 'test', addedAt: 0),
    );

    expect(result.items, hasLength(1));
    final item = result.items.single;
    expect(item.kind, MediaKind.episode);
    expect(item.season, 1);
    expect(item.episode, 2);
    expect(item.title, 'The Beginning');
    expect(item.seriesTitle, 'Demo Show');
    expect(item.overview, 'Pilot plot.');
    expect(item.nfoPath, isNotNull);
  });

  test('discovers MP4 files larger than the minimum scan size', () async {
    await video('Movies/Example.Movie.2024.mp4');

    final result = await MediaScanner().scan(
      LibrarySource(id: 1, path: root.path, name: 'test', addedAt: 0),
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.fileName, 'Example.Movie.2024.mp4');
    expect(result.visitedFiles, 1);
    expect(result.skipped, 0);
    expect(result.failedFiles, 0);
  });

  test('ignores samples, hidden folders and Android data', () async {
    await video('Movies/Real.Movie.2020.mkv');
    await video('Movies/sample.mkv');
    await video('Movies/.hidden/Hidden.Movie.mkv');
    await video('Android/data/com.example/Cache.Movie.mkv');

    final result = await MediaScanner().scan(
      LibrarySource(id: 1, path: root.path, name: 'test', addedAt: 0),
    );

    expect(result.items, hasLength(1));
    expect(result.items.single.fileName, 'Real.Movie.2020.mkv');
    expect(result.skipped, greaterThanOrEqualTo(1));
  });

  test('derives a show name when files are just episode numbers', () async {
    await video('Show Name/Season 02/03.mkv');
    await video('Show Name/Season 02/04.mkv');

    final result = await MediaScanner().scan(
      LibrarySource(id: 1, path: root.path, name: 'test', addedAt: 0),
    );

    expect(result.items, hasLength(2));
    expect(result.items.every((m) => m.seriesTitle == 'Show Name'), isTrue);
    expect(result.items.every((m) => m.season == 2), isTrue);
    expect(result.items.map((m) => m.episode), containsAll([3, 4]));
  });

  test('keeps scanning after an unreadable sibling is skipped', () async {
    await video('A/One.Movie.2021.mkv');
    await video('B/Two.Movie.2022.mkv');

    final result = await MediaScanner().scan(
      LibrarySource(id: 1, path: root.path, name: 'test', addedAt: 0),
    );

    expect(result.items, hasLength(2));
  });
}
