import 'dart:async';

import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'library_source.dart';
import 'models.dart';

class MediaRepository {
  MediaRepository(this._database);

  final AppDatabase _database;
  int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<Database> get _db => _database.database;

  // ---------------------------------------------------------------- sources

  Future<List<LibrarySource>> sources() async {
    final db = await _db;
    final rows = await db.query('sources', orderBy: 'added_at ASC');
    return rows.map(LibrarySource.fromMap).toList();
  }

  Future<int> addSource({
    required String path,
    required String name,
    String? uri,
  }) async {
    final db = await _db;
    final existing = await db.query(
      'sources',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return db.insert('sources', {
      'path': path,
      'uri': uri,
      'name': name,
      'added_at': _now(),
    });
  }

  Future<void> touchSource(int sourceId) async {
    final db = await _db;
    await db.update(
      'sources',
      {'last_scan_at': _now()},
      where: 'id = ?',
      whereArgs: [sourceId],
    );
  }

  Future<void> removeSource(int sourceId) async {
    final db = await _db;
    await db.delete('sources', where: 'id = ?', whereArgs: [sourceId]);
  }

  // ------------------------------------------------------------------ media

  Future<List<MediaItem>> allMedia() async {
    final db = await _db;
    final rows = await db.query('media', orderBy: 'added_at DESC');
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<List<MediaItem>> movies() async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: 'kind = ?',
      whereArgs: [MediaKind.movie.dbValue],
      orderBy: 'added_at DESC',
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<List<MediaItem>> episodes() async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: 'kind = ?',
      whereArgs: [MediaKind.episode.dbValue],
      orderBy: 'added_at DESC',
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<MediaItem?> mediaById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : MediaItem.fromMap(rows.first);
  }

  Future<MediaItem?> mediaByPath(String path) async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: 'path = ?',
      whereArgs: [path],
      limit: 1,
    );
    return rows.isEmpty ? null : MediaItem.fromMap(rows.first);
  }

  Future<List<MediaItem>> episodesForSeries(String seriesKey) async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: 'series_key = ?',
      whereArgs: [seriesKey],
      orderBy: 'season ASC, episode ASC',
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  Future<List<MediaItem>> pendingItems() async {
    final db = await _db;
    final rows = await db.query(
      'media',
      where: "scrape_state IN ('pending', 'failed')",
      orderBy: 'added_at ASC',
    );
    return rows.map(MediaItem.fromMap).toList();
  }

  /// Writes a scan result to the database, preserving existing scrape data.
  /// Returns (added, removed) counts.
  Future<({int added, int removed})> applyScan(
    int sourceId,
    List<MediaItem> scanned,
  ) async {
    final db = await _db;
    final existingRows = await db.query(
      'media',
      columns: ['id', 'path', 'scrape_state', 'source_id'],
    );
    final existingByPath = {
      for (final row in existingRows)
        row['path'] as String: (
          id: row['id'] as int,
          sourceId: row['source_id'] as int,
          scraped: row['scrape_state'] == ScrapeState.done.dbValue,
        ),
    };
    final seen = <String>{};
    final now = _now();
    var added = 0;

    final removed = await db.transaction((txn) async {
      final batch = txn.batch();
      for (final item in scanned) {
        seen.add(item.path);
        final existing = existingByPath[item.path];
        if (existing == null) {
          added++;
          final map = item.toMap()
            ..remove('id')
            ..['source_id'] = sourceId
            ..['added_at'] = item.addedAt
            ..['updated_at'] = now;
          batch.insert('media', map);
        } else {
          final values = <String, Object?>{
            'source_id': sourceId,
            'file_name': item.fileName,
            'size': item.size,
            'modified_at': item.modifiedAt,
            'updated_at': now,
          };
          if (item.localPoster != null) {
            values['local_poster'] = item.localPoster;
          }
          if (item.localBackdrop != null) {
            values['local_backdrop'] = item.localBackdrop;
          }
          if (item.nfoPath != null) values['nfo_path'] = item.nfoPath;

          // Until TMDB has matched the row, refresh the filename-derived
          // title and parsed season/episode data on every scan.
          if (!existing.scraped) {
            values.addAll({
              'title': item.title,
              'year': item.year,
              'kind': item.kind.dbValue,
              'season': item.season,
              'episode': item.episode,
              'series_key': item.seriesKey,
              'series_title': item.seriesTitle,
            });
          }

          batch.update(
            'media',
            values,
            where: 'id = ?',
            whereArgs: [existing.id],
          );
        }
      }

      final removedIds = <int>[];
      for (final entry in existingByPath.entries) {
        if (entry.value.sourceId == sourceId && !seen.contains(entry.key)) {
          removedIds.add(entry.value.id);
        }
      }
      if (removedIds.isNotEmpty) {
        final placeholders = List.filled(removedIds.length, '?').join(',');
        batch.delete(
          'media',
          where: 'id IN ($placeholders)',
          whereArgs: removedIds,
        );
      }
      await batch.commit(noResult: true);
      return removedIds.length;
    });

    return (added: added, removed: removed);
  }

  Future<void> applyMetadata(int mediaId, ScrapedMetadata metadata) async {
    final values = metadata.toDbUpdate();
    if (values.isEmpty) return;
    values['updated_at'] = _now();
    final db = await _db;
    await db.update('media', values, where: 'id = ?', whereArgs: [mediaId]);
  }

  /// Applies show-level metadata to every episode of a series.
  Future<void> applySeriesMetadata(
    String seriesKey,
    ScrapedMetadata metadata,
  ) async {
    final values = <String, Object?>{};
    void put(String key, Object? value) {
      if (value != null) values[key] = value;
    }

    put('series_title', metadata.seriesTitle);
    put('year', metadata.year);
    put('overview', metadata.overview);
    put('poster_path', metadata.posterPath);
    put('backdrop_path', metadata.backdropPath);
    put('rating', metadata.rating);
    put('tmdb_id', metadata.tmdbId);
    put('imdb_id', metadata.imdbId);
    put('series_key', metadata.seriesKey);
    if (metadata.genres != null && metadata.genres!.isNotEmpty) {
      values['genres'] = metadata.genres!.join('\u001f');
    }
    if (values.isEmpty) return;
    values['updated_at'] = _now();
    final db = await _db;
    await db.update(
      'media',
      values,
      where: 'series_key = ?',
      whereArgs: [seriesKey],
    );
  }

  Future<void> renameSeriesKey(String oldKey, String newKey) async {
    final db = await _db;
    await db.update(
      'media',
      {'series_key': newKey, 'updated_at': _now()},
      where: 'series_key = ?',
      whereArgs: [oldKey],
    );
  }

  Future<void> setScrapeState(
    int mediaId,
    ScrapeState state, {
    String? error,
  }) async {
    final db = await _db;
    await db.update(
      'media',
      {
        'scrape_state': state.dbValue,
        'scrape_error': error,
        'updated_at': _now(),
      },
      where: 'id = ?',
      whereArgs: [mediaId],
    );
  }

  Future<void> setSeriesScrapeState(
    String seriesKey,
    ScrapeState state, {
    String? error,
  }) async {
    final db = await _db;
    await db.update(
      'media',
      {
        'scrape_state': state.dbValue,
        'scrape_error': error,
        'updated_at': _now(),
      },
      where: 'series_key = ?',
      whereArgs: [seriesKey],
    );
  }

  // --------------------------------------------------------------- progress

  Future<void> saveProgress({
    required int mediaId,
    required int positionMs,
    required int durationMs,
    bool completed = false,
  }) async {
    final db = await _db;
    await db.insert('progress', {
      'media_id': mediaId,
      'position_ms': positionMs < 0 ? 0 : positionMs,
      'duration_ms': durationMs < 0 ? 0 : durationMs,
      'updated_at': _now(),
      'completed': completed ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markCompleted(int mediaId, {int durationMs = 0}) async {
    await saveProgress(
      mediaId: mediaId,
      positionMs: durationMs,
      durationMs: durationMs,
      completed: true,
    );
  }

  Future<void> deleteProgress(int mediaId) async {
    final db = await _db;
    await db.delete('progress', where: 'media_id = ?', whereArgs: [mediaId]);
  }

  Future<PlaybackProgress?> progressFor(int mediaId) async {
    final db = await _db;
    final rows = await db.query(
      'progress',
      where: 'media_id = ?',
      whereArgs: [mediaId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return PlaybackProgress(
      mediaId: row['media_id'] as int,
      positionMs: row['position_ms'] as int? ?? 0,
      durationMs: row['duration_ms'] as int? ?? 0,
      updatedAt: row['updated_at'] as int? ?? 0,
      completed: (row['completed'] as int? ?? 0) == 1,
    );
  }

  Future<Map<int, PlaybackProgress>> allProgress() async {
    final db = await _db;
    final rows = await db.query('progress');
    return {
      for (final row in rows)
        row['media_id'] as int: PlaybackProgress(
          mediaId: row['media_id'] as int,
          positionMs: row['position_ms'] as int? ?? 0,
          durationMs: row['duration_ms'] as int? ?? 0,
          updatedAt: row['updated_at'] as int? ?? 0,
          completed: (row['completed'] as int? ?? 0) == 1,
        ),
    };
  }

  Future<List<ContinueItem>> continueWatching({int limit = 12}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT m.*, p.position_ms, p.duration_ms, p.updated_at AS p_updated_at,
             p.completed AS p_completed
      FROM media m
      JOIN progress p ON p.media_id = m.id
      WHERE p.completed = 0
        AND p.position_ms > 20000
        AND (p.duration_ms = 0 OR p.position_ms < p.duration_ms * 0.96)
      ORDER BY p.updated_at DESC
      LIMIT 100
    ''');
    final result = <ContinueItem>[];
    final seenSeries = <String>{};
    for (final row in rows) {
      final media = MediaItem.fromMap(row);
      if (media.isEpisode && media.seriesKey != null) {
        if (!seenSeries.add(media.seriesKey!)) continue;
      }
      result.add(
        ContinueItem(
          media: media,
          progress: PlaybackProgress(
            mediaId: media.id!,
            positionMs: row['position_ms'] as int? ?? 0,
            durationMs: row['duration_ms'] as int? ?? 0,
            updatedAt: row['p_updated_at'] as int? ?? 0,
            completed: (row['p_completed'] as int? ?? 0) == 1,
          ),
        ),
      );
      if (result.length >= limit) break;
    }
    return result;
  }

  // ------------------------------------------------------------------ admin

  Future<({int movies, int episodes, int series, int progress})> stats() async {
    final db = await _db;
    final movieRows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM media WHERE kind = 'movie'",
    );
    final episodeRows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM media WHERE kind = 'episode'",
    );
    final seriesRows = await db.rawQuery(
      "SELECT COUNT(DISTINCT series_key) AS c FROM media WHERE series_key IS NOT NULL",
    );
    final progressRows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM progress WHERE completed = 0 AND position_ms > 20000',
    );
    return (
      movies: (movieRows.first['c'] as int?) ?? 0,
      episodes: (episodeRows.first['c'] as int?) ?? 0,
      series: (seriesRows.first['c'] as int?) ?? 0,
      progress: (progressRows.first['c'] as int?) ?? 0,
    );
  }

  Future<void> clearLibrary() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('progress');
      await txn.delete('media');
      await txn.delete('sources');
    });
  }
}
