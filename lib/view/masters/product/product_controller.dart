import 'package:flutter/material.dart';

import '../unit/unit_controller.dart';
import 'product_model.dart';

class ProductController extends ChangeNotifier {
  final UnitController unitController;

  ProductController({required this.unitController});

  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  void addProduct(Product product) {
    // Name must be unique
    final exists = _products.any(
      (p) => p.name.toLowerCase() == product.name.toLowerCase(),
    );
    if (exists) {
      throw Exception('Product already exists');
    }

    // Unit must exist
    final validUnit = unitController.units.any((u) => u.id == product.unit.id);
    if (!validUnit) {
      throw Exception('Invalid unit selected');
    }

    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw Exception('Product not found');
    }

    _products[index] = product;
    notifyListeners();
  }

  void removeProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Product? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
