import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/invoice_model.dart';
import '../tables/invoice_table.dart';

class InvoiceDao {
  /// Insert invoice
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await AppDatabase.database;

    final exists = await invoiceNumberExists(invoice.invoiceNumber);
    if (exists) {
      throw Exception('Invoice number already exists');
    }

    return await db.insert(
      InvoiceTable.tableName,
      invoice.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort, // UNIQUE invoice_number
    );
  }

  /// Get all invoices (latest first)
  Future<List<InvoiceModel>> getAllInvoices() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      InvoiceTable.tableName,
      orderBy: 'created_at DESC',
    );

    return result.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  /// Get invoice by ID
  Future<InvoiceModel?> getInvoiceById(int id) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      InvoiceTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return InvoiceModel.fromMap(result.first);
    }
    return null;
  }

  /// Update existing invoice details
  Future<int> updateInvoice(int id, InvoiceModel invoice) async {
    final db = await AppDatabase.database;
    final payload = Map<String, dynamic>.from(invoice.toMap())..remove('id');

    return db.update(
      InvoiceTable.tableName,
      payload,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update invoice status (offline → backed_up / paid)
  Future<int> updateStatus(int id, String status) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();

    return await db.update(
      InvoiceTable.tableName,
      {'status': status, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<InvoiceModel>> getInvoicesByStatus(String status) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      InvoiceTable.tableName,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );

    return rows.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<List<InvoiceModel>> getInvoicesByCustomerId(String customerId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      InvoiceTable.tableName,
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return rows.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  Future<int> markPendingAsBackedUp() async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toUtc().toIso8601String();

    return db.update(
      InvoiceTable.tableName,
      {'status': 'backed_up', 'updated_at': now},
      where: 'status = ?',
      whereArgs: ['pending'],
    );
  }

  Future<bool> invoiceNumberExists(
    String invoiceNumber, {
    int? excludeId,
  }) async {
    final db = await AppDatabase.database;

    final whereParts = <String>['invoice_number = ?'];
    final args = <Object?>[invoiceNumber];
    if (excludeId != null) {
      whereParts.add('id != ?');
      args.add(excludeId);
    }

    final rows = await db.query(
      InvoiceTable.tableName,
      columns: ['id'],
      where: whereParts.join(' AND '),
      whereArgs: args,
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<String> nextInvoiceNumber() async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      InvoiceTable.tableName,
      columns: ['invoice_number'],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return 'INV-0001';
    }

    final latest = (rows.first['invoice_number'] as String?) ?? 'INV-0000';
    final parsed = _extractInvoiceNumberPart(latest);
    final next = parsed + 1;
    return 'INV-${next.toString().padLeft(4, '0')}';
  }

  Future<Map<String, num>> getInvoiceStatusSummary() async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total_count,
        SUM(CASE WHEN status = 'pending' THEN total ELSE 0 END) AS pending_amount,
        SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END) AS paid_amount
      FROM ${InvoiceTable.tableName}
      ''');

    final row = rows.first;
    return {
      'total_count': (row['total_count'] as num?) ?? 0,
      'pending_amount': (row['pending_amount'] as num?) ?? 0,
      'paid_amount': (row['paid_amount'] as num?) ?? 0,
    };
  }

  /// Delete invoice
  Future<int> deleteInvoice(int id) async {
    final db = await AppDatabase.database;
    return await db.delete(
      InvoiceTable.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  int _extractInvoiceNumberPart(String invoiceNumber) {
    final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }
}
