import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fm_sons/data/local/dao/customer_dao.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/dao/invoice_item_dao.dart';
import 'package:fm_sons/data/local/dao/terms_condition_dao.dart';
import 'package:fm_sons/data/local/models/invoice_item_model.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/data/local/models/terms_condition_model.dart';
import 'package:fm_sons/utils/money_utils.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';

class InvoiceItem {
  final String? productId;
  final String name;
  final String? unitId;
  final String unit;
  final double quantity;
  final double rate;

  InvoiceItem({
    this.productId,
    required this.name,
    this.unitId,
    required this.unit,
    required this.quantity,
    required this.rate,
  });

  double get total => quantity * rate;
}

class InvoiceController extends ChangeNotifier {
  final InvoiceDao _invoiceDao;
  final InvoiceItemDao _invoiceItemDao;
  final CustomerDao _customerDao;

  InvoiceController({
    InvoiceDao? invoiceDao,
    InvoiceItemDao? invoiceItemDao,
    CustomerDao? customerDao,
    bool autoInitialize = true,
  }) : _invoiceDao = invoiceDao ?? InvoiceDao(),
       _invoiceItemDao = invoiceItemDao ?? InvoiceItemDao(),
       _customerDao = customerDao ?? CustomerDao() {
    if (autoInitialize) initialize();
  }

  bool _initialized = false;
  String amountInWords = "";
  String _notes = '';
  String? _attachedImagePath;
  String? _attachedDocPath;
  double _receivedAmount = 0;
  double _manualTotal = 0;
  String _templateId = 'taxTheme1';
  String _documentType = 'invoice'; // 'invoice' or 'estimate'
  String _paymentStatus = 'unpaid'; // 'paid' or 'unpaid'
  final TermsConditionDao _termsConditionDao = TermsConditionDao();
  int? _selectedTermsId;
  String _customNotes = '';
  List<TermsCondition> _availableTerms = [];
  TermsCondition? _selectedTermsCondition;
  final List<InvoiceItem> _items = [];
  final List<InvoiceModel> _savedInvoices = [];
  bool _isLoading = false;
  bool _isViewMode = false;
  String? _errorMessage;
  int? _activeInvoiceId;
  int? _editingInvoiceId;

  String _invoiceNumber = 'INV-0001';
  DateTime _invoiceDate = DateTime.now();

  String get invoiceNumber => _invoiceNumber;
  DateTime get invoiceDate => _invoiceDate;
  int? get activeInvoiceId => _activeInvoiceId;
  int? get editingInvoiceId => _editingInvoiceId;
  bool get isEditingInvoice => _editingInvoiceId != null;
  bool get isViewMode => _isViewMode;
  void setViewMode(bool v) {
    _isViewMode = v;
    notifyListeners();
  }
  String get notes => _notes;
  String? get attachedImagePath => _attachedImagePath;
  String? get attachedDocPath => _attachedDocPath;
  String get templateId => _templateId;
  String get documentType => _documentType;
  bool get isEstimate => _documentType == 'estimate';
  TermsCondition? get selectedTermsCondition => _selectedTermsCondition;
  int? get selectedTermsId => _selectedTermsId;
  List<TermsCondition> get availableTerms => _availableTerms;
  String get customNotes => _customNotes;

  Future<void> loadAvailableTerms() async {
    final type = _documentType;
    _availableTerms = await _termsConditionDao.getByType(type);
    if (_selectedTermsId != null) {
      _selectedTermsCondition = await _termsConditionDao.getById(_selectedTermsId!);
    }
    notifyListeners();
  }

  void setSelectedTerms(TermsCondition? tc) {
    _selectedTermsId = tc?.id;
    _selectedTermsCondition = tc;
    _saveDraft();
    notifyListeners();
  }

  void setCustomNotes(String value) {
    _customNotes = value;
    _saveDraft();
    notifyListeners();
  }

  void setTemplateId(String id) {
    _templateId = id;
    _saveDraft();
    notifyListeners();
  }

  String get paymentStatus => _paymentStatus;

  void setPaymentStatus(String status) {
    _paymentStatus = status;
    if (status == 'paid') {
      _receivedAmount = totalAmount;
    } else {
      _receivedAmount = 0;
    }
    _saveDraft();
    notifyListeners();
  }

  void setDocumentType(String type) {
    _documentType = type;
    // Clear selected T&C if not applicable to new type, then reload list
    if (_selectedTermsCondition != null &&
        !_selectedTermsCondition!.applicableFor.contains(type)) {
      _selectedTermsId = null;
      _selectedTermsCondition = null;
    }
    notifyListeners();
    _saveDraft();
    loadAvailableTerms();
  }

