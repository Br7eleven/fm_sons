class InvoiceItemTable {
  static const tableName = 'invoice_items';

  static const createTable =
      '''
  CREATE TABLE $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    quantity REAL NOT NULL,
    unit TEXT NOT NULL, -- kg, ton, meter, sqft, bag
    rate REAL NOT NULL,
    amount REAL NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      ON DELETE CASCADE
  );
  ''';
}
