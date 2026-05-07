class UnitTable {
  static const tableName = 'units';

  static const createTable =
      '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL COLLATE NOCASE UNIQUE,
    symbol TEXT NOT NULL,
    allow_decimal INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  ''';
}
