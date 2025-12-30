class InvoiceTable {
  static const tableName = 'invoices';

  static const createTable =
      '''
  CREATE TABLE $tableName (
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
    status TEXT NOT NULL, -- paid, pending, cancelled
    created_at TEXT NOT NULL
  );
  ''';
}
