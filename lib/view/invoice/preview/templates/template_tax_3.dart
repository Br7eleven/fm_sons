import 'package:flutter/material.dart';

import 'invoice_template_base.dart';
import '../../controller/create_invoice_controller.dart';

class TemplateTax3 extends InvoiceTemplate {
  const TemplateTax3({super.key, required super.invoice});

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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    InvoiceTemplate.companyOf(context).tagline,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Email: ${InvoiceTemplate.companyOf(context).email}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    InvoiceTemplate.companyOf(context).address,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Text(
                    'Vendor No: ${InvoiceTemplate.companyOf(context).vendorNumber}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                documentTypeLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8F8CD9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 2, color: const Color(0xFF8F8CD9)),
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
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Customer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill To',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  customerDisplayName,
                  style: const TextStyle(fontSize: 14),
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
              const Text(
                'Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              _meta('Invoice No', invoice.invoiceNumber),
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
    return Column(
      children: [
        if (pageItems.isNotEmpty || invoice.items.isEmpty) ...[
          const SizedBox(height: 8),
          /// Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8F8CD9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('#', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text('Item Name', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Text('Quantity', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Text('Unit', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Text('Price/Unit', style: TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text('Amount', textAlign: TextAlign.right,
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        /// Items
        ...pageItems.asMap().entries.map(
          (entry) => Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text('${startIndex + entry.key + 1}', style: const TextStyle(fontSize: 10)),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    entry.value.name,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(child: Text(formatQuantity(entry.value.quantity), style: const TextStyle(fontSize: 10))),
                Expanded(
                  child: Text(
                    entry.value.unit,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(child: Text(formatMoney(entry.value.rate), style: const TextStyle(fontSize: 10))),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      formatMoney(entry.value.total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 10),
                    ),
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
            color: const Color(0xFF8F8CD9),
            child: Row(
              children: [
                const Expanded(flex: 5, child: Text('Total',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                Expanded(
                  child: Text('${invoice.items.length}', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
                const Expanded(child: SizedBox()),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(formatMoney(grandTotalAmount), textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8F8CD9), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              _totalRow('Sub Total', subtotalAmount),
              _totalRow('Total', grandTotalAmount),
              if (!isEstimate) _totalRow('Received', receivedAmount),
              if (!isEstimate) _totalRow('Balance', balanceDue),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(note.isEmpty ? '-' : note, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          const Text(
            'Estimate Amount in Words',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(amountInWordsLabel, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 14),
          if (hasTermsCondition) ...[
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              termsConditionDescription,
              style: const TextStyle(fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'For: ${InvoiceTemplate.companyOf(context).name} ${InvoiceTemplate.companyOf(context).tagline} Vendor Number ${InvoiceTemplate.companyOf(context).vendorNumber}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  buildSignature(context),
                  const Text(
                    'Authorized Signatory',
                    style: TextStyle(fontSize: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _totalRow(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            formatMoney(value),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
