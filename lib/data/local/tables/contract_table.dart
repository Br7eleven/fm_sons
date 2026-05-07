class ContractTable {
  static const tableName = 'contracts';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    contract_number TEXT NOT NULL UNIQUE,
    department_name TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT,
    total_value REAL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  ''';
}
