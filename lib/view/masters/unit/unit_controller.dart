import 'package:flutter/material.dart';

import '../../../data/local/dao/unit_dao.dart';
import 'unit_model.dart';

class UnitController extends ChangeNotifier {
  final UnitDao _unitDao;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  UnitController({UnitDao? unitDao}) : _unitDao = unitDao ?? UnitDao() {
    initialize();
  }

  final List<Unit> _units = [];

  /// Public read-only access
  List<Unit> get units => List.unmodifiable(_units);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && _units.isEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadUnits();
    if (_units.isEmpty) {
      await seedDefaultUnits();
      await loadUnits();
    }
  }

  Future<void> loadUnits() async {
    _setLoading(true);
    _setError(null);

    final result = await _unitDao.getAll();

    if (result.isFailure || result.data == null) {
      _units.clear();
      _setError(result.error ?? 'Failed to load units');
      _setLoading(false);
      return;
    }

    _units
      ..clear()
      ..addAll(result.data!);

    _setLoading(false);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadUnits();
  }

  /// Add a new unit
  Future<void> addUnit(Unit unit) async {
    // Rule 1: Unit name must be unique (case-insensitive)
    final exists = _units.any(
      (u) => u.name.toLowerCase() == unit.name.toLowerCase(),
    );

    if (exists) {
      throw Exception('Unit with this name already exists');
    }

    _setError(null);
    final result = await _unitDao.create(unit);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to create unit');
    }

    _units.add(unit);
    _sortUnits();
    notifyListeners();
  }

  /// Update an existing unit
  Future<void> updateUnit(Unit updatedUnit) async {
    final index = _units.indexWhere((u) => u.id == updatedUnit.id);

    if (index == -1) {
      throw Exception('Unit not found');
    }

    // Rule 2: Updated name must still be unique
    final duplicate = _units.any(
      (u) =>
          u.id != updatedUnit.id &&
          u.name.toLowerCase() == updatedUnit.name.toLowerCase(),
    );

    if (duplicate) {
      throw Exception('Another unit with this name already exists');
    }

    _setError(null);
    final result = await _unitDao.update(updatedUnit);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to update unit');
    }

    _units[index] = updatedUnit;
    _sortUnits();
    notifyListeners();
  }

  /// Soft-delete from active list
  Future<void> removeUnit(String id) async {
    _setError(null);

    final result = await _unitDao.deactivate(id);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to remove unit');
    }

    _units.removeWhere((u) => u.id == id);
    notifyListeners();
  }

  /// Find unit by ID
  Unit? getUnitById(String id) {
    try {
      return _units.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Seed default units only when database is empty.
  Future<void> seedDefaultUnits() async {
    final existing = await _unitDao.countUnits();
    if (existing.data != null && existing.data! > 0) {
      return;
    }

    const defaults = [
      Unit(id: 'bag', name: 'Bag', symbol: 'bag', allowDecimal: false),
      Unit(id: 'kg', name: 'Kilogram', symbol: 'kg', allowDecimal: true),
      Unit(id: 'rft', name: 'Running Feet', symbol: 'rft', allowDecimal: true),
      Unit(id: 'day', name: 'Day', symbol: 'day', allowDecimal: false),
    ];

    for (final unit in defaults) {
      final result = await _unitDao.create(unit);
      if (result.isFailure) {
        // Ignore duplicates from partially seeded databases.
        continue;
      }
    }

    await loadUnits();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _sortUnits() {
    _units.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
