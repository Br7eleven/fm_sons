import 'package:flutter/material.dart';
import 'invoice_template_base.dart';
import '../../controller/create_invoice_controller.dart';

class TemplateBlue extends InvoiceTemplate {
  const TemplateBlue({super.key, required super.invoice});

  /* -------------------------------------------------------------------------- */
  /*                                   HEADER                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    InvoiceTemplate.companyOf(context).name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    InvoiceTemplate.companyOf(context).tagline,
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    InvoiceTemplate.companyOf(context).email,
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    InvoiceTemplate.companyOf(context).address,
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vendor No: ${InvoiceTemplate.companyOf(context).vendorNumber}',
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ],
              ),
              Text(
                documentTypeLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                             INVOICE INFO                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Bill To + Dates
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill To
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BILL TO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 1,
                      width: 80,
                      color: const Color(0xFF1565C0),
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
              // Dates
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _meta('Invoice No', invoice.invoiceNumber),
                  _meta('Date', invoiceDateLabel),
                ],
              ),
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
    final blue = const Color(0xFF1976D2);
    return Column(
      children: [
        // Blue header
        if (pageItems.isNotEmpty || invoice.items.isEmpty || startIndex > 0)
          Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: blue,
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
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
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
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
            color: blue,
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
            // Left: Thank you message
            const Expanded(
              flex: 2,
              child: Text(
                'Thank you for your business!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
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
    final note = invoice.notes.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Amount in Words
        Text(
          '${documentTypeLabel[0]}${documentTypeLabel.substring(1).toLowerCase()} Amount in Words',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amountInWordsLabel,
          style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
        // Note
        const Text(
          'Note',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          note.isEmpty ? '-' : note,
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        // Terms & Conditions
        if (hasTermsCondition) ...[
          const SizedBox(height: 4),
          const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            termsConditionDescription,
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'For: ${InvoiceTemplate.companyOf(context).name} ${InvoiceTemplate.companyOf(context).tagline} Vendor Number ${InvoiceTemplate.companyOf(context).vendorNumber}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                buildSignature(context),
                Container(width: 160, height: 1.5, color: Colors.black),
                const SizedBox(height: 4),
                const Text(
                  'Authorized Signatory',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                HELPERS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _meta(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  // Widget _dateRow(String label, String value) {
  //   return Row(
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
  //       ),
  //       const SizedBox(width: 6),
  //       Text(value, style: const TextStyle(fontSize: 10)),
  //     ],
  //   );
  // }

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
