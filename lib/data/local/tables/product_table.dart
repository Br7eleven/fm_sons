class ProductTable {
  static const tableName = 'products';

  static const createTable =
      '''
  CREATE TABLE $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    unit TEXT NOT NULL,
    default_rate REAL,
    description TEXT
  );
  ''';
}
