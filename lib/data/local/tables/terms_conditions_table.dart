class TermsConditionTable {
  static const tableName = 'terms_conditions';

  static const createTable = '''
  CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    applicable_for TEXT NOT NULL,
    created_at TEXT NOT NULL
  );
  ''';
}
