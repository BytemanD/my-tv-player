import 'dart:io';

import 'package:xml/xml.dart';

class NfoData {
  const NfoData({
    this.title,
    this.originalTitle,
    this.plot,
    this.year,
    this.tmdbId,
    this.imdbId,
    this.rating,
    this.runtime,
    this.genres = const [],
    this.poster,
    this.fanart,
    this.premiered,
    this.season,
    this.episode,
    this.showTitle,
  });

  final String? title;
  final String? originalTitle;
  final String? plot;
  final int? year;
  final int? tmdbId;
  final String? imdbId;
  final double? rating;
  final int? runtime;
  final List<String> genres;
  final String? poster;
  final String? fanart;
  final String? premiered;
  final int? season;
  final int? episode;
  final String? showTitle;

  bool get hasUsefulData =>
      title != null ||
      plot != null ||
      year != null ||
      tmdbId != null ||
      imdbId != null ||
      poster != null ||
      fanart != null;

  String? get preferredTitle => (title != null && title!.trim().isNotEmpty)
      ? title!.trim()
      : originalTitle;
}

class NfoParser {
  static Future<NfoData?> parseFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      return parse(content);
    } catch (_) {
      return null;
    }
  }

  static NfoData? parse(String content) {
    if (content.trim().isEmpty) return null;
    try {
      final document = XmlDocument.parse(content);
      final root = document.rootElement;
      final rootName = root.name.local.toLowerCase();
      if (rootName != 'movie' &&
          rootName != 'tvshow' &&
          rootName != 'episodedetails') {
        return null;
      }

      final tmdbId =
          _findUniqueId(root, 'tmdb') ??
          _int(_text(root, ['tmdbid'])) ??
          (rootName == 'movie' ? _int(_text(root, ['id'])) : null);
      final imdbId = _findUniqueTextId(root, 'imdb') ?? _text(root, ['imdbid']);

      final ratingElement = root.findElements('ratings').isEmpty
          ? root
          : root.findElements('ratings').first;
      final rating = _double(
        _nestedText(ratingElement, ['rating', 'value']) ??
            _text(root, ['rating']),
      );

      final fanartRoot = root.findElements('fanart').isNotEmpty
          ? root.findElements('fanart').first
          : null;
      final fanart =
          _nestedText(fanartRoot, ['thumb']) ??
          _nestedText(
            root.findElements('art').isNotEmpty
                ? root.findElements('art').first
                : null,
            ['fanart'],
          );

      final poster =
          _text(root, ['poster']) ??
          _nestedText(
            root.findElements('art').isNotEmpty
                ? root.findElements('art').first
                : null,
            ['poster'],
          );

      final genres = root
          .findAllElements('genre')
          .map((e) => e.innerText.trim())
          .where((g) => g.isNotEmpty)
          .toSet()
          .toList();

      return NfoData(
        title: _text(root, ['title']),
        originalTitle: _text(root, ['originaltitle']),
        plot: _text(root, ['plot']) ?? _text(root, ['outline']),
        year: _int(_text(root, ['year'])),
        tmdbId: tmdbId,
        imdbId: imdbId,
        rating: rating,
        runtime: _int(_text(root, ['runtime'])),
        genres: genres,
        poster: poster,
        fanart: fanart,
        premiered:
            _text(root, ['premiered']) ??
            _text(root, ['releasedate']) ??
            _text(root, ['aired']),
        season: _int(_text(root, ['season'])),
        episode: _int(_text(root, ['episode'])),
        showTitle: _text(root, ['showtitle']),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _findUniqueTextId(XmlElement root, String type) {
    for (final element in root.findElements('uniqueid')) {
      final idType = element.getAttribute('type')?.toLowerCase();
      if (idType == type) {
        final value = element.innerText.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static int? _findUniqueId(XmlElement root, String type) {
    for (final element in root.findElements('uniqueid')) {
      final idType = element.getAttribute('type')?.toLowerCase();
      if (idType == type) {
        final value = int.tryParse(element.innerText.trim());
        if (value != null) return value;
      }
    }
    return null;
  }

  static String? _text(XmlElement element, List<String> names) {
    for (final name in names) {
      for (final child in element.findElements(name)) {
        final value = child.innerText.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  static String? _nestedText(XmlElement? element, List<String> names) {
    if (element == null) return null;
    return _text(element, names);
  }

  static int? _int(String? value) {
    if (value == null) return null;
    final match = RegExp(r'-?\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static double? _double(String? value) {
    if (value == null) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }
}
