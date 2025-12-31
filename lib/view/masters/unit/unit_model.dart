class Unit {
  /// Unique identifier (later useful for DB)
  final String id;

  /// Display name
  /// Examples: Bag, Kg, RFT, Cum, Day
  final String name;

  /// Short symbol
  /// Examples: bag, kg, rft, m³, day
  final String symbol;

  /// Whether decimal quantities are allowed
  /// true  -> Kg, RFT, SqFt, Cum
  /// false -> Bag, Piece, Day, Shift
  final bool allowDecimal;

  /// Optional description (govt notes / clarification)
  final String? description;

  const Unit({
    required this.id,
    required this.name,
    required this.symbol,
    required this.allowDecimal,
    this.description,
  });

  /// Copy helper (useful for edit later)
  Unit copyWith({
    String? id,
    String? name,
    String? symbol,
    bool? allowDecimal,
    String? description,
  }) {
    return Unit(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      allowDecimal: allowDecimal ?? this.allowDecimal,
      description: description ?? this.description,
    );
  }

  /// Convert to Map (for future SQLite / JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'allowDecimal': allowDecimal,
      'description': description,
    };
  }

  /// Create Unit from Map
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      name: map['name'],
      symbol: map['symbol'],
      allowDecimal: map['allowDecimal'],
      description: map['description'],
    );
  }
}
