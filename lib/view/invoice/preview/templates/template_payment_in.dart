import 'package:flutter/material.dart';
import '../../../../utils/constants/color_string.dart';
import 'invoice_template_base.dart';
import '../../controller/create_invoice_controller.dart';

/// Payment-In receipt template.
/// Extends InvoiceTemplate to reuse full company header, A4 proportions,
/// PDF generation pipeline, and signature handling.
class TemplatePaymentIn extends InvoiceTemplate {
  const TemplatePaymentIn({super.key, required super.invoice});

  @override
  Widget buildHeader(BuildContext context) {
    final company = InvoiceTemplate.companyOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company header block
        Text(
          company.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: FMSons.accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          company.tagline,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text(
          company.email,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text(
          company.address,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        Text(
          'Vendor No: ${company.vendorNumber}',
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),

        const SizedBox(height: 12),

        // ── Divider above title ──
        Container(height: 1, color: Colors.grey.shade400),

        // ── Payment-In centered title ──
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Payment-In',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: FMSons.accent,
              ),
            ),
          ),
        ),

        // ── Divider below title ──
        Container(height: 1, color: Colors.grey.shade400),
      ],
    );
  }

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Received From
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Received From',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  customerDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right: Receipt Details aligned to right edge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Receipt Details',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              _detailRow('Receipt No.', invoice.invoiceNumber),
              const SizedBox(height: 4),
              _detailRow('Date', invoiceDateLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget buildItems(BuildContext context, {required List<InvoiceItem> pageItems, required int startIndex, required bool isLastPage, required bool isFinalPage}) {
    // Amount section — rendered inside Expanded area, close to invoice info
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Amount In Words
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount In Words',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                amountInWordsLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right: Received amount aligned to right edge
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Received',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(invoice.totalAmount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildTotals(BuildContext context) {
    // For: + Signature block — sits below the divider, at bottom of page
    final company = InvoiceTemplate.companyOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              company.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildSignature(context),
            const SizedBox(height: 4),
            const Text(
              'Authorized Signatory',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context) {
    return const SizedBox.shrink();
  }
}
