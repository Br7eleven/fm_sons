import 'package:flutter/material.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';

/// Controller for Payment-In form.
/// Structurally separate from InvoiceController — Payment-In is opposite
/// ledger direction (reduces Due, not creates it).
class PaymentInController extends ChangeNotifier {
  final InvoiceDao _invoiceDao;
  final String customerId;
  final String customerName;
  final int? editingInvoiceId;

  PaymentInController({
    InvoiceDao? invoiceDao,
    required this.customerId,
    required this.customerName,
    this.editingInvoiceId,
  }) : _invoiceDao = invoiceDao ?? InvoiceDao() {
    _initialize();
  }

  String _receiptNumber = '';
  DateTime _date = DateTime.now();
  double _amount = 0;
  bool _isSaving = false;
  String? _errorMessage;
  double _currentDue = 0;
  String _notes = '';
  String? _attachedImagePath;

  String get receiptNumber => _receiptNumber;
  DateTime get date => _date;
  double get amount => _amount;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  double get currentDue => _currentDue;
  String get notes => _notes;
  String? get attachedImagePath => _attachedImagePath;

  Future<void> _initialize() async {
    if (editingInvoiceId != null) {
      await _loadExisting(editingInvoiceId!);
    } else {
      await _loadNextReceiptNumber();
    }
    await _loadBalance();
  }

  Future<void> _loadExisting(int id) async {
    try {
      final existing = await _invoiceDao.getInvoiceById(id);
      if (existing != null) {
        _receiptNumber = existing.invoiceNumber;
        _date = DateTime.tryParse(existing.invoiceDate)?.toLocal() ?? DateTime.now();
        _amount = existing.total;
        _notes = existing.customNotes ?? '';
        _attachedImagePath = existing.attachedImage;
        notifyListeners();
      }
    } catch (_) {
      // fall through to fresh receipt number
      await _loadNextReceiptNumber();
    }
  }

  Future<void> _loadNextReceiptNumber() async {
    try {
      _receiptNumber = await _invoiceDao.nextSequentialNumber('PIN');
      notifyListeners();
    } catch (_) {
      _receiptNumber = 'PIN-0001';
      notifyListeners();
    }
  }

  Future<void> _loadBalance() async {
    try {
      final bal = await _invoiceDao.getClientBalance(customerId);
      final invoiced = (bal['totalInvoiced'] as num?)?.toDouble() ?? 0;
      final received = (bal['totalReceived'] as num?)?.toDouble() ?? 0;
      final paymentIn = (bal['totalPaymentIn'] as num?)?.toDouble() ?? 0;
      _currentDue = invoiced - received - paymentIn;
      notifyListeners();
    } catch (_) {
      _currentDue = 0;
      notifyListeners();
    }
  }

  void setAmount(double value) {
    _amount = value < 0 ? 0 : value;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _date = date;
    notifyListeners();
  }

  void setNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  void setAttachedImage(String? path) {
    _attachedImagePath = path;
    notifyListeners();
  }

  Future<void> save() async {
    if (_amount <= 0) {
      _errorMessage = 'Amount must be greater than 0';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final invoice = InvoiceModel(
        id: editingInvoiceId,
        invoiceNumber: _receiptNumber,
        customerId: customerId,
        clientName: customerName,
        clientAddress: null,
        invoiceDate: _date.toUtc().toIso8601String(),
        subtotal: 0,
        total: _amount,
        receivedAmount: 0,
        status: 'paid',
        paymentStatus: 'paid',
        template: 'taxTheme1',
        documentType: 'payment_in',
        attachedImage: _attachedImagePath,
        customNotes: _notes.isNotEmpty ? _notes : null,
        createdAt: now,
        updatedAt: now,
      );

      if (editingInvoiceId != null) {
        final updated = await _invoiceDao.updateInvoice(editingInvoiceId!, invoice);
        if (updated == 0) {
          throw Exception('Payment record not found for update');
        }
      } else {
        await _invoiceDao.insertInvoice(invoice);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save payment: $e';
      _isSaving = false;
      notifyListeners();
      rethrow;
    }
  }
}
