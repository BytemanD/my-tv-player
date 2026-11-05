import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
    : _factory = factory ?? databaseFactory,
      _customPath = path;

  final DatabaseFactory _factory;
  final String? _customPath;
  Database? _db;
  Completer<Database>? _opening;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    if (_opening != null) return _opening!.future;

    final completer = Completer<Database>();
    _opening = completer;
    try {
      final dbPath = _customPath ?? p.join(await getDatabasesPath(), 'luma.db');
      final db = await _factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: _create,
        ),
      );
      _db = db;
      completer.complete(db);
      return db;
    } catch (error, stack) {
      completer.completeError(error, stack);
      rethrow;
    } finally {
      _opening = null;
    }
  }

  Future<void> _create(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path TEXT NOT NULL UNIQUE,
        uri TEXT,
        name TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        last_scan_at INTEGER
      )
    ''');
    batch.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id INTEGER NOT NULL,
        path TEXT NOT NULL UNIQUE,
        file_name TEXT NOT NULL,
        size INTEGER NOT NULL DEFAULT 0,
        modified_at INTEGER NOT NULL DEFAULT 0,
        kind TEXT NOT NULL DEFAULT 'movie',
        title TEXT NOT NULL DEFAULT '',
        year INTEGER,
        season INTEGER,
        episode INTEGER,
        series_key TEXT,
        series_title TEXT,
        tmdb_id INTEGER,
        imdb_id TEXT,
        overview TEXT,
        poster_path TEXT,
        backdrop_path TEXT,
        still_path TEXT,
        local_poster TEXT,
        local_backdrop TEXT,
        rating REAL,
        genres TEXT,
        runtime INTEGER,
        release_date TEXT,
        nfo_path TEXT,
        scrape_state TEXT NOT NULL DEFAULT 'pending',
        scrape_error TEXT,
        added_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (source_id) REFERENCES sources (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('''
      CREATE TABLE progress (
        media_id INTEGER PRIMARY KEY,
        position_ms INTEGER NOT NULL DEFAULT 0,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (media_id) REFERENCES media (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_media_kind ON media (kind)');
    batch.execute('CREATE INDEX idx_media_series_key ON media (series_key)');
    batch.execute('CREATE INDEX idx_media_added_at ON media (added_at)');
    batch.execute('CREATE INDEX idx_media_scrape ON media (scrape_state)');
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
