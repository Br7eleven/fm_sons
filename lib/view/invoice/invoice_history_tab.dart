import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import '../../data/local/models/invoice_model.dart';
import '../payment_in/payment_in_screen.dart';
import '../shared/date_range_filter.dart';
import '../shared/transaction_action_sheet.dart';
import 'controller/create_invoice_controller.dart';
import 'create_invoice_screen.dart';
import 'preview/invoice_preview_screen.dart';

class InvoiceHistoryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback onSettingsTap;

  const InvoiceHistoryAppBar({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Invoice History',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(onPressed: onSettingsTap, icon: const Icon(Icons.settings)),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

enum _InvoiceFilter { all, pending, paid, backedUp }

class InvoiceHistoryTab extends StatefulWidget {
  const InvoiceHistoryTab({super.key});

  @override
  State<InvoiceHistoryTab> createState() => _InvoiceHistoryTabState();
}

class _InvoiceHistoryTabState extends State<InvoiceHistoryTab> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy • hh:mm a');

  String _searchQuery = '';
  _InvoiceFilter _filter = _InvoiceFilter.all;
  DateTimeRange? _dateRange;

  List<InvoiceModel> _applyFilters(List<InvoiceModel> invoices) {
    final query = _searchQuery.trim().toLowerCase();
    final range = _dateRange;
    final filtered = invoices.where((invoice) {
      final matchesFilter = switch (_filter) {
        _InvoiceFilter.all => true,
        _InvoiceFilter.pending => invoice.status.toLowerCase() == 'pending',
        _InvoiceFilter.paid => invoice.status.toLowerCase() == 'paid',
        _InvoiceFilter.backedUp => invoice.status.toLowerCase() == 'backed_up',
      };
      if (!matchesFilter) return false;

      if (range != null) {
        final d = DateTime.tryParse(invoice.invoiceDate)?.toLocal();
        if (d == null) return false;
        if (d.isBefore(range.start) ||
            d.isAfter(range.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return invoice.invoiceNumber.toLowerCase().contains(query) ||
          invoice.clientName.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aDate =
          DateTime.tryParse(a.invoiceDate)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b.invoiceDate)?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  Map<String, List<InvoiceModel>> _groupByMonth(List<InvoiceModel> invoices) {
    final grouped = <String, List<InvoiceModel>>{};

    for (final invoice in invoices) {
      final parsed = DateTime.tryParse(invoice.invoiceDate)?.toLocal();
      final key = parsed == null
          ? 'UNKNOWN'
          : DateFormat('MMMM yyyy').format(parsed).toUpperCase();
      grouped.putIfAbsent(key, () => <InvoiceModel>[]).add(invoice);
    }

    return grouped;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'backed_up':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Saved';
      case 'backed_up':
        return 'Backed Up';
      case 'pending':
        return 'Pending';
      default:
        return status.replaceAll('_', ' ').trim().toUpperCase();
    }
  }

  String _formatDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    if (parsed == null) return rawDate;
    return _dateTimeFormat.format(parsed);
  }

  Future<void> _editInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    if (!mounted) return;

    try {
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

      if (!mounted) return;
      await context.read<InvoiceController>().loadSavedInvoices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open: $e')),
      );
    }
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    final controller = context.read<InvoiceController>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (d) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Invoice',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content: Text(
            'Delete ${invoice.invoiceNumber}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(d, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(d).colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await controller.deleteInvoice(invoice.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${invoice.invoiceNumber} deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete invoice: $e')));
    }
  }

  void _showActionSheet(InvoiceModel invoice) {
    if (invoice.id == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => TransactionActionSheet(invoiceId: invoice.id!),
    );
  }

  Future<void> _previewInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;

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
          builder: (_) => CreateInvoiceScreen(invoiceId: invoice.id!, viewMode: true),
        ),
      );
    }
  }

  Widget _buildChip(String label, _InvoiceFilter filter) {
    final isSelected = _filter == filter;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.textTheme.bodyMedium?.color,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final invoices = _applyFilters(controller.savedInvoices);
    final groupedInvoices = _groupByMonth(invoices);
    return RefreshIndicator(
      onRefresh: controller.loadSavedInvoices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by party or invoice #',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: FMSons.accent, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('All', _InvoiceFilter.all),
                const SizedBox(width: 6),
                _buildChip('Pending', _InvoiceFilter.pending),
                const SizedBox(width: 6),
                _buildChip('Backed Up', _InvoiceFilter.backedUp),
                const SizedBox(width: 6),
                _buildChip('Paid', _InvoiceFilter.paid),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DateRangeFilter(
            range: _dateRange,
            onChanged: (r) => setState(() => _dateRange = r),
          ),
          const SizedBox(height: 16),
          if (invoices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No invoices found',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a new invoice to see customer history here.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ...groupedInvoices.entries.expand((entry) {
              final monthTitle = entry.key;
              final monthInvoices = entry.value;

              return [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    monthTitle,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...monthInvoices.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _InvoiceHistoryCard(
                      invoice: invoice,
                      currencyFormat: _currencyFormat,
                      statusColor: _statusColor(invoice.status),
                      statusLabel: _statusLabel(invoice.status),
                      formattedDate: _formatDate(invoice.invoiceDate),
                      onViewTap: () => _previewInvoice(invoice),
                      onEditTap: () => _editInvoice(invoice),
                      onDeleteTap: () => _deleteInvoice(invoice),
                      onShareTap: () => _showActionSheet(invoice),
                    ),
                  ),
                ),
              ];
            }),
        ],
      ),
    );
  }
}

