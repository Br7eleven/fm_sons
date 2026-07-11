import 'package:fm_sons/utils/money_utils.dart';
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/view/invoice/controller/create_invoice_controller.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/shared/date_range_filter.dart';
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
    _tabController?.dispose();
    _tabController = null;
    setState(() {
      _hasInvoices = invoices > 0;
      _hasEstimates = estimates > 0;
      _countsLoaded = true;
      if (_hasInvoices && _hasEstimates) {
        _tabController = TabController(length: 2, vsync: this);
      }
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateInvoiceScreen(invoiceId: invoice.id!),
        ),
      );
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

  Future<void> _previewInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoice.id!),
      ),
    );
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete'),
        content: Text(
          'Delete ${invoice.invoiceNumber}? This cannot be undone.',
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
        await context.read<InvoiceController>().deleteInvoice(invoice.id!);
        if (mounted) {
          _refreshKey++;
          _loadCounts();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Future<void> _shareInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          previewInvoiceId: invoice.id!,
          autoShare: true,
        ),
      ),
    );
  }

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
        onTakePayment: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
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

          // ── Tab bar (only when both types exist) ──
          if (_countsLoaded && _hasInvoices && _hasEstimates)
            Container(
              color: Theme.of(context).cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: FMSons.accent,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: FMSons.accent,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Invoices'),
                  Tab(text: 'Estimates'),
                ],
              ),
            ),

          // ── Content ──
          if (!_countsLoaded)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_hasInvoices && _hasEstimates)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _docList(c.id, 'invoice'),
                  _docList(c.id, 'estimate'),
                ],
              ),
            )
          else if (_hasInvoices || _hasEstimates)
            Expanded(
              child: _docList(c.id, _hasInvoices ? 'invoice' : 'estimate'),
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
                      'No invoices or estimates yet',
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

  Widget _docList(String customerId, String docType) {
    return _DocumentList(
      customerId: customerId,
      invoiceDao: _invoiceDao,
      refreshKey: _refreshKey,
      docType: docType,
      dateRange: _dateRange,
      onEdit: _editInvoice,
      onPreview: _previewInvoice,
      onShare: _shareInvoice,
      onDelete: _deleteInvoice,
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
        final due = normalizeMoney(invoiced - received);
        final pct = invoiced > 0 ? (received / invoiced) : 0.0;

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
                  _balCol('Paid', received, Colors.green.shade600),
                  _balCol('Due', due, Colors.orange.shade700),
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
                    '${(pct * 100).toStringAsFixed(0)}% paid',
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
  final String docType;
  final DateTimeRange? dateRange;
  final void Function(InvoiceModel) onEdit;
  final void Function(InvoiceModel) onPreview;
  final void Function(InvoiceModel) onShare;
  final void Function(InvoiceModel)? onDelete;

  const _DocumentList({
    required this.customerId,
    required this.invoiceDao,
    required this.refreshKey,
    required this.docType,
    this.dateRange,
    required this.onEdit,
    required this.onPreview,
    required this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvoiceModel>>(
      key: ValueKey('docs_${customerId}_${docType}_$refreshKey'),
      future: invoiceDao.getInvoicesByCustomerId(customerId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final filtered = all.where((i) {
          if (i.documentType != docType) return false;
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

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    docType == 'invoice'
                        ? Icons.receipt_long_outlined
                        : Icons.description_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No ${docType}s for this client',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _DocTile(
            invoice: filtered[i],
            onTap: () => onEdit(filtered[i]),
            onPreview: () => onPreview(filtered[i]),
            onShare: () => onShare(filtered[i]),
            onDelete: onDelete != null ? () => onDelete!(filtered[i]) : null,
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            DOCUMENT TILE                                     */
/* -------------------------------------------------------------------------- */

class _DocTile extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  const _DocTile({
    required this.invoice,
    required this.onTap,
    required this.onPreview,
    required this.onShare,
    this.onDelete,
  });

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    final remaining = i.total - i.receivedAmount;
    final isEstimate = i.documentType == 'estimate';
    final fullyPaid = !isEstimate && i.receivedAmount >= i.total && i.total > 0;

    return Container(
      key: ValueKey(invoice.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isEstimate
                      ? Colors.purple.shade50
                      : fullyPaid
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEstimate
                      ? Icons.description_outlined
                      : Icons.receipt_outlined,
                  color: isEstimate
                      ? Colors.purple.shade400
                      : fullyPaid
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fmtDate(i.invoiceDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs ${i.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (!isEstimate && !fullyPaid && i.total > 0)
                    Text(
                      'Due: ${remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isEstimate)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Estimate',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.purple.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (!isEstimate)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: FMSons.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sale',
                        style: TextStyle(
                          fontSize: 9,
                          color: FMSons.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Preview'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Share'),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onTap();
                  if (v == 'preview') onPreview();
                  if (v == 'share') onShare();
                  if (v == 'delete') onDelete?.call();
                },
              ),
            ],
          ),
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
