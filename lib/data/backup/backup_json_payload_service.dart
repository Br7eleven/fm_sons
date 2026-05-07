import 'dart:convert';

import '../local/app_database.dart';
import '../local/tables/contract_table.dart';
import '../local/tables/customer_table.dart';
import '../local/tables/invoice_item_table.dart';
import '../local/tables/invoice_table.dart';
import '../local/tables/product_table.dart';
import '../local/tables/unit_table.dart';

class BackupJsonPayloadService {
  static const int payloadVersion = 1;

  static const List<String> _exportOrder = [
    CustomerTable.tableName,
    UnitTable.tableName,
    ProductTable.tableName,
    ContractTable.tableName,
    InvoiceTable.tableName,
    InvoiceItemTable.tableName,
  ];

  static const List<String> _deleteOrder = [
    InvoiceItemTable.tableName,
    InvoiceTable.tableName,
    ProductTable.tableName,
    ContractTable.tableName,
    CustomerTable.tableName,
    UnitTable.tableName,
  ];

  static const Map<String, List<String>> _tableColumns = {
    CustomerTable.tableName: [
      'id',
      'name',
      'phone',
      'address',
      'created_at',
      'updated_at',
    ],
    UnitTable.tableName: [
      'id',
      'name',
      'symbol',
      'allow_decimal',
      'description',
      'is_active',
      'created_at',
      'updated_at',
    ],
    ProductTable.tableName: [
      'id',
      'name',
      'type',
      'unit_id',
      'default_rate',
      'description',
      'is_active',
      'created_at',
      'updated_at',
    ],
    ContractTable.tableName: [
      'id',
      'contract_number',
      'department_name',
      'start_date',
      'end_date',
      'total_value',
      'status',
      'created_at',
      'updated_at',
    ],
    InvoiceTable.tableName: [
      'id',
      'invoice_number',
      'customer_id',
      'client_name',
      'client_address',
      'contract_id',
      'invoice_date',
      'due_date',
      'subtotal',
      'tax',
      'total',
      'status',
      'created_at',
      'updated_at',
    ],
    InvoiceItemTable.tableName: [
      'id',
      'invoice_id',
      'product_id',
      'product_name',
      'unit_id',
      'unit_label',
      'quantity',
      'rate',
      'amount',
      'sort_order',
    ],
  };

  Future<String> buildPayloadJson() async {
    final db = await AppDatabase.database;
    final payload = <String, dynamic>{
      'version': payloadVersion,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'tables': <String, dynamic>{},
    };

    final tablesMap = payload['tables'] as Map<String, dynamic>;

    for (final tableName in _exportOrder) {
      final columns = _tableColumns[tableName]!;
      final rows = await db.query(tableName, columns: columns);
      tablesMap[tableName] = rows
          .map((row) => _normalizeRow(row, columns))
          .toList(growable: false);
    }

    return jsonEncode(payload);
  }

  Future<void> restoreFromPayloadJson(String jsonPayload) async {
    final decoded = jsonDecode(jsonPayload);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup payload root must be a JSON object');
    }

    final tables = decoded['tables'];
    if (tables is! Map<String, dynamic>) {
      throw const FormatException('Backup payload is missing "tables" object');
    }

    final db = await AppDatabase.database;

    await db.transaction((txn) async {
      for (final tableName in _deleteOrder) {
        await txn.delete(tableName);
      }

      for (final tableName in _exportOrder) {
        final rawRows = tables[tableName];
        if (rawRows == null) {
          continue;
        }

        if (rawRows is! List) {
          throw FormatException('Table "$tableName" should be a JSON array');
        }

        final columns = _tableColumns[tableName]!;
        for (final rawRow in rawRows) {
          if (rawRow is! Map) {
            throw FormatException(
              'Table "$tableName" contains a non-object row',
            );
          }

          final normalized = _normalizeIncomingRow(rawRow, columns);
          await txn.insert(tableName, normalized);
        }
      }

      await _syncAutoIncrementSequence(txn, ContractTable.tableName);
      await _syncAutoIncrementSequence(txn, InvoiceTable.tableName);
      await _syncAutoIncrementSequence(txn, InvoiceItemTable.tableName);
    });
  }

  Future<void> _syncAutoIncrementSequence(dynamic txn, String tableName) async {
    final rows = await txn.rawQuery(
      'SELECT IFNULL(MAX(id), 0) AS max_id FROM $tableName',
    );
    final maxId = (rows.first['max_id'] as num?)?.toInt() ?? 0;

    await txn.delete(
      'sqlite_sequence',
      where: 'name = ?',
      whereArgs: [tableName],
    );
    if (maxId > 0) {
      await txn.insert('sqlite_sequence', {'name': tableName, 'seq': maxId});
    }
  }

  Map<String, dynamic> _normalizeRow(
    Map<String, Object?> row,
    List<String> columns,
  ) {
    final normalized = <String, dynamic>{};
    for (final column in columns) {
      final value = row[column];
      normalized[column] = value;
    }
    return normalized;
  }

  Map<String, dynamic> _normalizeIncomingRow(
    Map<dynamic, dynamic> row,
    List<String> columns,
  ) {
    final normalized = <String, dynamic>{};
    for (final column in columns) {
      normalized[column] = row[column];
    }
    return normalized;
  }
}
