import 'package:flutter_test/flutter_test.dart';
import 'package:luma_tv/widgets/artwork.dart';

void main() {
  test('adds Referer for Douban image hosts', () {
    final headers = imageRequestHeaders(
      'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p1.jpg',
    );
    expect(headers, isNotNull);
    expect(headers!['Referer'], 'https://movie.douban.com/');
  });

  test('leaves TMDB image hosts untouched', () {
    expect(
      imageRequestHeaders('https://image.tmdb.org/t/p/w500/abc.jpg'),
      isNull,
    );
  });

  test('upgrades stored Douban thumbnails to large images', () {
    expect(
      upgradeDoubanImageUrl(
        'https://img3.doubanio.com/view/photo/s_ratio_poster/public/p2932167080.jpg',
      ),
      'https://img3.doubanio.com/view/photo/l/public/p2932167080.jpg',
    );
    expect(
      upgradeDoubanImageUrl(
        'https://img3.doubanio.com/view/photo/l/public/p2932167080.jpg',
      ),
      'https://img3.doubanio.com/view/photo/l/public/p2932167080.jpg',
    );
  });
}
