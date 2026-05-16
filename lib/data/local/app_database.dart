import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables/customer_table.dart';
import 'tables/invoice_item_table.dart';
import 'tables/invoice_table.dart';
import 'tables/product_table.dart';
import 'tables/contract_table.dart';
import 'tables/unit_table.dart';
import 'tables/note_table.dart';

class AppDatabase {
  static const int schemaVersion = 5;
  static const String _dbName = 'fm_sons.db';

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<String> databaseFilePath() async {
    return join(await getDatabasesPath(), _dbName);
  }

  static Future<void> closeDatabase() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createLatestSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _runMigrations(db, oldVersion, newVersion);
      },
    );
  }

  static Future<void> _createLatestSchema(Database db) async {
    await db.execute(CustomerTable.createTable);
    await db.execute(UnitTable.createTable);
    await db.execute(ProductTable.createTable);
    await db.execute(ContractTable.createTable);
    await db.execute(InvoiceTable.createTable);
    await db.execute(InvoiceItemTable.createTable);
    await db.execute(NoteTable.createTable);
  }

  static Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateV1ToV2(db);
    }

    if (oldVersion < 3) {
      await _migrateV2ToV3(db);
    }

    if (oldVersion < 4) {
      await _migrateV3ToV4(db);
    }

    if (oldVersion < 5) {
      await _migrateV4ToV5(db);
    }
    if (newVersion > schemaVersion) {
      // ignore: avoid_print
      print(
        'Warning: database newer than app schema ($newVersion > $schemaVersion)',
      );
    }
  }

  @visibleForTesting
  static Future<void> migrateForTesting(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await _runMigrations(db, oldVersion, newVersion);
  }

  static Future<void> _migrateV2ToV3(Database db) async {
    await db.execute(NoteTable.createTable);
  }

  static Future<void> _migrateV4ToV5(Database db) async {
    final cols = await db.rawQuery(
      "PRAGMA table_info(${InvoiceTable.tableName})",
    );
    final hasDocType = cols.any((c) => c['name'] == 'document_type');
    if (!hasDocType) {
      await db.execute(
        "ALTER TABLE ${InvoiceTable.tableName} ADD COLUMN document_type TEXT NOT NULL DEFAULT 'invoice'",
      );
    }
  }

  static Future<void> _migrateV3ToV4(Database db) async {
    final cols = await db.rawQuery(
      "PRAGMA table_info(${InvoiceTable.tableName})",
    );
    final hasTemplate = cols.any((c) => c['name'] == 'template');
    if (!hasTemplate) {
      await db.execute(
        "ALTER TABLE ${InvoiceTable.tableName} ADD COLUMN template TEXT NOT NULL DEFAULT 'taxTheme1'",
      );
    }
  }

  static Future<void> _migrateV1ToV2(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();

    await db.transaction((txn) async {
      await _ensureTable(
        txn,
        CustomerTable.tableName,
        CustomerTable.createTable,
      );
      await _ensureTable(txn, UnitTable.tableName, UnitTable.createTable);

      await _migrateProducts(txn, now);
      await _migrateContracts(txn, now);
      await _migrateInvoices(txn, now);
      await _migrateInvoiceItems(txn, now);
    });
  }

  static Future<void> _migrateProducts(Transaction txn, String now) async {
    if (!await _tableExists(txn, ProductTable.tableName)) {
      await txn.execute(ProductTable.createTable);
      return;
    }

    final legacyRows = await txn.query(ProductTable.tableName);

    await txn.execute(
      'ALTER TABLE ${ProductTable.tableName} RENAME TO _products_v1_backup',
    );
    await txn.execute(ProductTable.createTable);

    await _ensureFallbackUnit(txn, now);

    for (final row in legacyRows) {
      final unitId = await _upsertLegacyUnit(
        txn,
        _toNullableString(row['unit']),
        now,
      );

      await txn.insert(ProductTable.tableName, {
        'id': _toRequiredString(
          row['id'],
          fallback: 'legacy-product-${DateTime.now().microsecondsSinceEpoch}',
        ),
        'name': _toRequiredString(row['name'], fallback: 'Unnamed Product'),
        'type': 'material',
        'unit_id': unitId,
        'default_rate': _toDouble(row['default_rate']),
        'description': _toNullableString(row['description']),
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await txn.execute('DROP TABLE _products_v1_backup');
  }

  static Future<void> _migrateContracts(Transaction txn, String now) async {
    if (!await _tableExists(txn, ContractTable.tableName)) {
      await txn.execute(ContractTable.createTable);
      return;
    }

    final legacyRows = await txn.query(ContractTable.tableName);

    await txn.execute(
      'ALTER TABLE ${ContractTable.tableName} RENAME TO _contracts_v1_backup',
    );
    await txn.execute(ContractTable.createTable);

    for (final row in legacyRows) {
      await txn.insert(ContractTable.tableName, {
        'id': row['id'],
        'contract_number': _toRequiredString(
          row['contract_number'],
          fallback: 'UNKNOWN-CONTRACT',
        ),
        'department_name': _toRequiredString(
          row['department_name'],
          fallback: 'Unknown Department',
        ),
        'start_date': _toNullableString(row['start_date']),
        'end_date': _toNullableString(row['end_date']),
        'total_value': _toNullableDouble(row['total_value']),
        'status': _toRequiredString(row['status'], fallback: 'active'),
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await txn.execute('DROP TABLE _contracts_v1_backup');
  }

  static Future<void> _migrateInvoices(Transaction txn, String now) async {
    if (!await _tableExists(txn, InvoiceTable.tableName)) {
      await txn.execute(InvoiceTable.createTable);
      return;
    }

    final legacyRows = await txn.query(InvoiceTable.tableName);

    await txn.execute(
      'ALTER TABLE ${InvoiceTable.tableName} RENAME TO _invoices_v1_backup',
    );
    await txn.execute(InvoiceTable.createTable);

    for (final row in legacyRows) {
      final normalizedContractId = await _validContractId(
        txn,
        row['contract_id'],
      );
      final createdAt = _toRequiredString(row['created_at'], fallback: now);

      await txn.insert(InvoiceTable.tableName, {
        'id': row['id'],
        'invoice_number': _toRequiredString(
          row['invoice_number'],
          fallback: 'INV-UNKNOWN',
        ),
        'customer_id': null,
        'client_name': _toRequiredString(
          row['client_name'],
          fallback: 'Walk-in Customer',
        ),
        'client_address': _toNullableString(row['client_address']),
        'contract_id': normalizedContractId,
        'invoice_date': _toRequiredString(row['invoice_date'], fallback: now),
        'due_date': _toNullableString(row['due_date']),
        'subtotal': _toDouble(row['subtotal']),
        'tax': _toDouble(row['tax']),
        'total': _toDouble(row['total']),
        'status': _toRequiredString(row['status'], fallback: 'pending'),
        'created_at': createdAt,
        'updated_at': createdAt,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await txn.execute('DROP TABLE _invoices_v1_backup');
  }

  static Future<void> _migrateInvoiceItems(Transaction txn, String now) async {
    if (!await _tableExists(txn, InvoiceItemTable.tableName)) {
      await txn.execute(InvoiceItemTable.createTable);
      return;
    }

    final legacyRows = await txn.query(InvoiceItemTable.tableName);

    await txn.execute(
      'ALTER TABLE ${InvoiceItemTable.tableName} RENAME TO _invoice_items_v1_backup',
    );
    await txn.execute(InvoiceItemTable.createTable);

    for (var index = 0; index < legacyRows.length; index++) {
      final row = legacyRows[index];
      final invoiceId = _toInt(row['invoice_id']);

      // Skip orphan item rows during migration; they cannot satisfy FK.
      if (!await _invoiceExists(txn, invoiceId)) {
        continue;
      }

      final unitValue = _toNullableString(row['unit']);
      final unitId = await _upsertLegacyUnit(txn, unitValue, now);

      await txn.insert(InvoiceItemTable.tableName, {
        'id': row['id'],
        'invoice_id': invoiceId,
        'product_id': null,
        'product_name': _toRequiredString(
          row['product_name'],
          fallback: 'Unnamed Item',
        ),
        'unit_id': unitId,
        'unit_label': _toRequiredString(unitValue, fallback: 'Unit'),
        'quantity': _toDouble(row['quantity']),
        'rate': _toDouble(row['rate']),
        'amount': _toDouble(row['amount']),
        'sort_order': index,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await txn.execute('DROP TABLE _invoice_items_v1_backup');
  }

  static Future<void> _ensureFallbackUnit(Transaction txn, String now) async {
    await txn.insert(UnitTable.tableName, {
      'id': 'unit-default',
      'name': 'Unit',
      'symbol': 'unit',
      'allow_decimal': 1,
      'description': 'Fallback unit for migrated legacy data',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<String> _upsertLegacyUnit(
    Transaction txn,
    String? rawUnit,
    String now,
  ) async {
    final normalizedRaw = rawUnit?.trim();
    if (normalizedRaw == null || normalizedRaw.isEmpty) {
      return 'unit-default';
    }

    final unitId = _normalizeId(normalizedRaw);

    await txn.insert(UnitTable.tableName, {
      'id': unitId,
      'name': normalizedRaw,
      'symbol': unitId,
      'allow_decimal': _defaultDecimalPolicy(normalizedRaw),
      'description': 'Auto-migrated from legacy product/item records',
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return unitId;
  }

  static Future<int?> _validContractId(
    Transaction txn,
    dynamic contractId,
  ) async {
    final normalized = _toNullableInt(contractId);
    if (normalized == null) return null;

    final rows = await txn.query(
      ContractTable.tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [normalized],
      limit: 1,
    );

    return rows.isEmpty ? null : normalized;
  }

  static Future<bool> _invoiceExists(Transaction txn, int invoiceId) async {
    final rows = await txn.query(
      InvoiceTable.tableName,
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [invoiceId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<void> _ensureTable(
    DatabaseExecutor db,
    String tableName,
    String createSql,
  ) async {
    if (!await _tableExists(db, tableName)) {
      await db.execute(createSql);
    }
  }

  static Future<bool> _tableExists(
    DatabaseExecutor db,
    String tableName,
  ) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static String _toRequiredString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String _normalizeId(String input) {
    final normalized = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return normalized.isEmpty ? 'unit-default' : normalized;
  }

  static int _defaultDecimalPolicy(String unitName) {
    final normalized = unitName.toLowerCase();
    const nonDecimalUnits = {'bag', 'piece', 'pcs', 'day', 'shift'};
    return nonDecimalUnits.contains(normalized) ? 0 : 1;
  }
}