int _seqNum(String invoiceNumber) {
  final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
  if (match == null) return 0;
  return int.tryParse(match.group(1) ?? '0') ?? 0;
}

class _InvoiceHistoryCard extends StatelessWidget {
  final InvoiceModel invoice;
  final NumberFormat currencyFormat;
  final Color statusColor;
  final String statusLabel;
  final String formattedDate;
  final VoidCallback onViewTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onShareTap;

  const _InvoiceHistoryCard({
    required this.invoice,
    required this.currencyFormat,
    required this.statusColor,
    required this.statusLabel,
    required this.formattedDate,
    required this.onViewTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onShareTap,
  });

  String _typeLabel() {
    switch (invoice.documentType) {
      case 'payment_in': return 'PAYMENT-IN';
      case 'estimate': return 'ESTIMATE';
      default: return 'SALE';
    }
  }

  Color _typeColor() {
    switch (invoice.documentType) {
      case 'payment_in': return Colors.teal;
      case 'estimate': return Colors.purple;
      default: return FMSons.accent;
    }
  }

  Color _typeBg() {
    switch (invoice.documentType) {
      case 'payment_in': return Colors.teal.shade50;
      case 'estimate': return Colors.purple.shade50;
      default: return FMSons.accent.withValues(alpha: 0.1);
    }
  }

  void _showShareSheet(BuildContext context) {
    final id = invoice.id;
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => TransactionActionSheet(invoiceId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i = invoice;
    final remaining = i.total - i.receivedAmount;
    final isPaymentIn = i.documentType == 'payment_in';
    final seq = _seqNum(i.invoiceNumber);
    final remainingStr = isPaymentIn ? 'Rs. 0' : 'Rs. ${remaining.toStringAsFixed(0)}';
    final remainingColor = isPaymentIn ? Colors.grey.shade400 : (remaining > 0 ? Colors.orange.shade700 : Colors.green.shade600);

    return Container(
      key: ValueKey(invoice.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onViewTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Party name | #N
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(i.clientName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text('#$seq', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
              ]),
              const SizedBox(height: 4),
              // Row 2: Type pill | date
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _typeBg(), borderRadius: BorderRadius.circular(10)),
                  child: Text(_typeLabel(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeColor(), letterSpacing: 0.5)),
                ),
                const Spacer(),
                Text(formattedDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ]),
              const SizedBox(height: 10),
              // Row 3: Total + Balance | print share ⋮
              Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text('Rs. ${i.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isPaymentIn ? 'Unused' : 'Balance', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(remainingStr, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: remainingColor)),
                ]),
                const Spacer(),
                InkWell(onTap: () {
                  if (invoice.id == null) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoice.id!, autoPrint: true)));
                }, child: Padding(
                  padding: const EdgeInsets.all(6), child: Icon(Icons.print_outlined, size: 18, color: Colors.grey.shade500))),
                InkWell(onTap: () => _showShareSheet(context), child: Padding(
                  padding: const EdgeInsets.all(6), child: Icon(Icons.share_outlined, size: 18, color: Colors.grey.shade500))),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                  onSelected: (v) {
                    if (v == 'share') _showShareSheet(context);
                    if (v == 'edit') onEditTap();
                    if (v == 'delete') onDeleteTap();
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
