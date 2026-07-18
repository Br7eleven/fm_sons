import 'package:flutter/material.dart';
// import 'package:pdf/pdf.dart';
import 'invoice_template_base.dart';
import '../../controller/create_invoice_controller.dart';

class TemplateOrange extends InvoiceTemplate {
  const TemplateOrange({super.key, required super.invoice});

  /* -------------------------------------------------------------------------- */
  /*                                   HEADER                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildHeader(BuildContext context) {
    return Column(
      children: [
        // Orange top bar
        Container(
          width: double.infinity,
          height: 20,
          color: const Color(0xFF1A7A1A), // Orange
        ),
        const SizedBox(height: 24),
        // Company info and ESTIMATE title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  InvoiceTemplate.companyOf(context).name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  InvoiceTemplate.companyOf(context).email,
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  InvoiceTemplate.companyOf(context).address,
                  style: const TextStyle(fontSize: 11),
                ),
                Text(
                  'Vendor No: ${InvoiceTemplate.companyOf(context).vendorNumber}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            // Document type title
            Text(
              documentTypeLabel,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                             INVOICE INFO                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Bill To
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BILL TO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A7A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  width: 120,
                  color: const Color(0xFF1A7A1A),
                ),
                const SizedBox(height: 8),
                Text(
                  customerDisplayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Right: Date and Invoice No
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _infoRow('DATE', invoiceDateLabel),
              const SizedBox(height: 8),
              _infoRow('$documentTypeLabel NO.', invoice.invoiceNumber),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 ITEMS                                      */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildItems(
    BuildContext context, {
    required List<InvoiceItem> pageItems,
    required int startIndex,
    required bool isLastPage,
    required bool isFinalPage,
  }) {
    final green = const Color(0xFF1A7A1A);
    return Column(
      children: [
        // Green header
        if (pageItems.isNotEmpty || invoice.items.isEmpty)
          Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: green,
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text('#', style: TextStyle(color: Colors.white)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'ITEM NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'QTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'UNIT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'UNIT PRICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'TOTAL',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Items
        ...pageItems.asMap().entries.map(
          (e) => Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${startIndex + e.key + 1}',
                    // textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    e.value.name,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    formatQuantity(e.value.quantity),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value.unit,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    formatMoney(e.value.rate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    formatMoney(e.value.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Total row (last page only)
        if (isLastPage && pageItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            color: green,
            child: Row(
              children: [
                const Expanded(
                  flex: 5,
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${invoice.items.length}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    formatMoney(grandTotalAmount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 TOTALS                                     */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildTotals(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Left note + Right totals
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Note and Terms
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Note',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.notes.trim().isEmpty ? '-' : invoice.notes.trim(),
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  if (hasTermsCondition) ...[
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      termsConditionDescription,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right: Totals
            Expanded(
              child: Column(
                children: [
                  _totalRow('SUBTOTAL', formatMoney(subtotalAmount)),
                  const Divider(thickness: 2, color: Colors.black),
                  _totalRow(
                    'TOTAL',
                    formatMoney(grandTotalAmount),
                    isBold: true,
                  ),
                  if (!isEstimate)
                    _totalRow('RECEIVED', formatMoney(receivedAmount)),
                  if (!isEstimate)
                    _totalRow('BALANCE', formatMoney(balanceDue)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  FOOTER                                    */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildFooter(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildSignature(context),
                Container(width: 160, height: 1.5, color: Colors.black),
                const SizedBox(height: 4),
                const Text(
                  'Authorized Signatory',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Orange bottom bar
        Container(
          width: double.infinity,
          height: 20,
          color: const Color(0xFF1A7A1A),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                HELPERS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
