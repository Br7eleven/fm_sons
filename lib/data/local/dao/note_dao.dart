import '../app_database.dart';
import '../tables/note_table.dart';
import '../models/note_model.dart';
import 'dao_result.dart';

class NoteDao {
  Future<DaoResult<Note>> create(Note note) async {
    try {
      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final id = await db.insert(NoteTable.tableName, {
        'title': note.title,
        'body': note.body,
        'created_at': now,
        'updated_at': now,
      });

      return DaoResult.success(note.copyWith(id: id));
    } catch (e) {
      return DaoResult.failure('Failed to create note', exception: e);
    }
  }

  Future<DaoResult<Note>> update(Note note) async {
    try {
      if (note.id == null) {
        return DaoResult.failure('Note ID is required for update');
      }

      final db = await AppDatabase.database;
      final now = DateTime.now().toUtc().toIso8601String();

      final rows = await db.update(
        NoteTable.tableName,
        {'title': note.title, 'body': note.body, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [note.id],
      );

      if (rows == 0) {
        return DaoResult.failure('Note not found for update');
      }

      return DaoResult.success(note.copyWith(updatedAt: DateTime.parse(now)));
    } catch (e) {
      return DaoResult.failure('Failed to update note', exception: e);
    }
  }

  Future<DaoResult<int>> delete(int id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.delete(
        NoteTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      return DaoResult.success(rows);
    } catch (e) {
      return DaoResult.failure('Failed to delete note', exception: e);
    }
  }

  Future<DaoResult<Note?>> getById(int id) async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        NoteTable.tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        return DaoResult.success(null);
      }

      return DaoResult.success(Note.fromMap(rows.first));
    } catch (e) {
      return DaoResult.failure('Failed to load note by id', exception: e);
    }
  }

  Future<DaoResult<List<Note>>> getAll() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.query(
        NoteTable.tableName,
        orderBy: 'updated_at DESC',
      );

      return DaoResult.success(rows.map(Note.fromMap).toList());
    } catch (e) {
      return DaoResult.failure('Failed to load notes', exception: e);
    }
  }

  Future<DaoResult<List<Note>>> search(String query) async {
    try {
      final db = await AppDatabase.database;
      final q = query.trim();

      if (q.isEmpty) {
        return getAll();
      }

      final rows = await db.query(
        NoteTable.tableName,
        where: 'title LIKE ? OR body LIKE ?',
        whereArgs: ['%$q%', '%$q%'],
        orderBy: 'updated_at DESC',
      );

      return DaoResult.success(rows.map(Note.fromMap).toList());
    } catch (e) {
      return DaoResult.failure('Failed to search notes', exception: e);
    }
  }

  Future<DaoResult<int>> countNotes() async {
    try {
      final db = await AppDatabase.database;
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM ${NoteTable.tableName}',
      );
      final count = (rows.first['count'] as int?) ?? 0;
      return DaoResult.success(count);
    } catch (e) {
      return DaoResult.failure('Failed to count notes', exception: e);
    }
  }
}
