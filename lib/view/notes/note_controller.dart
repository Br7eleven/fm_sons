import 'package:flutter/material.dart';
import '../../data/local/dao/note_dao.dart';
import '../../data/local/models/note_model.dart';

class NoteController extends ChangeNotifier {
  final NoteDao _noteDao;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  NoteController({NoteDao? noteDao}) : _noteDao = noteDao ?? NoteDao() {
    initialize();
  }

  final List<Note> _notes = [];
  List<Note> _filteredNotes = [];

  /// Public read-only access
  List<Note> get notes => List.unmodifiable(_filteredNotes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && _filteredNotes.isEmpty;
  String get searchQuery => _searchQuery;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadNotes();
  }

  Future<void> loadNotes() async {
    _setLoading(true);
    _setError(null);

    final result = await _noteDao.getAll();

    if (result.isFailure || result.data == null) {
      _notes.clear();
      _filteredNotes.clear();
      _setError(result.error ?? 'Failed to load notes');
      _setLoading(false);
      return;
    }

    _notes
      ..clear()
      ..addAll(result.data!);

    _applyFilter();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadNotes();
  }

  /// Search notes by title or body
  void search(String query) {
    _searchQuery = query.trim();
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_notes);
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredNotes = _notes.where((note) {
        return note.title.toLowerCase().contains(lowerQuery) ||
            note.body.toLowerCase().contains(lowerQuery);
      }).toList();
    }
  }

  /// Add a new note
  Future<void> addNote(Note note) async {
    _setError(null);
    final result = await _noteDao.create(note);
    if (result.isFailure || result.data == null) {
      throw Exception(result.error ?? 'Failed to create note');
    }

    _notes.insert(0, result.data!);
    _applyFilter();
    notifyListeners();
  }

  /// Update an existing note
  Future<void> updateNote(Note updatedNote) async {
    if (updatedNote.id == null) {
      throw Exception('Note ID is required for update');
    }

    final index = _notes.indexWhere((n) => n.id == updatedNote.id);

    if (index == -1) {
      throw Exception('Note not found');
    }

    _setError(null);
    final result = await _noteDao.update(updatedNote);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to update note');
    }

    _notes[index] = updatedNote;
    _applyFilter();
    notifyListeners();
  }

  /// Delete a note
  Future<void> deleteNote(int id) async {
    _setError(null);
    final result = await _noteDao.delete(id);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to delete note');
    }

    _notes.removeWhere((n) => n.id == id);
    _applyFilter();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? message) {
    _errorMessage = message;
  }
}
