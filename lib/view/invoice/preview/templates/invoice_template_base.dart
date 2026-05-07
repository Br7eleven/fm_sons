import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../controller/create_invoice_controller.dart';

/// Base class for all invoice templates
/// Optimized for A4 Letterhead display without overflow.
abstract class InvoiceTemplate extends StatelessWidget {
  final InvoiceController invoice;

  static const int _maxPreviewItems = 18;
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'PKR ',
    decimalDigits: 2,
  );

  const InvoiceTemplate({super.key, required this.invoice});

  Widget buildHeader(BuildContext context);
  Widget buildInvoiceInfo(BuildContext context);
  Widget buildItems(BuildContext context);
  Widget buildTotals(BuildContext context);
  Widget buildFooter(BuildContext context);

  List<InvoiceItem> get previewItems {
    if (invoice.items.length <= _maxPreviewItems) {
      return invoice.items;
    }
    return invoice.items.take(_maxPreviewItems).toList(growable: false);
  }

  int get hiddenItemsCount => invoice.items.length - previewItems.length;

  String get customerDisplayName {
    final text = invoice.customerName?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String get invoiceDateLabel =>
      DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

  String get amountInWordsLabel {
    final text = invoice.amountInWords.trim();
    return text.isEmpty ? 'Zero Rupees only' : text;
  }

  double get subtotalAmount => invoice.totalAmount;
  double get taxAmount => 0;
  double get grandTotalAmount => subtotalAmount + taxAmount;

  String formatMoney(num value) => _moneyFormat.format(value);

  String formatQuantity(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toStringAsFixed(0);
    }
    return asDouble.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 794,
        height: 1123,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(context),
            const SizedBox(height: 20),

            buildInvoiceInfo(context),
            const SizedBox(height: 15),

            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.hardEdge,
                child: buildItems(context),
              ),
            ),

            const Divider(thickness: 1, color: Colors.black26),
            const SizedBox(height: 10),
            buildTotals(context),

            const SizedBox(height: 30),
            buildFooter(context),
          ],
        ),
      ),
    );
  }
}
