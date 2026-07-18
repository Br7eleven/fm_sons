import 'package:fm_sons/utils/money_utils.dart';
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/payment_in/payment_in_screen.dart';
import 'package:fm_sons/view/shared/date_range_filter.dart';
import 'package:fm_sons/view/shared/share_transaction_bottom_sheet.dart';
import 'customer_controller.dart';
import 'customer_edit_screen.dart';
import 'customer_model.dart';

class ClientDetailScreen extends StatefulWidget {
  final Customer customer;
  const ClientDetailScreen({super.key, required this.customer});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen>
    with SingleTickerProviderStateMixin {
  final InvoiceDao _invoiceDao = InvoiceDao();
  TabController? _tabController;
  int _refreshKey = 0;
  DateTimeRange? _dateRange;
  bool _hasInvoices = true;
  bool _hasEstimates = true;
  bool _hasPayments = false;
  bool _countsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final all = await _invoiceDao.getInvoicesByCustomerId(widget.customer.id);
    if (!mounted) return;
    final invoices = all.where((i) => i.documentType == 'invoice').length;
    final estimates = all.where((i) => i.documentType == 'estimate').length;
    final payments = all.where((i) => i.documentType == 'payment_in').length;
    _tabController?.dispose();
    _tabController = null;
    setState(() {
      _hasInvoices = invoices > 0;
      _hasEstimates = estimates > 0;
      _hasPayments = payments > 0;
      _countsLoaded = true;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _editInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    try {
      if (!mounted) return;
      if (invoice.documentType == 'payment_in') {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentInScreen(
              customerId: invoice.customerId ?? '',
              customerName: invoice.clientName,
              editingInvoiceId: invoice.id,
            ),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateInvoiceScreen(invoiceId: invoice.id!),
          ),
        );
      }
      if (mounted) {
        _refreshKey++;
        _loadCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open: $e')));
      }
    }
  }

