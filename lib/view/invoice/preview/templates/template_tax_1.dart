import 'package:flutter/material.dart';
import '../../controller/create_invoice_controller.dart';
import 'invoice_template_base.dart';

class TemplateTax1 extends InvoiceTemplate {
  const TemplateTax1({super.key, required super.invoice});

  @override
  Widget buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'FM Sons',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text('Construction & Supplies', style: TextStyle(fontSize: 13)),
        Divider(height: 24),
      ],
    );
  }

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Bill To
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill To',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(invoice.customerName ?? '-'),
            ],
          ),
        ),

        /// Invoice Meta
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _metaRow('Invoice No', invoice.invoiceNumber),
            _metaRow('Date', invoice.invoiceDate.toString().split(' ').first),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildItems(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),

        /// Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Row(
            children: const [
              Expanded(flex: 4, child: Text('Description')),
              Expanded(child: Text('Qty')),
              Expanded(child: Text('Unit')),
              Expanded(child: Text('Rate')),
              Expanded(child: Text('Amount', textAlign: TextAlign.right)),
            ],
          ),
        ),

        /// Items
        ...invoice.items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text(item.name)),
                Expanded(child: Text(item.quantity.toString())),
                Expanded(child: Text(item.unit)),
                Expanded(child: Text(item.rate.toStringAsFixed(2))),
                Expanded(
                  child: Text(
                    item.total.toStringAsFixed(2),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget buildTotals(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 16),
            Text(
              'PKR ${invoice.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 24),
        Text(
          'Terms & Conditions',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Text('Payment due within 30 days.', style: TextStyle(fontSize: 12)),
        SizedBox(height: 32),
        Text('Authorized Signature'),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
