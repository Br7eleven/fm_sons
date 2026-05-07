import '../app_database.dart';
import '../models/invoice_item_model.dart';
import '../tables/invoice_item_table.dart';

class InvoiceItemDao {
  Future<int> insertItem(InvoiceItemModel item) async {
    final db = await AppDatabase.database;
    return db.insert(InvoiceItemTable.tableName, item.toMap());
  }

  Future<List<InvoiceItemModel>> getItemsByInvoiceId(int invoiceId) async {
    final db = await AppDatabase.database;
    final rows = await db.query(
      InvoiceItemTable.tableName,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'sort_order ASC, id ASC',
    );

    return rows.map(InvoiceItemModel.fromMap).toList();
  }

  Future<int> deleteItemsByInvoiceId(int invoiceId) async {
    final db = await AppDatabase.database;
    return db.delete(
      InvoiceItemTable.tableName,
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
  }
}
