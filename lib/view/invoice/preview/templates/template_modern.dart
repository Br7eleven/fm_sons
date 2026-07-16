import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

import 'invoice_template_base.dart';
import '../../controller/create_invoice_controller.dart';

class TemplateModern extends InvoiceTemplate {
  const TemplateModern({super.key, required super.invoice});

  /* -------------------------------------------------------------------------- */
  /*                                   HEADER                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: FMSons.accent, // brand accent
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            InvoiceTemplate.companyOf(context).name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            InvoiceTemplate.companyOf(context).tagline,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          /// Customer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Billed To',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  customerDisplayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          /// Meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _meta('Invoice', invoice.invoiceNumber),
              _meta('Date', invoiceDateLabel),
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
  Widget buildItems(BuildContext context, {required List<InvoiceItem> pageItems, required int startIndex, required bool isLastPage, required bool isFinalPage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          /// Header
          if (pageItems.isNotEmpty)
            Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Description', style: TextStyle(fontSize: 10))),
                Expanded(child: Text('Qty', style: TextStyle(fontSize: 10))),
                Expanded(child: Text('Unit', style: TextStyle(fontSize: 10))),
                Expanded(child: Text('Rate', style: TextStyle(fontSize: 10))),
                Expanded(child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 10))),
              ],
            ),
          ),

          /// Items
          ...pageItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(child: Text(formatQuantity(item.quantity), style: const TextStyle(fontSize: 10))),
                  Expanded(
                    child: Text(
                      item.unit,
                      style: const TextStyle(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(child: Text(formatMoney(item.rate), style: const TextStyle(fontSize: 10))),
                  Expanded(
                    child: Text(
                      formatMoney(item.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                 TOTALS                                     */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildTotals(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      formatMoney(grandTotalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!isEstimate) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Received: ${formatMoney(receivedAmount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'Balance: ${formatMoney(balanceDue)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                  FOOTER                                    */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildFooter(BuildContext context) {
    final note = invoice.notes.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Note',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            note.isEmpty ? '-' : note,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Amount In Words: $amountInWordsLabel',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasTermsCondition) ...[
            const SizedBox(height: 8),
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(termsConditionDescription,
                style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 4),
          const Text(
            'Thank you for your business!',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildSignature(context),
                  Container(width: 160, height: 1, color: Colors.black54),
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
      ),
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                HELPERS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _meta(String label, String value) {
    return Text('$label: $value', style: const TextStyle(fontSize: 12));
  }
}
