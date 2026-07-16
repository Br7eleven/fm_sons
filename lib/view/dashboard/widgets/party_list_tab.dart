import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/utils/money_utils.dart';
import 'package:fm_sons/view/masters/customer/customer_controller.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';
import 'package:fm_sons/view/masters/customer/client_detail_screen.dart';

class PartyListTab extends StatefulWidget {
  const PartyListTab({super.key});

  @override
  State<PartyListTab> createState() => _PartyListTabState();
}

class _PartyListTabState extends State<PartyListTab> {
  final InvoiceDao _invoiceDao = InvoiceDao();
  final Map<String, Map<String, dynamic>?> _balances = {};
  final Map<String, String?> _lastDates = {};
  String _searchQuery = '';

  void _loadData(Iterable<Customer> customers) {
    for (final c in customers) {
      if (!_balances.containsKey(c.id)) {
        _balances[c.id] = null;
        _loadPartyData(c);
      }
    }
  }

  Future<void> _loadPartyData(Customer c) async {
    final bal = await _invoiceDao.getClientBalance(c.id);
    if (!mounted) return;
    final invoiced = (bal['totalInvoiced'] as num?)?.toDouble() ?? 0;
    final received = (bal['totalReceived'] as num?)?.toDouble() ?? 0;
    final paymentIn = (bal['totalPaymentIn'] as num?)?.toDouble() ?? 0;
    final due = normalizeMoney(invoiced - received - paymentIn);

    // Get last transaction date
    final invoices = await _invoiceDao.getInvoicesByCustomerId(c.id);
    String? lastDate;
    if (invoices.isNotEmpty) {
      final sorted = List.from(invoices)
        ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));
      lastDate = sorted.first.invoiceDate;
    }

    if (!mounted) return;
    setState(() {
      _balances[c.id] = {
        'totalInvoiced': invoiced,
        'totalReceived': received,
        'totalPaymentIn': paymentIn,
        'due': due,
      };
      _lastDates[c.id] = lastDate;
    });
  }

  String _fmtDate(String? raw) {
    if (raw == null) return '';
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return '';
    return DateFormat('dd MMM, yy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomerController>();
    final customers = controller.customers;
    _loadData(customers);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search parties...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
        if (customers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No parties yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
          )
        else
          ...customers.where((c) {
            if (_searchQuery.isEmpty) return true;
            return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).map((c) {
            final bal = _balances[c.id];
            final due = (bal?['due'] as double?) ?? 0;
            final lastDate = _lastDates[c.id];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PartyRow(customer: c, due: due, lastDate: lastDate, fmtDate: _fmtDate),
            );
          }),
      ],
    );
  }
}

class _PartyRow extends StatelessWidget {
  final Customer customer;
  final double due;
  final String? lastDate;
  final String Function(String?) fmtDate;

  const _PartyRow({required this.customer, required this.due, this.lastDate, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailScreen(customer: c)));
        if (context.mounted) {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
            if (lastDate != null) ...[const SizedBox(height: 2), Text(fmtDate(lastDate), style: TextStyle(fontSize: 11, color: Colors.grey.shade500))],
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              due == 0 ? 'Rs. 0' : 'Rs. ${due.abs().toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: due == 0 ? Colors.grey : due > 0 ? Colors.green.shade600 : Colors.red.shade600),
            ),
            if (due != 0) ...[const SizedBox(height: 2), Text(due > 0 ? "You'll Get" : "You'll Pay", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: due > 0 ? Colors.green.shade600 : Colors.red.shade400))],
          ]),
        ]),
      ),
    );
  }
}
