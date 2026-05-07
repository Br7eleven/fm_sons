class InvoiceModel {
  final int? id;
  final String invoiceNumber;
  final String? customerId;
  final String clientName;
  final String? clientAddress;
  final int? contractId;
  final String invoiceDate;
  final String? dueDate;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final String createdAt;
  final String updatedAt;

  InvoiceModel({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.clientName,
    this.clientAddress,
    this.contractId,
    required this.invoiceDate,
    this.dueDate,
    required this.subtotal,
    this.tax = 0,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'client_name': clientName,
      'client_address': clientAddress,
      'contract_id': contractId,
      'invoice_date': invoiceDate,
      'due_date': dueDate,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      customerId: map['customer_id'],
      clientName: map['client_name'],
      clientAddress: map['client_address'],
      contractId: map['contract_id'],
      invoiceDate: map['invoice_date'],
      dueDate: map['due_date'],
      subtotal: map['subtotal'],
      tax: map['tax'],
      total: map['total'],
      status: map['status'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'] ?? map['created_at'],
    );
  }
}
