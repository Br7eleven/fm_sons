class CustomerTable {
  static const tableName = 'customers';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    phone TEXT,
    address TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  ''';
}
