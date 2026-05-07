import '../app_database.dart';
import '../tables/product_table.dart';
import '../tables/unit_table.dart';
import 'dao_result.dart';
import '../../../view/masters/product/product_model.dart';
import '../../../view/masters/unit/unit_model.dart';

class ProductDao {
  Future<DaoResult<Product>> create(Product product) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      await db.insert(ProductTable.tableName, {
        'id': product.id,
        'name': product.name,
        'type': product.type.name,
        'unit_id': product.unit.id,
        'default_rate': product.defaultRate,
        'description': product.description,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      });

      return DaoResult.success(product);
    } catch (e) {
      return DaoResult.failure('Failed to create product', exception: e);
    }
  }

  Future<DaoResult<Product>> update(Product product) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        ProductTable.tableName,
        {
          'name': product.name,
          'type': product.type.name,
          'unit_id': product.unit.id,
          'default_rate': product.defaultRate,
          'description': product.description,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [product.id],
      );

      if (rows == 0) {
        return DaoResult.failure('Product not found for update');
      }

      return DaoResult.success(product);
    } catch (e) {
      return DaoResult.failure('Failed to update product', exception: e);
    }
  }

  Future<DaoResult<int>> deactivate(String id) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        ProductTable.tableName,
        {'is_active': 0, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to deactivate product', exception: e);
    }
  }

  Future<DaoResult<int>> delete(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.delete(
        ProductTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to delete product', exception: e);
    }
  }

  Future<DaoResult<Product?>> getById(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          p.id AS p_id,
          p.name AS p_name,
          p.type AS p_type,
          p.default_rate AS p_default_rate,
          p.description AS p_description,
          u.id AS u_id,
          u.name AS u_name,
          u.symbol AS u_symbol,
          u.allow_decimal AS u_allow_decimal,
          u.description AS u_description
        FROM ${ProductTable.tableName} p
        INNER JOIN ${UnitTable.tableName} u ON u.id = p.unit_id
        WHERE p.id = ?
        LIMIT 1
        ''',
        [id],
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(_fromJoinedRow(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to load product by id', exception: e);
    }
  }

  Future<DaoResult<List<Product>>> getAll({bool activeOnly = true}) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery('''
        SELECT
          p.id AS p_id,
          p.name AS p_name,
          p.type AS p_type,
          p.default_rate AS p_default_rate,
          p.description AS p_description,
          u.id AS u_id,
          u.name AS u_name,
          u.symbol AS u_symbol,
          u.allow_decimal AS u_allow_decimal,
          u.description AS u_description
        FROM ${ProductTable.tableName} p
        INNER JOIN ${UnitTable.tableName} u ON u.id = p.unit_id
        ${activeOnly ? 'WHERE p.is_active = 1' : ''}
        ORDER BY p.name COLLATE NOCASE ASC
        ''');

      return DaoResult.success(rows.map(_fromJoinedRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load products', exception: e);
    }
  }

  Future<DaoResult<List<Product>>> searchByName(
    String query, {
    bool activeOnly = true,
    int limit = 30,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) {
        return DaoResult.success(const []);
      }

      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          p.id AS p_id,
          p.name AS p_name,
          p.type AS p_type,
          p.default_rate AS p_default_rate,
          p.description AS p_description,
          u.id AS u_id,
          u.name AS u_name,
          u.symbol AS u_symbol,
          u.allow_decimal AS u_allow_decimal,
          u.description AS u_description
        FROM ${ProductTable.tableName} p
        INNER JOIN ${UnitTable.tableName} u ON u.id = p.unit_id
        WHERE p.name LIKE ? ${activeOnly ? 'AND p.is_active = 1' : ''}
        ORDER BY p.name COLLATE NOCASE ASC
        LIMIT ?
        ''',
        ['%$q%', limit],
      );

      return DaoResult.success(rows.map(_fromJoinedRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to search products', exception: e);
    }
  }

  Future<DaoResult<List<Product>>> getByUnitId(
    String unitId, {
    bool activeOnly = true,
  }) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        '''
        SELECT
          p.id AS p_id,
          p.name AS p_name,
          p.type AS p_type,
          p.default_rate AS p_default_rate,
          p.description AS p_description,
          u.id AS u_id,
          u.name AS u_name,
          u.symbol AS u_symbol,
          u.allow_decimal AS u_allow_decimal,
          u.description AS u_description
        FROM ${ProductTable.tableName} p
        INNER JOIN ${UnitTable.tableName} u ON u.id = p.unit_id
        WHERE p.unit_id = ? ${activeOnly ? 'AND p.is_active = 1' : ''}
        ORDER BY p.name COLLATE NOCASE ASC
        ''',
        [unitId],
      );

      return DaoResult.success(rows.map(_fromJoinedRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load products by unit', exception: e);
    }
  }

  Future<DaoResult<int>> countProducts({bool activeOnly = true}) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${ProductTable.tableName}${activeOnly ? ' WHERE is_active = 1' : ''}',
      );
      final count = (rows.first['count'] as int?) ?? 0;
      return DaoResult.success(count);
    } catch (e) {
      return DaoResult.failure('Failed to count products', exception: e);
    }
  }

  Product _fromJoinedRow(Map<String, Object?> row) {
    final unit = Unit(
      id: row['u_id'] as String,
      name: row['u_name'] as String,
      symbol: row['u_symbol'] as String,
      allowDecimal: ((row['u_allow_decimal'] as num?) ?? 0) == 1,
      description: row['u_description'] as String?,
    );

    final typeName = (row['p_type'] as String?) ?? ProductType.material.name;
    final parsedType = ProductType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => ProductType.material,
    );

    return Product(
      id: row['p_id'] as String,
      name: row['p_name'] as String,
      type: parsedType,
      unit: unit,
      defaultRate: (row['p_default_rate'] as num?)?.toDouble() ?? 0,
      description: row['p_description'] as String?,
    );
  }
}
