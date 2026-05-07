import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fm_sons/data/local/app_database.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('migrates v1 schema to latest and preserves legacy data', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'fm_sons_migration_test_',
    );
    final dbPath = path.join(tempDir.path, 'fm_sons_migration.db');

    try {
      final db = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE invoices (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                invoice_number TEXT NOT NULL UNIQUE,
                client_name TEXT NOT NULL,
                client_address TEXT,
                contract_id INTEGER,
                invoice_date TEXT NOT NULL,
                due_date TEXT,
                subtotal REAL NOT NULL,
                tax REAL DEFAULT 0,
                total REAL NOT NULL,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL
              );
            ''');

            await db.execute('''
              CREATE TABLE products (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                unit TEXT NOT NULL,
                default_rate REAL,
                description TEXT
              );
            ''');

            await db.execute('''
              CREATE TABLE contracts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                contract_number TEXT NOT NULL UNIQUE,
                department_name TEXT NOT NULL,
                start_date TEXT,
                end_date TEXT,
                total_value REAL,
                status TEXT
              );
            ''');
          },
        ),
      );

      await db.insert('contracts', {
        'id': 1,
        'contract_number': 'C-001',
        'department_name': 'Works Dept',
        'status': 'active',
      });

      await db.insert('products', {
        'id': 1,
        'name': 'Portland Cement',
        'unit': 'Bag',
        'default_rate': 1200.0,
        'description': 'Legacy product row',
      });

      await db.insert('invoices', {
        'id': 1,
        'invoice_number': 'INV-0001',
        'client_name': 'Ali Traders',
        'client_address': 'Model Town',
        'contract_id': 1,
        'invoice_date': '2026-01-10T00:00:00.000Z',
        'due_date': '2026-01-20T00:00:00.000Z',
        'subtotal': 1000.0,
        'tax': 0.0,
        'total': 1000.0,
        'status': 'pending',
        'created_at': '2026-01-10T00:00:00.000Z',
      });

      await AppDatabase.migrateForTesting(db, 1, AppDatabase.schemaVersion);

      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = tableRows
          .map((e) => e['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();

      expect(tableNames.contains('customers'), isTrue);
      expect(tableNames.contains('units'), isTrue);
      expect(tableNames.contains('products'), isTrue);
      expect(tableNames.contains('contracts'), isTrue);
      expect(tableNames.contains('invoices'), isTrue);
      expect(tableNames.contains('invoice_items'), isTrue);

      final productColumns = await db.rawQuery('PRAGMA table_info(products)');
      final productColumnNames = productColumns
          .map((e) => e['name']?.toString() ?? '')
          .toSet();
      expect(productColumnNames.contains('unit_id'), isTrue);
      expect(productColumnNames.contains('type'), isTrue);
      expect(productColumnNames.contains('created_at'), isTrue);
      expect(productColumnNames.contains('updated_at'), isTrue);

      final invoiceColumns = await db.rawQuery('PRAGMA table_info(invoices)');
      final invoiceColumnNames = invoiceColumns
          .map((e) => e['name']?.toString() ?? '')
          .toSet();
      expect(invoiceColumnNames.contains('customer_id'), isTrue);
      expect(invoiceColumnNames.contains('updated_at'), isTrue);

      final migratedProduct = await db.query('products', limit: 1);
      expect(migratedProduct, isNotEmpty);
      expect(migratedProduct.first['id'], '1');
      expect(migratedProduct.first['name'], 'Portland Cement');
      expect(migratedProduct.first['unit_id'], 'bag');

      final migratedUnit = await db.query(
        'units',
        where: 'id = ?',
        whereArgs: ['bag'],
        limit: 1,
      );
      expect(migratedUnit, isNotEmpty);

      final migratedInvoice = await db.query('invoices', limit: 1);
      expect(migratedInvoice, isNotEmpty);
      expect(migratedInvoice.first['invoice_number'], 'INV-0001');
      expect(migratedInvoice.first['updated_at'], isNotNull);

      await db.close();
    } finally {
      if (await databaseFactory.databaseExists(dbPath)) {
        await databaseFactory.deleteDatabase(dbPath);
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
