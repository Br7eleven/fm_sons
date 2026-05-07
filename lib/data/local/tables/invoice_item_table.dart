class InvoiceItemTable {
  static const tableName = 'invoice_items';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    product_id TEXT,
    product_name TEXT NOT NULL,
    unit_id TEXT,
    unit_label TEXT NOT NULL,
    quantity REAL NOT NULL,
    rate REAL NOT NULL,
    amount REAL NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
      ON DELETE SET NULL,
    FOREIGN KEY (unit_id) REFERENCES units(id)
      ON DELETE SET NULL
  );
  ''';
}
