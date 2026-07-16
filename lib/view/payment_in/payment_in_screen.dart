import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/shared/notes_attachment_widget.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    try {
      await _controller.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment saved — ${_controller.receiptNumber}'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_controller.errorMessage ?? e}')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_controller.receiptNumber} deleted')),
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
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
          isNewRecord ? 'Take Payment' : 'Payment Receipt',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          if (!isNewRecord && _isViewMode) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: () {
                // Share PDF — future: trigger PDF generation + share
              },
            ),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Party name (always read-only) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    FMSons.accent.withValues(alpha: 0.12),
                                child: Text(
                                  widget.customerName.isNotEmpty
                                      ? widget.customerName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: FMSons.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.customerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Current Due (read-only) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                FMSons.accent.withValues(alpha: 0.08),
                                FMSons.accent.withValues(alpha: 0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: FMSons.accent.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Balance Due',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${_controller.currentDue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _controller.currentDue > 0
                                      ? Colors.orange.shade700
                                      : Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Receipt No. + Date row ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Receipt No.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _controller.receiptNumber,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 32,
                                child: VerticalDivider(
                                  width: 24,
                                  thickness: 1,
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isViewMode ? null : _pickDate,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy')
                                          .format(_controller.date),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Amount input ──
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: TextInputType.number,
                          autofocus: isNewRecord,
                          readOnly: _isViewMode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Amount Received *',
                            prefixText: 'Rs. ',
                            prefixStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            filled: true,
                            fillColor: _isViewMode
                                ? Colors.grey.shade100
                                : theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
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

                        const SizedBox(height: 16),

                        // ── Notes + Photo ──
                        NotesAttachmentWidget(
                          notes: _controller.notes,
                          attachedImagePath: _controller.attachedImagePath,
                          onNotesChanged: _controller.setNotes,
                          onImageChanged: _controller.setAttachedImage,
                          editable: !_isViewMode,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _isViewMode && !isNewRecord
            ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _deletePayment,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FMSons.accent,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _switchToEditMode,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
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
                    shape: const StadiumBorder(),
                  ),
                  onPressed: _controller.isSaving ? null : _save,
                  child: _controller.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
      ),
    );
  }
}

