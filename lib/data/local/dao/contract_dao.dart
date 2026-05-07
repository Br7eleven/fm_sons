import '../app_database.dart';
import '../models/contract_model.dart';
import '../tables/contract_table.dart';
import 'dao_result.dart';

class ContractDao {
  Future<DaoResult<ContractModel>> create(ContractModel contract) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final payload = {
        'contract_number': contract.contractNumber,
        'department_name': contract.departmentName,
        'start_date': contract.startDate,
        'end_date': contract.endDate,
        'total_value': contract.totalValue,
        'status': contract.status,
        'created_at': contract.createdAt,
        'updated_at': contract.updatedAt,
      };

      final hasTimestamps =
          (contract.createdAt?.trim().isNotEmpty ?? false) &&
          (contract.updatedAt?.trim().isNotEmpty ?? false);

      if (!hasTimestamps) {
        payload['created_at'] = now;
        payload['updated_at'] = now;
      }

      final id = await db.insert(ContractTable.tableName, payload);

      return DaoResult.success(contract.copyWith(id: id));
    } catch (e) {
      return DaoResult.failure('Failed to create contract', exception: e);
    }
  }

  Future<DaoResult<ContractModel>> update(ContractModel contract) async {
    try {
      if (contract.id == null) {
        return DaoResult.failure('Contract id is required for update');
      }

      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        ContractTable.tableName,
        {
          'contract_number': contract.contractNumber,
          'department_name': contract.departmentName,
          'start_date': contract.startDate,
          'end_date': contract.endDate,
          'total_value': contract.totalValue,
          'status': contract.status,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [contract.id],
      );

      if (rows == 0) {
        return DaoResult.failure('Contract not found for update');
      }

      return DaoResult.success(contract.copyWith(updatedAt: now));
    } catch (e) {
      return DaoResult.failure('Failed to update contract', exception: e);
    }
  }

  Future<DaoResult<int>> delete(int id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.delete(
        ContractTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to delete contract', exception: e);
    }
  }

  Future<DaoResult<ContractModel?>> getById(int id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        ContractTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(ContractModel.fromMap(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to load contract by id', exception: e);
    }
  }

  Future<DaoResult<List<ContractModel>>> getAll() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        ContractTable.tableName,
        orderBy: 'created_at DESC',
      );
      return DaoResult.success(rows.map(ContractModel.fromMap).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load contracts', exception: e);
    }
  }

  Future<DaoResult<List<ContractModel>>> getActiveContracts() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        ContractTable.tableName,
        where: 'status = ?',
        whereArgs: ['active'],
        orderBy: 'created_at DESC',
      );
      return DaoResult.success(rows.map(ContractModel.fromMap).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load active contracts', exception: e);
    }
  }

  Future<DaoResult<List<ContractModel>>> searchByDepartment(
    String query, {
    int limit = 20,
  }) async {
    try {
      final q = query.trim();
      if (q.isEmpty) {
        return DaoResult.success(const []);
      }

      final db = await AppDatabase.database;
      final rows = await db.query(
        ContractTable.tableName,
        where: 'department_name LIKE ?',
        whereArgs: ['%$q%'],
        orderBy: 'department_name COLLATE NOCASE ASC',
        limit: limit,
      );

      return DaoResult.success(rows.map(ContractModel.fromMap).toList());
    } catch (e) {
      return DaoResult.failure('Failed to search contracts', exception: e);
    }
  }

  Future<DaoResult<int>> countContracts({String? status}) async {
    try {
      final db = await AppDatabase.database;
      final where = status == null ? '' : ' WHERE status = ?';
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${ContractTable.tableName}$where',
        status == null ? null : [status],
      );
      final count = (rows.first['count'] as int?) ?? 0;
      return DaoResult.success(count);
    } catch (e) {
      return DaoResult.failure('Failed to count contracts', exception: e);
    }
  }
}