  void updateInvoiceDate(DateTime date) {
    clearError();
    _invoiceDate = date;
    _saveDraft();
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
    _saveDraft();
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      _attachedImagePath = file.path;
      _saveDraft();
      notifyListeners();
    }
  }

  void clearAttachedImage() {
    _attachedImagePath = null;
    _saveDraft();
    notifyListeners();
  }

  void setAttachedDoc(String path) {
    _attachedDocPath = path;
    _saveDraft();
    notifyListeners();
  }

  void clearAttachedDoc() {
    _attachedDocPath = null;
    _saveDraft();
    notifyListeners();
  }

  // Invoice Items
  List<InvoiceItem> get items => _items;
  List<InvoiceModel> get savedInvoices => List.unmodifiable(_savedInvoices);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSavedInvoices => _savedInvoices.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadNextNumberForDocumentType();
    await loadSavedInvoices();
    await _restoreDraft();
    await loadAvailableTerms();
  }

  /// Generate the next sequential number based on current document type.
  /// INV-xxxx for invoice, EST-xxxx for estimate, PIN-xxxx for payment-in.
  /// Always queries the DB fresh — no caching or client-name prefixing.
  Future<void> _loadNextNumberForDocumentType() async {
    try {
      _invoiceNumber = switch (_documentType) {
        'estimate' => await _invoiceDao.nextEstimateNumber(),
        'payment_in' => await _invoiceDao.nextPaymentInNumber(),
        _ => await _invoiceDao.nextInvoiceNumber(),
      };
      notifyListeners();
    } catch (_) {
      _invoiceNumber = 'INV-0001';
      notifyListeners();
    }
  }

  Future<void> loadSavedInvoices() async {
    setLoading(true);
    clearError();

    try {
      final invoices = await _invoiceDao.getAllInvoices();
      _savedInvoices
        ..clear()
        ..addAll(invoices);
    } catch (e) {
      setError('Failed to load invoices: $e');
    } finally {
      setLoading(false);
    }
  }

  Future<List<InvoiceModel>> getInvoicesByStatus(String status) async {
    return _invoiceDao.getInvoicesByStatus(status);
  }

  Future<void> updateInvoiceStatus(int id, String status) async {
    final affected = await _invoiceDao.updateStatus(id, status);
    if (affected == 0) {
      throw Exception('Invoice not found for status update');
    }
    await loadSavedInvoices();
  }

  Future<void> deleteInvoice(int id) async {
    final affected = await _invoiceDao.deleteInvoice(id);
    if (affected == 0) {
      throw Exception('Invoice not found for deletion');
    }
    await loadSavedInvoices();
  }

  void addItem(InvoiceItem item) {
    clearError();
    _items.add(item);
    updateAmountInWords();
    _saveDraft();
    notifyListeners();
  }

  void removeItem(int index) {
    clearError();
    _items.removeAt(index);
    updateAmountInWords();
    _saveDraft();
    notifyListeners();
  }

  void updateItem(int index, InvoiceItem item) {
    clearError();
    if (index < 0 || index >= _items.length) {
      throw Exception('Invalid invoice item index');
    }
    _items[index] = item;
    updateAmountInWords();
    _saveDraft();
    notifyListeners();
  }

  double get totalAmount {
    if (_items.isNotEmpty) {
      return _items.fold(0, (sum, item) => sum + item.total);
    }
    return _manualTotal;
  }

  void setManualTotal(double value) {
    _manualTotal = value < 0 ? 0 : value;
    _saveDraft();
    notifyListeners();
  }

  double get receivedAmount => _receivedAmount;
  double get balanceDue => normalizeMoney(totalAmount - _receivedAmount);

  void setReceivedAmount(double value) {
    _receivedAmount = value < 0 ? 0 : value;
    _saveDraft();
    notifyListeners();
  }

  Customer? _customer;

  Customer? get customer => _customer;

  /// Derived value (NO duplication)
  String? get customerName => _customer?.name;

  void setCustomer(Customer customer) {
    clearError();
    _customer = customer;
    _saveDraft();
    notifyListeners();
  }

  /// Optional: when user types a new name directly
  void setCustomerName(String name) {
    clearError();
    _customer = Customer.temp(name); // temporary unsaved customer
    _saveDraft();
    notifyListeners();
  }

  Future<void> loadInvoiceForEditing(int invoiceId) async {
    setLoading(true);
    clearError();

    try {
      final invoice = await _invoiceDao.getInvoiceById(invoiceId);
      if (invoice == null) {
        throw Exception('Invoice not found');
      }

      final items = await _invoiceItemDao.getItemsByInvoiceId(invoiceId);
      Customer? resolvedCustomer;

      if (invoice.customerId != null) {
        final customerResult = await _customerDao.getById(invoice.customerId!);
        if (customerResult.isSuccess) {
          resolvedCustomer = customerResult.data;
        }
      }

      resolvedCustomer ??= Customer(
        id:
            invoice.customerId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: invoice.clientName,
        address: invoice.clientAddress,
      );

      _editingInvoiceId = invoice.id;
      _activeInvoiceId = invoice.id;
      _invoiceNumber = invoice.invoiceNumber;
      _invoiceDate = DateTime.tryParse(invoice.invoiceDate)?.toLocal() ??
          DateTime.now();
      _customer = resolvedCustomer;
      _notes = '';
      _attachedImagePath = invoice.attachedImage;
      _attachedDocPath = invoice.attachedDoc;
      _templateId = invoice.template;
      _documentType = invoice.documentType;
      _paymentStatus = invoice.paymentStatus;
      _receivedAmount = invoice.receivedAmount;
      _selectedTermsId = invoice.termsId;
      _customNotes = invoice.customNotes ?? '';
      _selectedTermsCondition = invoice.termsId != null
          ? await _termsConditionDao.getById(invoice.termsId!)
          : null;

      _items
        ..clear()
        ..addAll(
          items.map(
            (item) => InvoiceItem(
              productId: item.productId,
              name: item.productName,
              unitId: item.unitId,
              unit: item.unitLabel,
              quantity: item.quantity,
              rate: item.rate,
            ),
          ),
        );

      // Payment-In has no line items — use invoice.total directly
      if (_items.isEmpty) {
        _manualTotal = invoice.total;
      }

      updateAmountInWords();
      notifyListeners();
    } catch (e) {
      setError('Failed to load invoice for editing: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<int> saveCurrentInvoice({String status = 'pending'}) async {
    final name = customerName?.trim() ?? '';
    if (name.isEmpty) {
      throw Exception('Customer name is required');
    }

    final editingId = _editingInvoiceId;
    final duplicate = await _invoiceDao.invoiceNumberExists(
      _invoiceNumber,
      excludeId: editingId,
    );
    if (duplicate) {
      throw Exception('Invoice number $_invoiceNumber already exists');
    }

    setLoading(true);
    clearError();

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final existingInvoice = editingId != null
          ? await _invoiceDao.getInvoiceById(editingId)
          : null;

      if (editingId != null && existingInvoice == null) {
        throw Exception('Invoice not found for editing');
      }

      final customer = await _customerDao.addOrGetByName(name);
      if (customer.isFailure || customer.data == null) {
        throw Exception(customer.error ?? 'Failed to resolve customer');
      }

      final invoice = InvoiceModel(
        id: editingId,
        invoiceNumber: _invoiceNumber,
        customerId: customer.data!.id,
        clientName: customer.data!.name,
        clientAddress: customer.data!.address,
        contractId: null,
        invoiceDate: _invoiceDate.toUtc().toIso8601String(),
        dueDate: null,
        subtotal: totalAmount,
        tax: 0,
        total: totalAmount,
        receivedAmount: _receivedAmount,
        status: existingInvoice?.status ?? status,
        paymentStatus: _paymentStatus,
        template: _templateId,
        documentType: _documentType,
        attachedImage: _attachedImagePath,
        attachedDoc: _attachedDocPath,
        termsId: _selectedTermsId,
        customNotes: _customNotes.isNotEmpty ? _customNotes : null,
        createdAt: existingInvoice?.createdAt ?? now,
        updatedAt: now,
      );

      final invoiceId = editingId ?? await _invoiceDao.insertInvoice(invoice);
      if (editingId != null) {
        final updated = await _invoiceDao.updateInvoice(invoiceId, invoice);
        if (updated == 0) {
          throw Exception('Invoice not found for update');
        }
        await _invoiceItemDao.deleteItemsByInvoiceId(invoiceId);
      }

      _activeInvoiceId = invoiceId;

      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        final row = InvoiceItemModel(
          invoiceId: invoiceId,
          productId: item.productId,
          productName: item.name,
          unitId: item.unitId,
          unitLabel: item.unit,
          quantity: item.quantity,
          rate: item.rate,
          amount: item.total,
          sortOrder: i,
        );
        await _invoiceItemDao.insertItem(row);
      }

      await loadSavedInvoices();
      await _prepareNextInvoiceDraft();

      return invoiceId;
    } catch (e) {
      setError('Failed to save invoice: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> _prepareNextInvoiceDraft() async {
    _items.clear();
    _customer = null;
    _invoiceDate = DateTime.now();
    amountInWords = '';
    _notes = '';
    _attachedImagePath = null;
    _attachedDocPath = null;
    _templateId = 'taxTheme1';
    _documentType = 'invoice';
    _paymentStatus = 'unpaid';
    _receivedAmount = 0;
    _selectedTermsId = null;
    _selectedTermsCondition = null;
    _customNotes = '';
    _availableTerms = [];
    _activeInvoiceId = null;
    _editingInvoiceId = null;
    await _loadNextNumberForDocumentType();
    await _clearDraftStorage();
    notifyListeners();
  }

  Future<void> resetDraft() async {
    await _prepareNextInvoiceDraft();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  //amount in words
  void updateAmountInWords() {
    if (totalAmount == 0) {
      amountInWords = "Zero Rupees only";
    } else {
      // totalAmount ko integer mein convert kar ke conversion function ko bhej rahe hain
      amountInWords = "${_numberToEnglish(totalAmount.floor())} Rupees only";
    }
  }

  // Numbers ko Words mein badalne ki logic
  String _numberToEnglish(int n) {
    if (n < 0) return "Negative ${_numberToEnglish(-n)}";
    if (n <= 20) {
      return [
        "",
        "One",
        "Two",
        "Three",
        "Four",
        "Five",
        "Six",
        "Seven",
        "Eight",
        "Nine",
        "Ten",
        "Eleven",
        "Twelve",
        "Thirteen",
        "Fourteen",
        "Fifteen",
        "Sixteen",
        "Seventeen",
        "Eighteen",
        "Nineteen",
        "Twenty",
      ][n];
    }
    if (n < 100) {
      return [
            "",
            "",
            "Twenty",
            "Thirty",
            "Forty",
            "Fifty",
            "Sixty",
            "Seventy",
            "Eighty",
            "Ninety",
          ][n ~/ 10] +
          (n % 10 != 0 ? " ${_numberToEnglish(n % 10)}" : "");
    }
    if (n < 1000) {
      return "${_numberToEnglish(n ~/ 100)} Hundred${n % 100 != 0 ? " and ${_numberToEnglish(n % 100)}" : ""}";
    }
    if (n < 100000) {
      return "${_numberToEnglish(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_numberToEnglish(n % 1000)}" : ""}";
    }
    if (n < 10000000) {
      // Lakhs handle karne ke liye
      return "${_numberToEnglish(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_numberToEnglish(n % 100000)}" : ""}";
    }
    return n.toString();
  }

  static const String _draftKey = 'invoice_draft_v1';

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'invoiceDate': _invoiceDate.toUtc().toIso8601String(),
        'notes': _notes,
        'attachedImagePath': _attachedImagePath,
        'attachedDocPath': _attachedDocPath,
        'templateId': _templateId,
        'documentType': _documentType,
        'paymentStatus': _paymentStatus,
        'receivedAmount': _receivedAmount,
        'selectedTermsId': _selectedTermsId,
        'customNotes': _customNotes,
        'customer': _customer?.toMap(),
        'items': _items.map((it) => {
          'productId': it.productId,
          'name': it.name,
          'unitId': it.unitId,
          'unit': it.unit,
          'quantity': it.quantity,
          'rate': it.rate,
        }).toList(),
      };
      await prefs.setString(_draftKey, jsonEncode(data));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // invoiceNumber is intentionally NOT restored from draft —
      // it is always computed fresh by _loadNextInvoiceNumber() on init.
      final dateStr = map['invoiceDate'] as String?;
      if (dateStr != null) {
        _invoiceDate = DateTime.tryParse(dateStr)?.toLocal() ?? _invoiceDate;
      }
      _notes = map['notes'] ?? _notes;
      _attachedImagePath = map['attachedImagePath'] as String?;
      _attachedDocPath = map['attachedDocPath'] as String?;
      _templateId = map['templateId'] as String? ?? _templateId;
      _documentType = map['documentType'] as String? ?? _documentType;
      _paymentStatus = map['paymentStatus'] as String? ?? _paymentStatus;
      _receivedAmount = (map['receivedAmount'] as num?)?.toDouble() ?? _receivedAmount;
      _selectedTermsId = map['selectedTermsId'] as int?;
      _customNotes = map['customNotes'] as String? ?? '';
      final customerMap = map['customer'] as Map<String, dynamic>?;
      if (customerMap != null) {
        _customer = Customer.fromMap(Map<String, dynamic>.from(customerMap));
      }
      final itemsList = (map['items'] as List<dynamic>?) ?? [];
      _items
        ..clear()
        ..addAll(itemsList.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return InvoiceItem(
            productId: m['productId'] as String?,
            name: m['name'] as String? ?? '',
            unitId: m['unitId'] as String?,
            unit: m['unit'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toDouble() ?? 0.0,
            rate: (m['rate'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList());
      updateAmountInWords();
      notifyListeners();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _clearDraftStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {
      // ignore
    }
  }
}
