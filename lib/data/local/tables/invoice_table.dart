class InvoiceTable {
  static const tableName = 'invoices';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_number TEXT NOT NULL UNIQUE,
    customer_id TEXT,
    client_name TEXT NOT NULL,
    client_address TEXT,
    contract_id INTEGER,
    invoice_date TEXT NOT NULL,
    due_date TEXT,
    subtotal REAL NOT NULL,
    tax REAL NOT NULL DEFAULT 0,
    total REAL NOT NULL,
    status TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
      ON DELETE SET NULL,
    FOREIGN KEY (contract_id) REFERENCES contracts(id)
      ON DELETE SET NULL
  );
  ''';
}
