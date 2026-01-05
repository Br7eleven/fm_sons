import '../unit/unit_model.dart';

/// Represents a billable Product or Service
class Product {
  final String id;
  final String name;
  final ProductType type;
  final Unit unit;
  final double defaultRate;
  final String? description;

  const Product({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.defaultRate,
    this.description,
  });

  Product copyWith({
    String? id,
    String? name,
    ProductType? type,
    Unit? unit,
    double? defaultRate,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      defaultRate: defaultRate ?? this.defaultRate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'unitId': unit.id,
      'defaultRate': defaultRate,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, Unit unit) {
    return Product(
      id: map['id'],
      name: map['name'],
      type: ProductType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      unit: unit,
      defaultRate: map['defaultRate'],
      description: map['description'],
    );
  }
}

enum ProductType { material, service }
