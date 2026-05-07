import '../app_database.dart';
import '../tables/unit_table.dart';
import 'dao_result.dart';
import '../../../view/masters/unit/unit_model.dart';

class UnitDao {
  Future<DaoResult<Unit>> create(Unit unit) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      await db.insert(UnitTable.tableName, {
        'id': unit.id,
        'name': unit.name,
        'symbol': unit.symbol,
        'allow_decimal': unit.allowDecimal ? 1 : 0,
        'description': unit.description,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      return DaoResult.success(unit);
    } catch (e) {
      return DaoResult.failure('Failed to create unit', exception: e);
    }
  }

  Future<DaoResult<Unit>> update(Unit unit) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        UnitTable.tableName,
        {
          'name': unit.name,
          'symbol': unit.symbol,
          'allow_decimal': unit.allowDecimal ? 1 : 0,
          'description': unit.description,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [unit.id],
      );

      if (rows == 0) {
        return DaoResult.failure('Unit not found for update');
      }

      return DaoResult.success(unit);
    } catch (e) {
      return DaoResult.failure('Failed to update unit', exception: e);
    }
  }

  Future<DaoResult<int>> deactivate(String id) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        UnitTable.tableName,
        {'is_active': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to deactivate unit', exception: e);
    }
  }

  Future<DaoResult<int>> delete(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.delete(
        UnitTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to delete unit', exception: e);
    }
  }

  Future<DaoResult<Unit?>> getById(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        UnitTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(_fromRow(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to load unit by id', exception: e);
    }
  }

  Future<DaoResult<List<Unit>>> getAll({bool activeOnly = true}) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        UnitTable.tableName,
        where: activeOnly ? 'is_active = ?' : null,
        whereArgs: activeOnly ? [1] : null,
        orderBy: 'name COLLATE NOCASE ASC',
      );

      return DaoResult.success(rows.map(_fromRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load units', exception: e);
    }
  }

  Future<DaoResult<List<Unit>>> searchByName(
    String query, {
    bool activeOnly = true,
    int limit = 20,
  }) async {
    try {
      final db = await AppDatabase.database;
      final q = query.trim();
      if (q.isEmpty) {
        return DaoResult.success(const []);
      }

      final whereParts = <String>['name LIKE ?'];
      final args = <Object?>['%$q%'];
      if (activeOnly) {
        whereParts.add('is_active = ?');
        args.add(1);
      }

      final rows = await db.query(
        UnitTable.tableName,
        where: whereParts.join(' AND '),
        whereArgs: args,
        orderBy: 'name COLLATE NOCASE ASC',
        limit: limit,
      );

      return DaoResult.success(rows.map(_fromRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to search units', exception: e);
    }
  }

  Future<DaoResult<int>> countUnits({bool activeOnly = true}) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${UnitTable.tableName}${activeOnly ? ' WHERE is_active = 1' : ''}',
      );
      final count = (rows.first['count'] as int?) ?? 0;
      return DaoResult.success(count);
    } catch (e) {
      return DaoResult.failure('Failed to count units', exception: e);
    }
  }

  Unit _fromRow(Map<String, Object?> row) {
    return Unit(
      id: row['id'] as String,
      name: row['name'] as String,
      symbol: row['symbol'] as String,
      allowDecimal: ((row['allow_decimal'] as num?) ?? 0) == 1,
      description: row['description'] as String?,
    );
  }
}
