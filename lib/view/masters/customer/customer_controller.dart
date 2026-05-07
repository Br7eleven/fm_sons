import 'package:flutter/material.dart';

import '../../../data/local/dao/customer_dao.dart';
import 'customer_model.dart';

class CustomerController extends ChangeNotifier {
  final CustomerDao _customerDao;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  CustomerController({CustomerDao? customerDao})
    : _customerDao = customerDao ?? CustomerDao() {
    initialize();
  }

  final List<Customer> _customers = [];

  /// Read-only list
  List<Customer> get customers => List.unmodifiable(_customers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && _customers.isEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadCustomers();
  }

  Future<void> loadCustomers() async {
    _setLoading(true);
    _setError(null);

    final result = await _customerDao.getAll();
    if (result.isFailure || result.data == null) {
      _customers.clear();
      _setError(result.error ?? 'Failed to load customers');
      _setLoading(false);
      return;
    }

    _customers
      ..clear()
      ..addAll(result.data!);

    _setLoading(false);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadCustomers();
  }

  /* -------------------------------------------------------------------------- */
  /*                                CRUD                                        */
  /* -------------------------------------------------------------------------- */

  /// Add customer if not exists (by name)
  /// Returns existing customer if already present
  Future<Customer> addOrGetCustomer(Customer customer) async {
    final existing = findByName(customer.name);
    if (existing != null) return existing;

    _setError(null);

    final createResult = await _customerDao.create(customer);
    if (createResult.isSuccess && createResult.data != null) {
      _customers.add(createResult.data!);
      _sortCustomers();
      notifyListeners();
      return createResult.data!;
    }

    // If create failed due to uniqueness race, try a direct lookup.
    final lookupResult = await _customerDao.findByName(customer.name);
    if (lookupResult.isSuccess && lookupResult.data != null) {
      final found = lookupResult.data!;
      final index = _customers.indexWhere((c) => c.id == found.id);
      if (index == -1) {
        _customers.add(found);
      } else {
        _customers[index] = found;
      }
      _sortCustomers();
      notifyListeners();
      return found;
    }

    throw Exception(createResult.error ?? 'Failed to save customer');
  }

  Future<void> updateCustomer(Customer customer) async {
    final result = await _customerDao.update(customer);
    if (result.isFailure || result.data == null) {
      throw Exception(result.error ?? 'Failed to update customer');
    }

    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index == -1) {
      _customers.add(customer);
    } else {
      _customers[index] = customer;
    }

    _sortCustomers();
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    final result = await _customerDao.delete(id);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to delete customer');
    }

    _customers.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /* -------------------------------------------------------------------------- */
  /*                               QUERIES                                      */
  /* -------------------------------------------------------------------------- */

  Customer? findByName(String name) {
    final query = name.trim().toLowerCase();
    if (query.isEmpty) return null;

    try {
      return _customers.firstWhere((c) => c.name.toLowerCase() == query);
    } catch (_) {
      return null;
    }
  }

  /// Used for autocomplete dropdown
  List<Customer> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_customers);

    return _customers.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /* -------------------------------------------------------------------------- */
  /*                             SEED / DEBUG                                   */
  /* -------------------------------------------------------------------------- */

  Future<void> seed(List<Customer> initial) async {
    for (final customer in initial) {
      await _customerDao.create(customer);
    }
    await loadCustomers();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _sortCustomers() {
    _customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
