import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/data/scraper/douban_client.dart';

void main() {
  test('parses Douban search results where id/year are strings', () {
    final candidates = DoubanClient.parseCandidates({
      'count': 20,
      'start': 0,
      'total': 1,
      'subjects': [
        {
          'rating': {
            'max': 10,
            'average': 7.6,
            'stars': '40',
            'min': 0,
          },
          'genres': ['剧情', '恐怖'],
          'title': '夺命许愿',
          'casts': [
            {'name': '全昭映', 'id': '1577507'},
            {'name': '姜美娜', 'id': '1378719'},
          ],
          'original_title': '기리고',
          'subtype': 'tv',
          'directors': [
            {'name': '朴允书', 'id': '1504971'},
          ],
          'year': '2026',
          'images': {
            'small':
                'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2931885934.jpg',
            'large':
                'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2931885934.jpg',
            'medium':
                'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2931885934.jpg',
          },
          'alt': 'https://movie.douban.com/subject/37125831/',
          'id': '37125831',
        },
      ],
    });

    expect(candidates, hasLength(1));
    final candidate = candidates.single;
    expect(candidate.id, 37125831);
    expect(candidate.title, '夺命许愿');
    expect(candidate.originalTitle, '기리고');
    expect(candidate.subtype, 'tv');
    expect(candidate.year, 2026);
    expect(candidate.rating, 7.6);
    expect(candidate.genres, ['剧情', '恐怖']);
    expect(candidate.casts, ['全昭映', '姜美娜']);
    expect(candidate.directors, ['朴允书']);
    expect(
      candidate.posterPath,
      'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2931885934.jpg',
    );
  });

  test('tolerates numeric ids and missing fields', () {
    final candidates = DoubanClient.parseCandidates({
      'subjects': [
        {'id': 42, 'title': '数字 ID'},
        {'id': 'not-a-number', 'title': '无效 ID'},
        {'title': '没有 ID'},
      ],
    });

    expect(candidates, hasLength(1));
    expect(candidates.single.id, 42);
    expect(candidates.single.year, isNull);
    expect(candidates.single.rating, isNull);
  });

  test('returns empty list when subjects is missing', () {
    expect(DoubanClient.parseCandidates({'total': 0}), isEmpty);
  });

  test('parses subject detail including summary, episode count and aka', () {
    final subject = DoubanClient.parseSubject({
      'id': '37125831',
      'title': '夺命许愿',
      'original_title': '기리고',
      'subtype': 'tv',
      'year': '2026',
      'episodes_count': '8',
      'rating': {'average': 7.6},
      'genres': ['剧情', '恐怖'],
      'images': {
        'medium':
            'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2931885934.jpg',
      },
      'summary': '瑞麟高中的五名好友意外接触到一款名为“Girigo”的神秘APP……',
      'aka': ['为了纪念', 'Wish Your Death', 'If Wishes Could Kill', 'Girigo'],
    });

    expect(subject, isNotNull);
    expect(subject!.id, 37125831);
    expect(subject.episodeCount, 8);
    expect(subject.overview, contains('Girigo'));
    expect(subject.aka, contains('If Wishes Could Kill'));
    expect(subject.genres, ['剧情', '恐怖']);
  });

  test('returns null for an invalid subject payload', () {
    expect(DoubanClient.parseSubject({'msg': 'invalid_apikey'}), isNull);
  });

  test('accepts a translated title when Douban returns one result', () {
    final candidates = DoubanClient.parseCandidates({
      'subjects': [
        {
          'id': '37125831',
          'title': '夺命许愿',
          'original_title': '기리고',
          'subtype': 'tv',
          'year': '2026',
        },
      ],
    });

    final match = DoubanMatcher.best(
      candidates,
      title: 'If Wishes Could Kill',
    );
    expect(match?.id, 37125831);
  });

  test('trusts Douban relevance order for Latin titles with multiple results',
      () {
    final candidates = DoubanClient.parseCandidates({
      'subjects': [
        {'id': '1', 'title': '夺命许愿', 'year': '2026'},
        {'id': '2', 'title': '另一个条目', 'year': '2026'},
      ],
    });

    final match = DoubanMatcher.best(
      candidates,
      title: 'If Wishes Could Kill',
    );
    expect(match?.id, 1);
  });

  test('still prefers an exact title match over order', () {
    final candidates = DoubanClient.parseCandidates({
      'subjects': [
        {'id': '1', 'title': '另一个条目', 'year': '2020'},
        {'id': '2', 'title': '夺命许愿', 'original_title': 'If Wishes Could Kill'},
      ],
    });

    final match = DoubanMatcher.best(
      candidates,
      title: 'If Wishes Could Kill',
    );
    expect(match?.id, 2);
  });
}
