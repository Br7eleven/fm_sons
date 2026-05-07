class ProductTable {
  static const tableName = 'products';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    type TEXT NOT NULL,
    unit_id TEXT NOT NULL,
    default_rate REAL NOT NULL DEFAULT 0,
    description TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (unit_id) REFERENCES units(id)
      ON DELETE RESTRICT
  );
  ''';
}
