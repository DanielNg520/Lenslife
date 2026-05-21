import 'package:sqflite/sqflite.dart';

import '../services/session_database.dart';
import 'welford_state.dart';

class WelfordRepository {
  final Database db;

  WelfordRepository(this.db);

  static Future<WelfordRepository> open() async {
    return WelfordRepository(await SessionDatabase.database);
  }

  Future<WelfordState> load(String feature) async {
    final rows = await db.query(
      'welford_state',
      where: 'feature = ?',
      whereArgs: [feature],
    );
    if (rows.isEmpty) {
      return const WelfordState();
    }
    return WelfordState.fromMap(rows.first);
  }

  Future<void> save(String feature, WelfordState state) async {
    await db.insert(
      'welford_state',
      state.toMap(feature),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
