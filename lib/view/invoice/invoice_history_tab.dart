import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/local/models/invoice_model.dart';
import '../shared/avatar_widget.dart';
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
      toolbarHeight: 84,
      titleSpacing: 16,
      title: Row(
        children: [
          const AvatarWidget(size: 44),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'FM Sons Government Contracts',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: onSettingsTap, icon: const Icon(Icons.settings)),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(84);
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
    symbol: 'PKR ',
    decimalDigits: 0,
  );
  final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy • hh:mm a');

  String _searchQuery = '';
  _InvoiceFilter _filter = _InvoiceFilter.all;

  List<InvoiceModel> _applyFilters(List<InvoiceModel> invoices) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = invoices.where((invoice) {
      final matchesFilter = switch (_filter) {
        _InvoiceFilter.all => true,
        _InvoiceFilter.pending => invoice.status.toLowerCase() == 'pending',
        _InvoiceFilter.paid => invoice.status.toLowerCase() == 'paid',
        _InvoiceFilter.backedUp => invoice.status.toLowerCase() == 'backed_up',
      };

      if (!matchesFilter) return false;
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
    final controller = context.read<InvoiceController>();

    try {
      await controller.loadInvoiceForEditing(invoice.id!);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
      );

      if (!mounted) return;
      await controller.loadSavedInvoices();
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
    final formattedDate = _formatDate(invoice.invoiceDate);
    final formattedAmount = _currencyFormat.format(invoice.total);

    final shareText =
        '''
📄 Invoice Details

Invoice #: ${invoice.invoiceNumber}
Client: ${invoice.clientName}
Date: $formattedDate
Amount: $formattedAmount
Status: ${_statusLabel(invoice.status)}

Generated by FM Sons Billing App
    '''
            .trim();

    try {
      await Share.share(shareText, subject: 'Invoice ${invoice.invoiceNumber}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share invoice: $e')));
    }
  }

  Future<void> _previewInvoice(InvoiceModel invoice) async {
    if (invoice.id == null) return;
    final controller = context.read<InvoiceController>();

    try {
      await controller.loadInvoiceForEditing(invoice.id!);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InvoicePreviewScreen()),
      );

      if (!mounted) return;
      await controller.loadSavedInvoices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to preview invoice: $e')));
    }
  }

  Widget _buildChip(String label, _InvoiceFilter filter) {
    final isSelected = _filter == filter;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primaryContainer,
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
    final pendingCount = controller.savedInvoices
        .where((invoice) => invoice.status.toLowerCase() == 'pending')
        .length;

    return RefreshIndicator(
      onRefresh: controller.loadSavedInvoices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.errorContainer,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Offline Mode active. $pendingCount items pending backup.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: controller.loadSavedInvoices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
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
                const SizedBox(width: 10),
                _buildChip('Pending', _InvoiceFilter.pending),
                const SizedBox(width: 10),
                _buildChip('Backed Up', _InvoiceFilter.backedUp),
                const SizedBox(width: 10),
                _buildChip('Paid', _InvoiceFilter.paid),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    monthTitle,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                ...monthInvoices.map(
                  (invoice) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
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
    final iconColor = statusColor;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.description_outlined, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.clientName,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormat.format(invoice.total),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: onShareTap,
                            icon: Icon(
                              Icons.share_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            tooltip: 'Share Invoice',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onViewTap,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Invoice'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDeleteTap,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
