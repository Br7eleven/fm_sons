import 'package:flutter/material.dart';
import 'unit_model.dart';

class UnitController extends ChangeNotifier {
  /// Internal list of units

  final List<Unit> _units = [];

  /// Public read-only access
  List<Unit> get units => List.unmodifiable(_units);

  /// Add a new unit
  void addUnit(Unit unit) {
    // Rule 1: Unit name must be unique (case-insensitive)
    final exists = _units.any(
      (u) => u.name.toLowerCase() == unit.name.toLowerCase(),
    );

    if (exists) {
      throw Exception('Unit with this name already exists');
    }

    _units.add(unit);
    notifyListeners();
  }

  /// Update an existing unit
  void updateUnit(Unit updatedUnit) {
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

    _units[index] = updatedUnit;
    notifyListeners();
  }

  /// Delete a unit
  void removeUnit(String id) {
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

  /// Temporary seed data (optional, helps during development)
  void seedDefaultUnits() {
    if (_units.isNotEmpty) return;

    _units.addAll([
      const Unit(id: 'bag', name: 'Bag', symbol: 'bag', allowDecimal: false),
      const Unit(id: 'kg', name: 'Kilogram', symbol: 'kg', allowDecimal: true),
      const Unit(
        id: 'rft',
        name: 'Running Feet',
        symbol: 'rft',
        allowDecimal: true,
      ),
      const Unit(id: 'day', name: 'Day', symbol: 'day', allowDecimal: false),
    ]);

    notifyListeners();
  }
}
