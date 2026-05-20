import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Local persistence for session aggregates used by federated sync.
class SessionDatabase {
  SessionDatabase._();

  static const _dbName = 'lenslife.db';
  static const _dbVersion = 2;
  static const statsRowId = 1;

  static Database? _database;

  static Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    _database = await _open();
    return _database!;
  }

  static Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY,
            baseline_mean REAL NOT NULL DEFAULT 0,
            baseline_M2 REAL NOT NULL DEFAULT 0,
            session_count INTEGER NOT NULL DEFAULT 0,
            cluster_id TEXT,
            prior_mean REAL,
            prior_std REAL
          )
        ''');
        await db.insert('sessions', {'id': statsRowId});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(db, 'prior_mean', 'REAL');
          await _addColumnIfMissing(db, 'prior_std', 'REAL');
        }
      },
    );
  }

  static Future<void> _addColumnIfMissing(
    Database db,
    String column,
    String sqlType,
  ) async {
    final info = await db.rawQuery('PRAGMA table_info(sessions)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE sessions ADD COLUMN $column $sqlType');
    }
  }

  /// Persists onboarding cluster hash once; never recomputed per session.
  static Future<void> saveClusterId(String clusterId) async {
    final db = await database;
    await db.update(
      'sessions',
      {'cluster_id': clusterId},
      where: 'id = ?',
      whereArgs: [statsRowId],
    );
  }

  /// Records one session ΔT and updates Welford baseline stats.
  static Future<void> recordSessionDeltaT(double deltaT) async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [statsRowId],
      limit: 1,
    );

    if (rows.isEmpty) {
      await db.insert('sessions', {'id': statsRowId});
    }

    final row = rows.isEmpty ? <String, Object?>{'id': statsRowId} : rows.first;
    var mean = (row['baseline_mean'] as num?)?.toDouble() ?? 0.0;
    var m2 = (row['baseline_M2'] as num?)?.toDouble() ?? 0.0;
    var count = (row['session_count'] as int?) ?? 0;

    count += 1;
    final delta = deltaT - mean;
    mean += delta / count;
    final delta2 = deltaT - mean;
    m2 += delta * delta2;

    await db.update(
      'sessions',
      {
        'baseline_mean': mean,
        'baseline_M2': m2,
        'session_count': count,
      },
      where: 'id = ?',
      whereArgs: [statsRowId],
    );
  }

  static Future<Map<String, dynamic>> readStatsRow() async {
    final db = await database;
    final rows = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [statsRowId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return {
        'baseline_mean': 0.0,
        'baseline_M2': 0.0,
        'session_count': 0,
        'cluster_id': null,
        'prior_mean': null,
        'prior_std': null,
      };
    }
    return rows.first;
  }

  static Future<void> writePriors(double priorMean, double priorStd) async {
    final db = await database;
    await db.update(
      'sessions',
      {
        'prior_mean': priorMean,
        'prior_std': priorStd,
      },
      where: 'id = ?',
      whereArgs: [statsRowId],
    );
  }
}
