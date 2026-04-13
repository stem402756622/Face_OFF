import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/analysis_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const _dbName = 'faceoff.db';
  static const _dbVersion = 2;
  static const _legacyImportKey = 'legacy_sqlite_import';

  DatabaseHelper._init() {
    // Initialize sqflite for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    await _migrateLegacyIfNeeded(db);
    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schema_meta (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE analysis_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attractivenessScore REAL NOT NULL,
        bestAngle TEXT NOT NULL,
        bestAngleDescription TEXT NOT NULL,
        overallAnalysis TEXT NOT NULL,
        imageBase64 TEXT NOT NULL,
        facialFeaturesJson TEXT NOT NULL,
        medicalCondition TEXT NOT NULL,
        medicalSeverity TEXT NOT NULL,
        medicalDescription TEXT NOT NULL,
        medicalRecommendationsJson TEXT NOT NULL,
        medicalTreatmentsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cacheKey TEXT UNIQUE NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        expiresAt TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_analysis_history_created_at ON analysis_history (createdAt DESC)',
    );
    await db.execute('CREATE INDEX idx_cache_key ON api_cache(cacheKey)');
    await db.execute('CREATE INDEX idx_expires_at ON api_cache(expiresAt)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schema_meta (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS api_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cacheKey TEXT UNIQUE NOT NULL,
          data TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          expiresAt TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cache_key ON api_cache(cacheKey)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expires_at ON api_cache(expiresAt)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_analysis_history_created_at ON analysis_history (createdAt DESC)',
      );
    }
  }

  Future<void> _migrateLegacyIfNeeded(Database db) async {
    final done = await db.query(
      'schema_meta',
      where: 'key = ?',
      whereArgs: [_legacyImportKey],
      limit: 1,
    );
    if (done.isNotEmpty) return;

    final dir = await getDatabasesPath();

    try {
      await db.transaction((txn) async {
        final analysisPath = join(dir, 'face_analysis.db');
        if (await File(analysisPath).exists()) {
          Database? leg;
          try {
            leg = await openDatabase(analysisPath, readOnly: true);
            final rows = await leg.query('analysis_history');
            for (final row in rows) {
              await txn.insert(
                'analysis_history',
                row,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          } finally {
            await leg?.close();
          }
        }

        final cachePath = join(dir, 'api_cache.db');
        if (await File(cachePath).exists()) {
          Database? leg;
          try {
            leg = await openDatabase(cachePath, readOnly: true);
            final rows = await leg.query('api_cache');
            for (final row in rows) {
              await txn.insert(
                'api_cache',
                row,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          } finally {
            await leg?.close();
          }
        }

        await txn.insert('schema_meta', {
          'key': _legacyImportKey,
          'value': DateTime.now().toIso8601String(),
        });
      });
    } catch (e, st) {
      debugPrint('Legacy DB import failed: $e\n$st');
    }
  }

  Future<int> insertAnalysis(AnalysisHistory history) async {
    final db = await database;
    return await db.insert('analysis_history', history.toMap());
  }

  Future<int> updateAnalysis(AnalysisHistory history) async {
    final db = await database;
    return await db.update(
      'analysis_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  Future<AnalysisHistory?> getTodayAnalysis() async {
    final db = await database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final maps = await db.query(
      'analysis_history',
      where: 'createdAt >= ? AND createdAt < ?',
      whereArgs: [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return AnalysisHistory.fromMap(maps.first);
    }
    return null;
  }

  Future<List<AnalysisHistory>> getAllAnalyses() async {
    final db = await database;
    final maps = await db.query('analysis_history', orderBy: 'createdAt DESC');

    return maps.map((map) => AnalysisHistory.fromMap(map)).toList();
  }

  Future<AnalysisHistory?> getAnalysisById(int id) async {
    final db = await database;
    final maps = await db.query(
      'analysis_history',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return AnalysisHistory.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteAnalysis(int id) async {
    final db = await database;
    return await db.delete(
      'analysis_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllAnalyses() async {
    final db = await database;
    return await db.delete('analysis_history');
  }

  Future<int> getAnalysisCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM analysis_history',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
