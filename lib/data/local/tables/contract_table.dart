class ContractTable {
  static const tableName = 'contracts';

  static const createTable =
      '''
  CREATE TABLE $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    contract_number TEXT NOT NULL UNIQUE,
    department_name TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT,
    total_value REAL,
    status TEXT -- active, completed
  );
  ''';
}
