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

  Future<List<InvoiceModel>> getInvoicesByDateRange({
    required DateTime start,
    required DateTime end,
    String? status,
    String? documentType,
  }) async {
    final db = await AppDatabase.database;
    final whereParts = <String>["invoice_date BETWEEN ? AND ?"];
    final args = <dynamic>[
      start.toUtc().toIso8601String(),
      end.toUtc().toIso8601String(),
    ];
    if (status != null) {
      whereParts.add('status = ?');
      args.add(status);
    }
    if (documentType != null) {
      whereParts.add('document_type = ?');
      args.add(documentType);
    }
    final rows = await db.query(
      InvoiceTable.tableName,
      where: whereParts.join(' AND '),
      whereArgs: args,
      orderBy: 'invoice_date DESC',
    );
    return rows.map(InvoiceModel.fromMap).toList();
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

  /// Takes the first 2 words of the client name, lowercases, joins with _,
  /// strips special chars. Falls back to 'inv' for single-word or empty names.
  /// Used for PDF filenames — not for invoice numbers themselves.
  static String makePrefix(String name) {
    final cleaned = name.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      '',
    );
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final prefix = words.take(2).join('_');
    if (prefix.isNotEmpty) return prefix;
    return 'inv';
  }

  /// Generate the next sequential number for a given prefix (e.g. INV, EST, PIN).
  /// Global sequence — not per-client. Always queries the DB fresh.
  Future<String> nextSequentialNumber(String prefix) async {
    final db = await AppDatabase.database;
    final pattern = '$prefix-%';
    final rows = await db.rawQuery(
      "SELECT invoice_number FROM ${InvoiceTable.tableName} WHERE invoice_number LIKE ? ORDER BY invoice_number DESC LIMIT 1",
      [pattern],
    );

    if (rows.isEmpty) {
      return '$prefix-0001';
    }

    final latest = (rows.first['invoice_number'] as String?) ?? '$prefix-0000';
    final parsed = _extractInvoiceNumberPart(latest);
    final next = parsed + 1;
    return '$prefix-${next.toString().padLeft(4, '0')}';
  }

  /// Convenience wrappers
  Future<String> nextInvoiceNumber() => nextSequentialNumber('INV');
  Future<String> nextEstimateNumber() => nextSequentialNumber('EST');
  Future<String> nextPaymentInNumber() => nextSequentialNumber('PIN');

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

  Future<Map<String, dynamic>> getClientBalance(String customerId) async {
    final db = await AppDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS invoice_count,
        COALESCE(SUM(total), 0) AS total_invoiced,
        COALESCE(SUM(received_amount), 0) AS total_received
      FROM ${InvoiceTable.tableName}
      WHERE customer_id = ? AND document_type = 'invoice'
      ''',
      [customerId],
    );

    final row = rows.first;
    return {
      'invoiceCount': (row['invoice_count'] as num?)?.toInt() ?? 0,
      'totalInvoiced': (row['total_invoiced'] as num?)?.toDouble() ?? 0,
      'totalReceived': (row['total_received'] as num?)?.toDouble() ?? 0,
    };
  }

  int _extractInvoiceNumberPart(String invoiceNumber) {
    final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }
}
