import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'tables/invoice_table.dart';
import 'tables/product_table.dart';
import 'tables/contract_table.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'fm_sons.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // ignore: avoid_print
        print('✅ Creating database tables...');
        await db.execute(InvoiceTable.createTable);
        await db.execute(ProductTable.createTable);
        await db.execute(ContractTable.createTable);
      },
    );
  }
}
