import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/local/models/invoice_model.dart';
import '../shared/date_range_filter.dart';
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

    try {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateInvoiceScreen(invoiceId: invoice.id!),
        ),
      );

      if (!mounted) return;
      await context.read<InvoiceController>().loadSavedInvoices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open invoice for editing: $e')),
      );
    }
  }

  Future<void> _deleteInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    final controller = context.read<InvoiceController>();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Invoice'),
          content: Text(
            'Delete ${invoice.invoiceNumber}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
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

  Future<void> _previewInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoice.id!),
      ),
    );
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
              hintText: 'Search contract or invoice #',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
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
                      onShareTap: () => _shareInvoice(invoice),
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

  @override
  Widget build(BuildContext context) {
    final c = statusColor;
    final amountText = currencyFormat.format(invoice.total);

    return Container(
      key: ValueKey(invoice.id),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: icon | invoice # | amount ──
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.description_outlined, color: c, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  amountText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ── Row 2: client name | status chip ──
            Row(
              children: [
                const SizedBox(
                  width: 48,
                ), // align with text above (38 icon + 10 gap)
                Expanded(
                  child: Text(
                    invoice.clientName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: c,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // ── Row 3: date ──
            Row(
              children: [
                const SizedBox(width: 48),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Row 4: action buttons ──
            Row(
              children: [
                const SizedBox(width: 40),
                _actionBtn(
                  Icons.visibility_outlined,
                  'View',
                  onViewTap,
                  context,
                ),
                const SizedBox(width: 16),
                _actionBtn(Icons.edit_outlined, 'Edit', onEditTap, context),
                const SizedBox(width: 16),
                _actionBtn(Icons.share_outlined, 'Share', onShareTap, context),
                const Spacer(),
                _actionBtn(
                  Icons.delete_outline,
                  'Delete',
                  onDeleteTap,
                  context,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback onTap,
    BuildContext context, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isDestructive ? Colors.red.shade400 : Colors.grey.shade600,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDestructive
                    ? Colors.red.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
