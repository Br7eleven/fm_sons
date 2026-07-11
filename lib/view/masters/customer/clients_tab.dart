import 'package:fm_sons/utils/money_utils.dart';
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';

import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/view/masters/customer/add_party_form_sheet.dart';
import 'package:fm_sons/view/masters/customer/customer_controller.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';
import 'client_detail_screen.dart';

class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key});

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  final InvoiceDao _invoiceDao = InvoiceDao();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<CustomerController>().initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomerSheet() async {
    final messenger = ScaffoldMessenger.of(context);

    final result = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddPartyFormSheet(),
    );

    if (result == null || !mounted) return;

    try {
      await context.read<CustomerController>().addOrGetCustomer(result);
      messenger.showSnackBar(const SnackBar(content: Text('Party added')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to add party: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerController>();
    final allCustomers = controller.customers;
    final customers = _searchQuery.isEmpty
        ? allCustomers
        : allCustomers
              .where(
                (c) =>
                    c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (c.phone ?? '').contains(_searchQuery) ||
                    (c.address ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Parties',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCustomerSheet,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Party'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FMSons.accent,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search parties...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (customers.isEmpty && _searchQuery.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No parties match "$_searchQuery"',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else if (customers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No parties found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add parties to track their invoices and manage party details.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => ElevatedButton.icon(
                      onPressed: _showAddCustomerSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Your First Party'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FMSons.accent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...customers.map(
              (c) => _ClientListTile(customer: c, invoiceDao: _invoiceDao),
            ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                            CLIENT LIST TILE                                  */
/* -------------------------------------------------------------------------- */

class _ClientListTile extends StatefulWidget {
  final Customer customer;
  final InvoiceDao invoiceDao;

  const _ClientListTile({required this.customer, required this.invoiceDao});

  @override
  State<_ClientListTile> createState() => _ClientListTileState();
}

class _ClientListTileState extends State<_ClientListTile> {
  Map<String, dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final data = await widget.invoiceDao.getClientBalance(widget.customer.id);
    if (mounted) setState(() => _balance = data);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    final bal = _balance;
    final hasTransactions = bal != null && (bal['totalInvoiced'] as double) > 0;
    final due = hasTransactions
        ? normalizeMoney((bal['totalInvoiced'] as double) - (bal['totalReceived'] as double))
        : 0.0;

    return Column(
      key: ValueKey(c.id),
      children: [
        InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClientDetailScreen(customer: c)),
            );
            _loadBalance();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    /// Initials circle avatar (accepted ref pattern)
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: FMSons.accent.withValues(alpha: 0.12),
                      child: Text(
                        c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FMSons.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (c.phone != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                c.phone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
                if (hasTransactions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _miniStat(
                        'Total',
                        bal['totalInvoiced'] as double,
                        FMSons.accent,
                      ),
                      const SizedBox(width: 16),
                      _miniStat(
                        'Paid',
                        bal['totalReceived'] as double,
                        Colors.green.shade600,
                      ),
                      const SizedBox(width: 16),
                      _miniStat('Due', due, Colors.orange.shade700),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // Thin 1px divider per DESIGN.md flat list rule
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _miniStat(String label, double amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rs. ${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}

