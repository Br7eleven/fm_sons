import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/shared/notes_attachment_widget.dart';
import 'package:fm_sons/view/shared/transaction_action_sheet.dart';
import 'payment_in_controller.dart';

class PaymentInScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final int? editingInvoiceId;

  const PaymentInScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.editingInvoiceId,
  });

  @override
  State<PaymentInScreen> createState() => _PaymentInScreenState();
}

class _PaymentInScreenState extends State<PaymentInScreen> {
  late final PaymentInController _controller;
  late final TextEditingController _amountCtrl;
  bool _isReady = false;
  bool _isViewMode = true; // starts in view mode for existing, false for new

  @override
  void initState() {
    super.initState();
    _controller = PaymentInController(
      customerId: widget.customerId,
      customerName: widget.customerName,
      editingInvoiceId: widget.editingInvoiceId,
    );
    _amountCtrl = TextEditingController();
    _isViewMode = widget.editingInvoiceId != null; // view mode for existing records
    _controller.addListener(_onControllerChange);
    // Initial ready check — controller may already have data if sync
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAmountFromController();
      if (mounted) {
        setState(() => _isReady = true);
      }
    });
  }

  void _onControllerChange() {
    if (mounted) {
      _syncAmountFromController();
      setState(() {});
    }
  }

  void _syncAmountFromController() {
    final amt = _controller.amount;
    final currentText = _amountCtrl.text;
    if (amt > 0 && currentText != amt.toStringAsFixed(0)) {
      _amountCtrl.text = amt.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _switchToEditMode() {
    setState(() {
      _isViewMode = false;
      if (_controller.amount > 0) {
        _amountCtrl.text = _controller.amount.toStringAsFixed(0);
      }
    });
  }

  Future<void> _pickDate() async {
    if (_isViewMode) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) _controller.setDate(picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    _controller.setAmount(amount);
    if (_controller.amount <= 0) {
      showAppSnackBar(context, 'Enter a valid amount', isError: true);
      return;
    }

    try {
      await _controller.save();
      if (!mounted) return;
      showAppSnackBar(context, 'Payment saved — ${_controller.receiptNumber}', isError: false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, '${_controller.errorMessage ?? e}', isError: true);
    }
  }

  Future<void> _deletePayment() async {
    if (_controller.editingInvoiceId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Payment'),
        content: Text(
          'Delete ${_controller.receiptNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        final dao = InvoiceDao();
        await dao.deleteInvoice(_controller.editingInvoiceId!);
        if (!mounted) return;
        showAppSnackBar(context, '${_controller.receiptNumber} deleted', isError: false);
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        showAppSnackBar(context, 'Delete failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewRecord = widget.editingInvoiceId == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.customerName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          if (!isNewRecord && _isViewMode) ...[
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'edit') _switchToEditMode();
                if (v == 'delete') _deletePayment();
              },
            ),
          ],
          if (!isNewRecord && !_isViewMode)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'More',
              onPressed: () {},
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: !_isReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Receipt No. + Date row (compact, like InvoiceHeader) ──
                        Container(
                          color: theme.cardColor,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Receipt No.',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _controller.receiptNumber,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(
                                  width: 24,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _isViewMode ? null : _pickDate,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(_controller.date),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            if (!_isViewMode) ...[
                                              const SizedBox(width: 2),
                                              Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade500),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // ── Current Balance Due (compact) ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: FMSons.accent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: FMSons.accent.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Balance Due',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                const Spacer(),
                                Text(
                                  'Rs. ${_controller.currentDue.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: _controller.currentDue > 0
                                        ? Colors.orange.shade700
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Amount input (matching new sale customer field height) ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: TextInputType.number,
                            autofocus: isNewRecord,
                            readOnly: _isViewMode,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Amount Received *',
                              prefixText: 'Rs. ',
                              prefixStyle: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: FMSons.accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Notes + Photo (same as new sale) ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: NotesAttachmentWidget(
                            notes: _controller.notes,
                            attachedImagePath: _controller.attachedImagePath,
                            onNotesChanged: _controller.setNotes,
                            onImageChanged: _controller.setAttachedImage,
                            editable: !_isViewMode,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sticky bottom bar ──
                _buildBottomBar(theme),
              ],
            ),
        ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isNewRecord = widget.editingInvoiceId == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: _isViewMode && !isNewRecord
          ? Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade400),
                        foregroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _deletePayment,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FMSons.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _switchToEditMode,
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  width: 36,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => TransactionActionSheet(
                          invoiceId: widget.editingInvoiceId!,
                        ),
                      );
                    },
                    child: const Icon(Icons.more_vert, size: 20),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FMSons.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _controller.isSaving ? null : _save,
                child: _controller.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Payment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
    );
  }
}

