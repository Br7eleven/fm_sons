import 'package:flutter/material.dart';

class InvoiceItem {
  final String name;
  final String unit;
  final int quantity;
  final double rate;

  InvoiceItem({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;
}

class InvoiceController extends ChangeNotifier {
  final List<InvoiceItem> _items = [];

  List<InvoiceItem> get items => _items;

  void addItem(InvoiceItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.total);
  }
}
