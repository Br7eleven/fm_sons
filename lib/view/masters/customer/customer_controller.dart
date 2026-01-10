import 'package:flutter/material.dart';
import 'customer_model.dart';

class CustomerController extends ChangeNotifier {
  final List<Customer> _customers = [];

  /// Read-only list
  List<Customer> get customers => List.unmodifiable(_customers);

  /* -------------------------------------------------------------------------- */
  /*                                CRUD                                        */
  /* -------------------------------------------------------------------------- */

  /// Add customer if not exists (by name)
  /// Returns existing customer if already present
  Customer addOrGetCustomer(Customer customer) {
    final existing = findByName(customer.name);
    if (existing != null) return existing;

    _customers.add(customer);
    notifyListeners();
    return customer;
  }

  void updateCustomer(Customer customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index == -1) return;

    _customers[index] = customer;
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
    if (q.isEmpty) return [];

    return _customers.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  /* -------------------------------------------------------------------------- */
  /*                             SEED / DEBUG                                   */
  /* -------------------------------------------------------------------------- */

  /// Optional: preload sample customers (remove later)
  void seed(List<Customer> initial) {
    _customers
      ..clear()
      ..addAll(initial);
    notifyListeners();
  }
}
