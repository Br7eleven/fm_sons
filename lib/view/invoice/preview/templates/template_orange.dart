import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'invoice_template_base.dart';

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
          color: const Color(0xFFFF5722), // Orange
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
              children: const [
                Text(
                  '<Your Company>',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text('<Your address>', style: TextStyle(fontSize: 11)),
                Text('<Your contact>', style: TextStyle(fontSize: 11)),
                Text('details', style: TextStyle(fontSize: 11)),
              ],
            ),
            // ESTIMATE title
            const Text(
              'ESTIMATE',
              style: TextStyle(
                fontSize: 28,
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
      child: Column(
        children: [
          // Date and Estimate No
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _infoRow('DATE', invoiceDateLabel),
                  const SizedBox(height: 8),
                  _infoRow('ESTIMATE NO.', invoice.invoiceNumber),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bill to and Ship to
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: 120,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '<Contact Name>',
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      customerDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text('<Address>', style: TextStyle(fontSize: 11)),
                    const Text('<Phone>', style: TextStyle(fontSize: 11)),
                    const Text('<Email>', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              // Ship To
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHIP TO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      width: 120,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 8),
                    const Text('<Name / Dept>', style: TextStyle(fontSize: 11)),
                    Text(
                      customerDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text('<Address>', style: TextStyle(fontSize: 11)),
                    const Text('<Phone>', style: TextStyle(fontSize: 11)),
                  ],
                ),
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
  Widget buildItems(BuildContext context) {
    return Column(
      children: [
        // Orange header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: const Color(0xFFFF5722),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'DESCRIPTION',
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
        ...previewItems.map(
          (item) => Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    formatQuantity(item.quantity),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    formatMoney(item.rate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Text(
                    formatMoney(item.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11),
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
                '+$hiddenItemsCount more item(s) not shown',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
            // Left: Note
            const Expanded(
              flex: 2,
              child: Text(
                'Remarks, notes on how long the estimate is valid, project duration estimates.',
                style: TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 24),
            // Right: Totals
            Expanded(
              child: Column(
                children: [
                  _totalRow('SUBTOTAL', formatMoney(subtotalAmount)),
                  _totalRow('DISCOUNT', formatMoney(0)),
                  _totalRow('SUBTOTAL LESS DISCOUNT', formatMoney(subtotalAmount)),
                  _totalRow('TAX RATE', '0.00%'),
                  _totalRow('TOTAL TAX', formatMoney(0)),
                  _totalRow('SHIPPING/HANDLING', formatMoney(0)),
                  const Divider(thickness: 2, color: Colors.black),
                  _totalRow(
                    'Quote Total',
                    '\$ ${formatMoney(grandTotalAmount)}',
                    isBold: true,
                  ),
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
        const SizedBox(height: 16),
        // Orange bottom bar
        Container(
          width: double.infinity,
          height: 20,
          color: const Color(0xFFFF5722),
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
          child: Text(
            value,
            style: const TextStyle(fontSize: 10),
          ),
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
