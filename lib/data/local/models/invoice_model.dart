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
  final String paymentStatus;
  final String template;
  final String documentType;
  final String? attachedImage;
  final String? attachedDoc;
  final int? termsId;
  final String? customNotes;
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
    this.paymentStatus = 'unpaid',
    this.template = 'taxTheme1',
    this.documentType = 'invoice',
    this.attachedImage,
    this.attachedDoc,
    this.termsId,
    this.customNotes,
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
      'payment_status': paymentStatus,
      'template': template,
      'document_type': documentType,
      'attached_image': attachedImage,
      'attached_doc': attachedDoc,
      'terms_id': termsId,
      'custom_notes': customNotes,
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
      paymentStatus: map['payment_status'] as String? ?? 'unpaid',
      template: map['template'] as String? ?? 'taxTheme1',
      documentType: map['document_type'] as String? ?? 'invoice',
      attachedImage: map['attached_image'] as String?,
      attachedDoc: map['attached_doc'] as String?,
      termsId: map['terms_id'] as int?,
      customNotes: map['custom_notes'] as String?,
      createdAt: map['created_at'],
      updatedAt: map['updated_at'] ?? map['created_at'],
    );
  }
}
