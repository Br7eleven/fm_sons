import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controller/create_invoice_controller.dart';
import '../../../settings/company_profile_controller.dart';

/// Base class for all invoice templates
/// Optimized for A4 Letterhead display without overflow.
abstract class InvoiceTemplate extends StatelessWidget {
  final InvoiceController invoice;

  static const int itemsPerPage = 25;
  static const int maxItemsWithTotals = 16;
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 2,
  );

  const InvoiceTemplate({super.key, required this.invoice});

  Widget buildHeader(BuildContext context);
  Widget buildInvoiceInfo(BuildContext context);
  Widget buildItems(BuildContext context, {required List<InvoiceItem> pageItems, required int startIndex, required bool isLastPage, required bool isFinalPage});
  Widget buildTotals(BuildContext context);
  Widget buildFooter(BuildContext context);

  List<List<InvoiceItem>> get pageItemChunks {
    final items = invoice.items;
    final n = items.length;
    if (n == 0) return [[]];
    if (n <= maxItemsWithTotals) return [items];

    // 17–25 items: one items-only page + totals-only page
    if (n <= itemsPerPage) return [items, []];

    // > 25 items: first page = 25 items (no totals), then distribute
    // remaining so the final chunk has ≤ maxItemsWithTotals items
    final chunks = <List<InvoiceItem>>[];
    chunks.add(items.sublist(0, itemsPerPage));

    var i = itemsPerPage;
    while (i < n) {
      final remaining = n - i;
      if (remaining <= maxItemsWithTotals) {
        chunks.add(items.sublist(i, n));
        break;
      }
      // Take a full page of itemsPerPage, ensuring enough left for last page
      final take = (remaining - maxItemsWithTotals).clamp(1, itemsPerPage);
      chunks.add(items.sublist(i, i + take));
      i += take;
    }

    return chunks;
  }

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

  String get documentTypeLabel => invoice.isEstimate ? 'ESTIMATE' : 'INVOICE';

  bool get isEstimate => invoice.isEstimate;

  bool get hasTermsCondition => invoice.selectedTermsCondition != null;

  String get termsConditionTitle => invoice.selectedTermsCondition?.title ?? '';

  String get termsConditionDescription =>
      invoice.selectedTermsCondition?.description ?? '';

  String? get customNotes =>
      invoice.customNotes.isNotEmpty ? invoice.customNotes : null;

  double get receivedAmount => invoice.receivedAmount;

  double get balanceDue => invoice.balanceDue;

  double get taxAmount => 0;
  double get grandTotalAmount => subtotalAmount + taxAmount;

  // Resolved inside build() and passed to sub-builders via BuildContext
  static CompanyProfileController companyOf(BuildContext context) =>
      context.read<CompanyProfileController>();

  /// Renders the company signature image if set, otherwise an empty space.
  /// Height is fixed so the footer layout stays consistent across templates.
  Widget buildSignature(BuildContext context) {
    final sigPath = companyOf(context).signaturePath;
    if (sigPath == null) {
      return const SizedBox(height: 50);
    }
    return SizedBox(
      height: 60,
      child: Align(
        alignment: Alignment.centerRight,
        child: Image.file(File(sigPath), height: 60, fit: BoxFit.contain),
      ),
    );
  }

  String formatMoney(num value) => _moneyFormat.format(value);

  String formatQuantity(num value) {
    final asDouble = value.toDouble();
    if (asDouble == asDouble.roundToDouble()) {
      return asDouble.toStringAsFixed(0);
    }
    return asDouble.toStringAsFixed(2);
  }

  Widget _buildPage(BuildContext context, int pageIndex) {
    final chunks = pageItemChunks;
    final pageItems = chunks[pageIndex];
    final startIndex = chunks.take(pageIndex).fold<int>(0, (s, c) => s + c.length);
    final isLastPage = pageIndex == chunks.length - 1;
    // Total row belongs on the last page that actually has items,
    // not on an empty trailing totals-only page.
    final hasItemsAfter = pageIndex + 1 < chunks.length && chunks[pageIndex + 1].isNotEmpty;
    final isLastItemsPage = isLastPage || !hasItemsAfter;

    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF1A1A1A), fontFamily: ''),
      child: IconTheme(
        data: const IconThemeData(color: Color(0xFF1A1A1A)),
        child: Container(
          width: 794,
          height: 1123,
          decoration: const BoxDecoration(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(context),
              const SizedBox(height: 20),
              if (pageIndex == 0) ...[
                buildInvoiceInfo(context),
                const SizedBox(height: 15),
              ],
              if (!isLastPage)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    clipBehavior: Clip.hardEdge,
                    child: buildItems(context,
                        pageItems: pageItems,
                        startIndex: startIndex,
                        isLastPage: isLastItemsPage,
                        isFinalPage: isLastPage),
                  ),
                )
              else
                SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  child: buildItems(context,
                      pageItems: pageItems,
                      startIndex: startIndex,
                      isLastPage: isLastItemsPage,
                      isFinalPage: isLastPage),
                ),
              if (isLastPage) ...[
                const Divider(thickness: 1, color: Colors.black26),
                const SizedBox(height: 10),
                buildTotals(context),
                const SizedBox(height: 30),
                buildFooter(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> buildPages(BuildContext context) {
    return List.generate(pageItemChunks.length, (i) => _buildPage(context, i));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: buildPages(context),
      ),
    );
  }
}
