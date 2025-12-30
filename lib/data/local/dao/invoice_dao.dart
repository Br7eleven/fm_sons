import 'package:sqflite/sqflite.dart';
import '../app_database.dart';
import '../models/invoice_model.dart';
import '../tables/invoice_table.dart';

class InvoiceDao {
  /// Insert invoice
  Future<int> insertInvoice(InvoiceModel invoice) async {
    final db = await AppDatabase.database;
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

  /// Update invoice status (offline → backed_up / paid)
  Future<int> updateStatus(int id, String status) async {
    final db = await AppDatabase.database;

    return await db.update(
      InvoiceTable.tableName,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
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
}
