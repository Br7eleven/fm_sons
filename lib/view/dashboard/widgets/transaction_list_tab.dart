import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/controller/create_invoice_controller.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/payment_in/payment_in_screen.dart';
import 'package:fm_sons/view/shared/transaction_action_sheet.dart';
import 'quick_links_row.dart';

int _seqNum(String invoiceNumber) {
  final match = RegExp(r'(\d+)$').firstMatch(invoiceNumber);
  if (match == null) return 0;
  return int.tryParse(match.group(1) ?? '0') ?? 0;
}

class TransactionListTab extends StatefulWidget {
  final VoidCallback onAddTxn;
  const TransactionListTab({super.key, required this.onAddTxn});

  @override
  State<TransactionListTab> createState() => _TransactionListTabState();
}

class _TransactionListTabState extends State<TransactionListTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final allInvoices = controller.savedInvoices;
    final invoices = _searchQuery.isEmpty
        ? allInvoices
        : allInvoices.where((i) =>
            i.clientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            i.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
      children: [
        QuickLinksRow(
          onAddTxn: widget.onAddTxn,
          onSaleReport: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sale Report — coming soon')),
            );
          },
          onTxnSettings: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Transaction Settings')),
                  body: const Center(child: Text('Settings')),
                ),
              ),
            );
          },
          onShowAll: () {},
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
            decoration: InputDecoration(
              hintText: 'Search by party or invoice #',
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
        const SizedBox(height: 12),
        if (invoices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No transactions yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
          )
        else
          ...invoices.map((i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TransactionRow(invoice: i),
          )),
      ],
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final InvoiceModel invoice;
  const _TransactionRow({required this.invoice});

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd MMM, yy').format(d);
  }

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

  void _showActionSheet(BuildContext context) {
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

    return InkWell(
      onTap: () {
        if (i.id == null) return;
        if (i.documentType == 'payment_in') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentInScreen(
            customerId: i.customerId ?? '',
            customerName: i.clientName,
            editingInvoiceId: i.id,
          )));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreateInvoiceScreen(invoiceId: i.id, viewMode: true)));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(i.clientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text('#$seq', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _typeBg(), borderRadius: BorderRadius.circular(10)),
              child: Text(_typeLabel(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _typeColor(), letterSpacing: 0.5)),
            ),
            const Spacer(),
            Text(_fmtDate(i.invoiceDate), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text('Rs. ${i.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isPaymentIn ? 'Unused' : 'Balance', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(
                isPaymentIn ? 'Rs. 0' : 'Rs. ${remaining.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: remaining > 0 ? Colors.orange.shade700 : Colors.green.shade600),
              ),
            ]),
            const Spacer(),
            InkWell(onTap: () {
              if (i.id == null) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => InvoicePreviewScreen(previewInvoiceId: i.id, autoPrint: true)));
            }, child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.print_outlined, size: 18, color: Colors.grey.shade500))),
            InkWell(onTap: () => _showActionSheet(context), child: Padding(padding: const EdgeInsets.all(6), child: Icon(Icons.share_outlined, size: 18, color: Colors.grey.shade500))),
            InkWell(
              onTap: () => _showActionSheet(context),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
