import '../app_database.dart';
import '../tables/customer_table.dart';
import 'dao_result.dart';
import '../../../view/masters/customer/customer_model.dart';

class CustomerDao {
  Future<DaoResult<Customer>> create(Customer customer) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      await db.insert(CustomerTable.tableName, {
        ...customer.toMap(),
        'created_at': now,
        'updated_at': now,
      });

      return DaoResult.success(customer);
    } catch (e) {
      return DaoResult.failure('Failed to create customer', exception: e);
    }
  }

  Future<DaoResult<Customer>> update(Customer customer) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        CustomerTable.tableName,
        {
          'name': customer.name,
          'phone': customer.phone,
          'address': customer.address,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      if (rows == 0) {
        return DaoResult.failure('Customer not found for update');
      }

      return DaoResult.success(customer);
    } catch (e) {
      return DaoResult.failure('Failed to update customer', exception: e);
    }
  }

  Future<DaoResult<int>> delete(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.delete(
        CustomerTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to delete customer', exception: e);
    }
  }

  Future<DaoResult<Customer?>> getById(String id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        CustomerTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(_fromRow(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to load customer by id', exception: e);
    }
  }

  Future<DaoResult<Customer?>> findByName(String name) async {
    try {
      final db = await AppDatabase.database;
      final query = name.trim();
      if (query.isEmpty) {
        return DaoResult.success(null);
      }

      final rows = await db.query(
        CustomerTable.tableName,
        where: 'name = ?',
        whereArgs: [query],
        limit: 1,
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(_fromRow(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to find customer by name', exception: e);
    }
  }

  Future<DaoResult<Customer>> addOrGetByName(String name) async {
    try {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        return DaoResult.failure('Customer name cannot be empty');
      }

      final existing = await findByName(trimmed);
      if (existing.isFailure) {
        return DaoResult.failure(existing.error ?? 'Failed to find customer');
      }
      if (existing.data != null) {
        return DaoResult.success(existing.data!);
      }

      final customer = Customer.temp(trimmed);
      final created = await create(customer);
      if (created.isFailure || created.data == null) {
        return DaoResult.failure(created.error ?? 'Failed to create customer');
      }

      return DaoResult.success(created.data!);
    } catch (e) {
      return DaoResult.failure('Failed to add or get customer', exception: e);
    }
  }

  Future<DaoResult<List<Customer>>> getAll({int? limit}) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        CustomerTable.tableName,
        orderBy: 'name COLLATE NOCASE ASC',
        limit: limit,
      );

      return DaoResult.success(rows.map(_fromRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load customers', exception: e);
    }
  }

  Future<DaoResult<List<Customer>>> searchByName(
    String query, {
    int limit = 20,
  }) async {
    try {
      final db = await AppDatabase.database;
      final q = query.trim();
      if (q.isEmpty) {
        return DaoResult.success(const []);
      }

      final rows = await db.query(
        CustomerTable.tableName,
        where: 'name LIKE ?',
        whereArgs: ['%$q%'],
        orderBy: 'name COLLATE NOCASE ASC',
        limit: limit,
      );

      return DaoResult.success(rows.map(_fromRow).toList());
    } catch (e) {
      return DaoResult.failure('Failed to search customers', exception: e);
    }
  }

  Future<DaoResult<int>> countCustomers() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${CustomerTable.tableName}',
      );
      final count = (rows.first['count'] as int?) ?? 0;
      return DaoResult.success(count);
    } catch (e) {
      return DaoResult.failure('Failed to count customers', exception: e);
    }
  }

  Customer _fromRow(Map<String, Object?> row) {
    return Customer(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      address: row['address'] as String?,
    );
  }
}
