import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/core/common/utils.dart';
import 'package:luma_tv/data/scanner/nfo_parser.dart';
import 'package:luma_tv/data/scanner/video_file_name_parser.dart';
import 'package:luma_tv/data/storage_service.dart';

void main() {
  group('video file name parser', () {
    test('parses a movie with year and resolution', () {
      final parsed = VideoFileNameParser.parse(
        '/media/movies/Blade.Runner.2049.2017.2160p.UHD.BluRay.x265.mkv',
      );
      expect(parsed.isEpisode, isFalse);
      expect(parsed.title, contains('Blade Runner 2049'));
      expect(parsed.year, 2017);
    });

    test('parses a SxxEyy episode inside a show folder', () {
      final parsed = VideoFileNameParser.parse(
        '/media/tv/Severance/Season 01/Severance.S01E03.1080p.WEB-DL.mkv',
      );
      expect(parsed.isEpisode, isTrue);
      expect(parsed.season, 1);
      expect(parsed.episode, 3);
      expect(parsed.title.toLowerCase(), contains('severance'));
    });

    test('parses a Chinese episode marker with a folder season', () {
      final parsed = VideoFileNameParser.parse('/media/剧集/三体/第二季/三体 第08集.mp4');
      expect(parsed.isEpisode, isTrue);
      expect(parsed.episode, 8);
    });

    test('uses the show folder when the name starts with SxxEyy', () {
      final first = VideoFileNameParser.parse(
        '/media/剧集/死亡幻象/s01e01.1080p.HD中字[最新电影www.dyg7.com].mp4',
      );
      final second = VideoFileNameParser.parse(
        '/media/剧集/死亡幻象/s01e02.1080p.HD中字[最新电影www.dyg7.com].mp4',
      );

      expect(first.isEpisode, isTrue);
      expect(first.season, 1);
      expect(first.episode, 1);
      expect(first.title, '死亡幻象');
      expect(second.episode, 2);
      expect(second.title, '死亡幻象');
      expect(first.seriesKey, second.seriesKey);
    });

    test('skips a season folder when deriving the show name', () {
      final parsed = VideoFileNameParser.parse(
        '/media/剧集/三体/Season 02/s02e03.1080p.mp4',
      );
      expect(parsed.isEpisode, isTrue);
      expect(parsed.title, '三体');
    });

    test('parses anime style numbering', () {
      final parsed = VideoFileNameParser.parse(
        '/media/anime/Frieren - 12 [1080p].mkv',
      );
      expect(parsed.isEpisode, isTrue);
      expect(parsed.episode, 12);
    });

    test('ignores non video escapes and keeps a clean title', () {
      final parsed = VideoFileNameParser.parse(
        '/media/movies/The.Matrix.1999.1080p.BluRay.x264.mkv',
      );
      expect(parsed.title, 'The Matrix');
      expect(parsed.year, 1999);
    });

    test('strips spaced codec and audio tags from a release name', () {
      final parsed = VideoFileNameParser.parse(
        '/media/movies/The.Truthers.2026.1080p.NF.WEB-DL.H.264.DDP5.1.Atmos-PandaQT.mkv',
      );
      expect(parsed.isEpisode, isFalse);
      expect(parsed.title, 'The Truthers');
      expect(parsed.year, 2026);
    });

    test('lists only visible subdirectories in name order', () async {
      final temp = await Directory.systemTemp.createTemp('luma_list_');
      addTearDown(() => temp.delete(recursive: true));
      await Directory('${temp.path}/beta').create();
      await Directory('${temp.path}/Alpha').create();
      await Directory('${temp.path}/.hidden').create();
      await File('${temp.path}/movie.mp4').writeAsString('x');

      final entries = await StorageService().listDirectories(temp.path);
      expect(entries.map((e) => e.name), ['Alpha', 'beta']);
    });

    test('keeps a video named trailer but ignores marked trailer files', () {
      expect(
        VideoFileNameParser.shouldIgnore('trailer.mp4', 3 * 1024 * 1024),
        isFalse,
      );
      expect(
        VideoFileNameParser.shouldIgnore(
          'Example.Movie.trailer.mp4',
          3 * 1024 * 1024,
        ),
        isTrue,
      );
    });
  });

  group('nfo parser', () {
    test('reads movie metadata and unique ids', () {
      final parsed = NfoParser.parse('''
        <movie>
          <title>地球最后的夜晚</title>
          <year>2018</year>
          <plot>一段记忆的旅程。</plot>
          <runtime>138</runtime>
          <rating>7.1</rating>
          <genre>剧情</genre>
          <genre>悬疑</genre>
          <uniqueid type="tmdb">515173</uniqueid>
          <uniqueid type="imdb">tt7775488</uniqueid>
          <art>
            <poster>poster.jpg</poster>
            <fanart><thumb>fanart.jpg</thumb></fanart>
          </art>
        </movie>
      ''');
      expect(parsed, isNotNull);
      expect(parsed!.title, '地球最后的夜晚');
      expect(parsed.year, 2018);
      expect(parsed.tmdbId, 515173);
      expect(parsed.imdbId, 'tt7775488');
      expect(parsed.genres, containsAll(['剧情', '悬疑']));
      expect(parsed.poster, 'poster.jpg');
      expect(parsed.fanart, 'fanart.jpg');
    });

    test('reads episode details', () {
      final parsed = NfoParser.parse('''
        <episodedetails>
          <title>The Beginning</title>
          <season>1</season>
          <episode>2</episode>
          <showtitle>Some Show</showtitle>
        </episodedetails>
      ''');
      expect(parsed, isNotNull);
      expect(parsed!.season, 1);
      expect(parsed.episode, 2);
      expect(parsed.showTitle, 'Some Show');
    });

    test('rejects unrelated XML roots', () {
      expect(NfoParser.parse('<html><title>no</title></html>'), isNull);
      expect(NfoParser.parse(''), isNull);
    });
  });

  group('formatters', () {
    test('episode code pads numbers', () {
      expect(episodeCode(1, 2), 'S01E02');
      expect(episodeCode(null, 9), 'S01E09');
      expect(episodeCode(null, null), '');
    });

    test('runtime and file size are human readable', () {
      expect(formatRuntime(135), '2 小时 15 分');
      expect(formatRuntime(45), '45 分钟');
      expect(formatFileSize(1024 * 1024 * 3), '3.0 MB');
    });
  });
}
