import 'package:flutter/material.dart';
import 'package:fm_sons/view/masters/unit/unit_model.dart';

import '../../../data/local/dao/product_dao.dart';
import '../unit/unit_controller.dart';
import 'product_model.dart';

class ProductController extends ChangeNotifier {
  final ProductDao _productDao;
  final UnitController unitController;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  ProductController({required this.unitController, ProductDao? productDao})
    : _productDao = productDao ?? ProductDao() {
    initialize();
  }

  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && _products.isEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _setLoading(true);
    _setError(null);

    final result = await _productDao.getAll();
    if (result.isFailure || result.data == null) {
      _products.clear();
      _setError(result.error ?? 'Failed to load products');
      _setLoading(false);
      return;
    }

    _products
      ..clear()
      ..addAll(result.data!);

    _setLoading(false);
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadProducts();
  }

  Future<void> addProduct(Product product) async {
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

    _setError(null);
    final result = await _productDao.create(product);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to add product');
    }

    _products.add(product);
    _sortProducts();
    notifyListeners();
  }

  /// Returns the existing product with a matching (case-insensitive, trimmed)
  /// name, or silently creates a new one and returns it. Returns `null` if the
  /// name is empty or creation fails — callers should NOT block on this.
  Future<Product?> ensureProductByName(String name, Unit unit, double rate) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return null;

    final key = normalized.toLowerCase();
    final existing = _products
        .where((p) => p.name.trim().toLowerCase() == key)
        .toList();
    if (existing.isNotEmpty) return existing.first;

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: normalized,
      type: ProductType.material,
      unit: unit,
      defaultRate: rate,
      description: null,
    );

    try {
      final result = await _productDao.create(product);
      if (result.isFailure) {
        debugPrint('ensureProductByName: failed to create product: ${result.error}');
        return null;
      }
      _products.add(product);
      _sortProducts();
      notifyListeners();
      return product;
    } catch (e) {
      debugPrint('ensureProductByName: exception creating product: $e');
      return null;
    }
  }

  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      throw Exception('Product not found');
    }

    _setError(null);
    final result = await _productDao.update(product);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to update product');
    }

    _products[index] = product;
    _sortProducts();
    notifyListeners();
  }

  Future<void> removeProduct(String id) async {
    _setError(null);
    final result = await _productDao.deactivate(id);
    if (result.isFailure) {
      throw Exception(result.error ?? 'Failed to remove product');
    }

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _sortProducts() {
    _products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }
}
