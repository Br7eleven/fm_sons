class Customer {
  /// Unique identifier (DB & backup safe)
  final String id;

  /// Display name
  /// e.g. "John Traders", "Ali & Sons"
  final String name;

  /// Optional contact details (future use)
  final String? phone;
  final String? address;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.address,
  });

  /// Create a temporary customer from invoice screen
  /// Used when user only types a name (no full profile)
  factory Customer.temp(String name) {
    return Customer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    );
  }

  /// Copy helper (edit / update later)
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  /// Convert to Map (SQLite / JSON)
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'address': address};
  }

  /// Restore from Map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
    );
  }
}
