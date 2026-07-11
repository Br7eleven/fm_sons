import 'package:flutter/material.dart';
import 'invoice_template_base.dart';

class TemplateTax1 extends InvoiceTemplate {
  const TemplateTax1({super.key, required super.invoice});

  // Colors based on your brand design
  static const Color brandRed = Color(0xFFE31E24);
  static const Color brandDark = Color(0xFF232B2E);

  @override
  Widget buildHeader(BuildContext context) {
    return Column(
      children: [
        // Top Red Bar with Contact Info (Border included)
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: brandRed,
            border: Border.all(color: Colors.black, width: 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.email, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                ' | ${InvoiceTemplate.companyOf(context).email}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.location_on, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '| ${InvoiceTemplate.companyOf(context).address}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Dark Banner (With Line Box)
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 470,
              height: 70,
              decoration: BoxDecoration(
                color: brandDark,
                border: const Border(
                  left: BorderSide(color: Colors.black),
                  right: BorderSide(color: Colors.black),
                  bottom: BorderSide(color: Colors.black),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(60),
                ),
              ),
              padding: const EdgeInsets.only(left: 20, top: 10, right: 16),
              child: Text(
                '${InvoiceTemplate.companyOf(context).name} ${InvoiceTemplate.companyOf(context).tagline}\nVendor Number ${InvoiceTemplate.companyOf(context).vendorNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill To',
                style: TextStyle(
                  color: brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                customerDisplayName,
                style: const TextStyle(
                  fontSize: 14,
                  // fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                documentTypeLabel[0] +
                    documentTypeLabel.substring(1).toLowerCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _metaRow(
                '${documentTypeLabel[0]}${documentTypeLabel.substring(1).toLowerCase()} No.:',
                invoice.invoiceNumber,
              ),
              _metaRow('Date:', invoiceDateLabel),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget buildItems(BuildContext context) {
    return Column(
      children: [
        // Table Header with Border + Color
        Container(
          decoration: BoxDecoration(
            color: brandRed,
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              _cell('#', flex: 1, isHeader: true, align: TextAlign.center),
              _cell(
                'Item Name',
                flex: 5,
                isHeader: true,
                align: TextAlign.left,
              ),
              _cell(
                'Quantity',
                flex: 2,
                isHeader: true,
                align: TextAlign.center,
              ),
              _cell('Unit', flex: 2, isHeader: true, align: TextAlign.center),
              _cell('Price', flex: 3, isHeader: true, align: TextAlign.right),
              _cell('Amount', flex: 3, isHeader: true, align: TextAlign.right),
            ],
          ),
        ),
        // Rows with Borders
        ...previewItems.asMap().entries.map((e) => _itemRow(e.key, e.value)),
        if (hiddenItemsCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '+$hiddenItemsCount more item(s) not shown in preview',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        // Total Row with Border + Color
        Container(
          decoration: BoxDecoration(
            color: brandRed,
            border: Border.all(color: Colors.black, width: 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const Expanded(
                flex: 6,
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${invoice.items.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(flex: 5),
              Expanded(
                flex: 3,
                child: Text(
                  formatMoney(grandTotalAmount),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Summary Table with Full Borders and Red Highlights
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 260,
              child: Table(
                border: TableBorder.all(color: Colors.black, width: .5),
                children: [
                  _totalTableRow('Sub Total', formatMoney(subtotalAmount)),
                  _totalTableRow('Tax', formatMoney(taxAmount)),
                  _totalTableRow(
                    'Total',
                    formatMoney(grandTotalAmount),
                    isRed: true,
                  ),
                  if (!isEstimate)
                    _totalTableRow('Received', formatMoney(receivedAmount)),
                  if (!isEstimate)
                    _totalTableRow('Balance', formatMoney(balanceDue)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemRow(int index, dynamic item) {
    return Container(
      decoration: BoxDecoration(
        border: const Border(
          left: BorderSide(color: Colors.black),
          right: BorderSide(color: Colors.black),
          bottom: BorderSide(color: Colors.black, width: 0.5),
        ),
        color: index % 2 != 0 ? Colors.grey[50] : Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          _cell('${index + 1}', flex: 1),
          _cell(
            item.name,
            flex: 5,
            align: TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          _cell(formatQuantity(item.quantity), flex: 2),
          _cell(
            item.unit,
            flex: 2,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          _cell(formatMoney(item.rate), flex: 3, align: TextAlign.right),
          _cell(
            formatMoney(item.total),
            flex: 3,
            align: TextAlign.right,
            isBold: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildTotals(BuildContext context) {
    final note = invoice.notes.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${documentTypeLabel[0]}${documentTypeLabel.substring(1).toLowerCase()} Amount In Words',
                style: const TextStyle(
                  color: brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                amountInWordsLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Text(
                'Note',
                style: TextStyle(
                  color: brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                note.isEmpty ? '-' : note,
                style: const TextStyle(fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 15),
              if (hasTermsCondition) ...[
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: brandRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  termsConditionDescription,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
              // const Text(
              //   'Terms And Conditions',
              //   style: TextStyle(
              //     color: brandRed,
              //     fontWeight: FontWeight.bold,
              //     fontSize: 11,
              //   ),
              // ),
              // const Text(
              //   '1. Goods once sold will not be returned.',
              //   style: TextStyle(fontSize: 10),
              // ),
              // const Text(
              //   '2. Thank you for doing business with us.',
              //   style: TextStyle(fontSize: 10),
              // ),
            ],
          ),
        ),
        // // Summary Table with Full Borders and Red Highlights
        // SizedBox(
        //   width: 260,
        //   child: Table(
        //     border: TableBorder.all(color: Colors.black, width: 1),
        //     children: [
        //       _totalTableRow('Sub Total', 'Rs ${invoice.totalAmount}'),
        //       _totalTableRow('Total', 'Rs ${invoice.totalAmount}', isRed: true),
        //       _totalTableRow('Received', 'Rs 0.00'),
        //       _totalTableRow('Balance', 'Rs ${invoice.totalAmount}'),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.black, thickness: 1),
        Text(
          'For: ${InvoiceTemplate.companyOf(context).name} ${InvoiceTemplate.companyOf(context).tagline} Vendor Number ${InvoiceTemplate.companyOf(context).vendorNumber}',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
        buildSignature(context),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              children: [
                Container(width: 160, height: 1.5, color: Colors.black),
                const SizedBox(height: 4),
                const Text(
                  'Authorized Signatory',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // --- Static Helpers ---
  static Widget _cell(
    String text, {
    required int flex,
    bool isHeader = false,
    TextAlign align = TextAlign.center,
    bool isBold = false,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          color: isHeader ? Colors.white : Colors.black,
          fontWeight: (isHeader || isBold)
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  TableRow _totalTableRow(String label, String value, {bool isRed = false}) {
    return TableRow(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: isRed ? brandRed : Colors.white,
          child: Text(
            label,
            style: TextStyle(
              color: isRed ? Colors.white : Colors.black,
              fontWeight: isRed ? FontWeight.bold : FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8.0),
          color: isRed ? brandRed : Colors.white,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isRed ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(width: 15),
          Text(value, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