  void _printInvoice(InvoiceModel invoice) {
    if (invoice.id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoice.id!, autoPrint: true),
      ),
    );
  }

  // _deleteInvoice removed — delete is handled in the detail/preview screen's bottom bar

  Future<void> _editCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerEditScreen(customer: widget.customer),
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    final controller = context.read<CustomerController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Client'),
        content: Text(
          'Delete ${widget.customer.name}? This will not delete associated invoices.',
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
        await controller.deleteCustomer(widget.customer.id);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          c.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
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
              if (v == 'edit') _editCustomer();
              if (v == 'delete') _deleteCustomer();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        customerName: c.name,
        onTakePayment: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentInScreen(
                customerId: c.id,
                customerName: c.name,
              ),
            ),
          );
          if (result == true && mounted) {
            _refreshKey++;
            _loadCounts();
          }
        },
        onAddSale: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // ── Client info header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.phone != null) _infoRow(Icons.phone_outlined, c.phone!),
                if (c.address != null) ...[
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, c.address!),
                ],
                const SizedBox(height: 10),
                // ── Date filter ──
                DateRangeFilter(
                  range: _dateRange,
                  onChanged: (r) => setState(() => _dateRange = r),
                ),
                const SizedBox(height: 14),
                // ── Balance card ──
                _ClientBalanceCard(
                  customerId: c.id,
                  invoiceDao: _invoiceDao,
                  refreshKey: _refreshKey,
                ),
              ],
            ),
          ),

          // ── All transactions (combined, date-sorted) ──
          if (!_countsLoaded)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasInvoices || _hasEstimates || _hasPayments)
            Expanded(
              child: _allDocList(c.id),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _allDocList(String customerId) {
    return _DocumentList(
      customerId: customerId,
      invoiceDao: _invoiceDao,
      refreshKey: _refreshKey,
      docType: null, // no filter — show all document types
      dateRange: _dateRange,
      onEdit: _editInvoice,
      onPreview: _printInvoice,
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            BALANCE CARD                                      */
/* -------------------------------------------------------------------------- */

class _ClientBalanceCard extends StatelessWidget {
  final String customerId;
  final InvoiceDao invoiceDao;
  final int refreshKey;

  const _ClientBalanceCard({
    required this.customerId,
    required this.invoiceDao,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey('bal_${customerId}_$refreshKey'),
      future: invoiceDao.getClientBalance(customerId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final d = snap.data!;
        final invoiced = d['totalInvoiced'] as double;
        final received = d['totalReceived'] as double;
        final paymentIn = d['totalPaymentIn'] as double? ?? 0.0;
        final due = normalizeMoney(invoiced - received - paymentIn);
        final pct = invoiced > 0 ? ((received + paymentIn) / invoiced) : 0.0;

        final isCredit = due < 0;
        final absDue = due.abs();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                FMSons.accent.withValues(alpha: 0.08),
                FMSons.accent.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FMSons.accent.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _balCol('Total', invoiced, FMSons.accent),
                  _balCol('Paid', received + paymentIn, Colors.green.shade600),
                  // Balance with direction indicator (Fix #3)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          absDue == 0
                              ? 'Rs. 0'
                              : 'Rs. ${absDue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isCredit
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (absDue > 0)
                              Icon(
                                isCredit
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                size: 10,
                                color: isCredit
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                            if (absDue > 0) const SizedBox(width: 2),
                            Text(
                              absDue == 0
                                  ? 'Balance Clear'
                                  : isCredit
                                      ? 'Receivable'
                                      : 'Payable',
                              style: TextStyle(
                                fontSize: 10,
                                color: isCredit
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (invoiced > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${(pct.clamp(0, 1) * 100).toStringAsFixed(0)}% paid',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _balCol(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            DOCUMENT LIST                                     */
/* -------------------------------------------------------------------------- */

class _DocumentList extends StatelessWidget {
  final String customerId;
  final InvoiceDao invoiceDao;
  final int refreshKey;
  final String? docType; // null = show all document types
  final DateTimeRange? dateRange;
  final void Function(InvoiceModel) onEdit;
  final void Function(InvoiceModel) onPreview;

  const _DocumentList({
    required this.customerId,
    required this.invoiceDao,
    required this.refreshKey,
    this.docType, // null = show all
    this.dateRange,
    required this.onEdit,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvoiceModel>>(
      key: ValueKey('docs_${customerId}_${docType ?? 'all'}_$refreshKey'),
      future: invoiceDao.getInvoicesByCustomerId(customerId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final filtered = all.where((i) {
          // Filter by docType only when non-null
          if (docType != null && i.documentType != docType) return false;
          if (dateRange != null) {
            final d = DateTime.tryParse(i.invoiceDate)?.toLocal();
            if (d == null) return false;
            if (d.isBefore(dateRange!.start) ||
                d.isAfter(dateRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }
          return true;
        }).toList();

        // Sort by date descending (all types together)
        filtered.sort((a, b) {
          final aDate = DateTime.tryParse(a.invoiceDate)?.toLocal() ?? DateTime(0);
          final bDate = DateTime.tryParse(b.invoiceDate)?.toLocal() ?? DateTime(0);
          return bDate.compareTo(aDate);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No transactions yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          itemBuilder: (_, i) => _DocTile(
            invoice: filtered[i],
            onTap: () => onEdit(filtered[i]),
            onPreview: () => onPreview(filtered[i]),
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            DOCUMENT TILE (ref-matching)                       */
/* -------------------------------------------------------------------------- */

/// Extracts trailing numeric part from an invoice number (e.g. PIN-0001 → 1)
int _seqNum(String invoiceNumber) {
  final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
  if (match == null) return 0;
  return int.tryParse(match.group(1) ?? '0') ?? 0;
}

class _DocTile extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const _DocTile({
    required this.invoice,
    required this.onTap,
    required this.onPreview,
  });

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _typeLabel() {
    switch (invoice.documentType) {
      case 'payment_in':
        return 'Payment-In';
      case 'estimate':
        return 'Estimate';
      default:
        return 'Sale';
    }
  }

  Color _typeColor() {
    switch (invoice.documentType) {
      case 'payment_in':
        return Colors.green;
      case 'estimate':
        return Colors.purple;
      default:
        return FMSons.accent;
    }
  }

  void _showShareSheet(BuildContext context) {
    final id = invoice.id;
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareTransactionBottomSheet(
        invoiceId: id,
        documentType: invoice.documentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    final remaining = i.total - i.receivedAmount;
    final isPaymentIn = i.documentType == 'payment_in';
    final typeColor = _typeColor();
    final seq = _seqNum(i.invoiceNumber);

    return Padding(
      key: ValueKey(invoice.id),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Row 1: Type label (left) | #N + date (right) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type label
              Text(
                _typeLabel(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
              const Spacer(),
              // #N + date stacked right-aligned
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '#$seq',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtDate(i.invoiceDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Row 2: Total/Unused (left) | print/share/⋮ (right) ──
          Row(
            children: [
              // Total
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${i.total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 24),

              // Unused (Payment-In) or Balance (Sale/Estimate)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPaymentIn ? 'Unused' : 'Balance',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPaymentIn
                        ? 'Rs. 0'
                        : 'Rs. ${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPaymentIn
                          ? Colors.grey.shade400
                          : remaining > 0
                              ? Colors.orange.shade700
                              : Colors.green.shade600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Action icons — always visible
              InkWell(
                onTap: onPreview,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.print_outlined, size: 20, color: Colors.grey.shade500),
                ),
              ),
              InkWell(
                onTap: () => _showShareSheet(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.share_outlined, size: 20, color: Colors.grey.shade500),
                ),
              ),
              // 3-dot removed — Edit/Delete in detail view, print/share are direct icons
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         STICKY BOTTOM ACTION BAR                            */
/* -------------------------------------------------------------------------- */

class _BottomActionBar extends StatelessWidget {
  final String customerName;
  final VoidCallback onTakePayment;
  final VoidCallback onAddSale;

  const _BottomActionBar({
    required this.customerName,
    required this.onTakePayment,
    required this.onAddSale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FMSons.accent,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onTakePayment,
                  child: const Text(
                    'Take Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FMSons.accent,
                    side: const BorderSide(color: FMSons.accent),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onAddSale,
                  child: const Text(
                    'Add Sale',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
