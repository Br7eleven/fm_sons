class InvoiceItemModel {
  final int? id;
  final int invoiceId;
  final String? productId;
  final String productName;
  final String? unitId;
  final String unitLabel;
  final double quantity;
  final double rate;
  final double amount;
  final int sortOrder;

  const InvoiceItemModel({
    this.id,
    required this.invoiceId,
    this.productId,
    required this.productName,
    this.unitId,
    required this.unitLabel,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.sortOrder = 0,
  });

  InvoiceItemModel copyWith({
    int? id,
    int? invoiceId,
    String? productId,
    String? productName,
    String? unitId,
    String? unitLabel,
    double? quantity,
    double? rate,
    double? amount,
    int? sortOrder,
  }) {
    return InvoiceItemModel(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitId: unitId ?? this.unitId,
      unitLabel: unitLabel ?? this.unitLabel,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'unit_id': unitId,
      'unit_label': unitLabel,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'sort_order': sortOrder,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      id: map['id'] as int?,
      invoiceId: map['invoice_id'] as int,
      productId: map['product_id'] as String?,
      productName: map['product_name'] as String,
      unitId: map['unit_id'] as String?,
      unitLabel: map['unit_label'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}
