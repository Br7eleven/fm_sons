import 'package:flutter/material.dart';
import 'invoice_template_base.dart';

class TemplateBlue extends InvoiceTemplate {
  const TemplateBlue({super.key, required super.invoice});

  /* -------------------------------------------------------------------------- */
  /*                                   HEADER                                   */
  /* -------------------------------------------------------------------------- */

  @override
  Widget buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company Name in Blue
        const Text(
          '<Company Name>',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0), // Blue
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '<123 Street Address, City, State, Zip/Post>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        const Text(
          '<Website, Email Address>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 2),
        const Text(
          '<Phone Number>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Bill to and Ship to + Dates
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
                    const Text('<Contact Name>', style: TextStyle(fontSize: 10)),
                    Text(
                      customerDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text('<Address>', style: TextStyle(fontSize: 10)),
                    const Text('<Phone, Email>', style: TextStyle(fontSize: 10)),
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
                    const Text('<Name / Dept>', style: TextStyle(fontSize: 10)),
                    Text(
                      customerDisplayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text('<Address>', style: TextStyle(fontSize: 10)),
                    const Text('<Phone>', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              // Dates
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _dateRow('Estimate Date:', invoiceDateLabel),
                  const SizedBox(height: 8),
                  _dateRow('Valid For:', '14 days'),
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
  Widget buildItems(BuildContext context) {
    return Column(
      children: [
        // Blue header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          color: const Color(0xFF1976D2), // Blue
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
                  _totalRow('DISCOUNT', formatMoney(0)),
                  _totalRow('SUBTOTAL LESS DISCOUNT', formatMoney(subtotalAmount)),
                  _totalRow('TAX RATE', '0.00%'),
                  _totalRow('TOTAL TAX', formatMoney(0)),
                  _totalRow('SHIPPING/ HANDLING', formatMoney(0)),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Terms & Instructions
        const Text(
          'Terms & Instructions',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          width: 120,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(height: 8),
        const Text(
          '<Add payment requirements here, for example deposit amount and payment method>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const Text(
          '<Add terms here, e.g: warranty, returns policy...>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        const Text(
          '<Include project timeline>',
          style: TextStyle(fontSize: 10, color: Colors.black87),
        ),
      ],
    );
  }

  /* -------------------------------------------------------------------------- */
  /*                                HELPERS                                     */
  /* -------------------------------------------------------------------------- */

  Widget _dateRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 10),
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
