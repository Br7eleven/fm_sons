import '../app_database.dart';
import '../models/terms_condition_model.dart';
import '../tables/terms_conditions_table.dart';

class TermsConditionDao {
  Future<List<TermsCondition>> getAll() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      TermsConditionTable.tableName,
      orderBy: 'created_at DESC',
    );
    return rows.map(TermsCondition.fromMap).toList();
  }

  Future<List<TermsCondition>> getByType(String type) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      TermsConditionTable.tableName,
      where: 'applicable_for LIKE ?',
      whereArgs: ['%$type%'],
      orderBy: 'created_at DESC',
    );
    return rows.map(TermsCondition.fromMap).toList();
  }

  Future<int> insert(TermsCondition tc) async {
    final db = await AppDatabase.database;
    return db.insert(
      TermsConditionTable.tableName,
      tc.toMap(),
    );
  }

  Future<int> delete(int id) async {
    final db = await AppDatabase.database;
    return db.delete(
      TermsConditionTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<TermsCondition?> getById(int id) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      TermsConditionTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TermsCondition.fromMap(rows.first);
  }
}
