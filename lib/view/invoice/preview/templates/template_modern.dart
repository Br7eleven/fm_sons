import 'package:flutter/material.dart';

import 'invoice_template_base.dart';

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
        color: Color(0xFF1E5EFF), // brand accent
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
  Widget buildItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          /// Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Description')),
                Expanded(child: Text('Qty')),
                Expanded(child: Text('Unit')),
                Expanded(child: Text('Rate')),
                Expanded(child: Text('Amount', textAlign: TextAlign.right)),
              ],
            ),
          ),

          /// Items
          ...previewItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(child: Text(formatQuantity(item.quantity))),
                  Expanded(
                    child: Text(
                      item.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(child: Text(formatMoney(item.rate))),
                  Expanded(
                    child: Text(
                      formatMoney(item.total),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hiddenItemsCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '+$hiddenItemsCount more item(s) not shown in preview',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
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
            Text(
              termsConditionTitle,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(termsConditionDescription,
                style: const TextStyle(fontSize: 12)),
          ],
          if (customNotes != null) ...[
            const SizedBox(height: 8),
            const Text('Notes',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(customNotes!, style: const TextStyle(fontSize: 12)),
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
