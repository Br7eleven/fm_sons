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
          ),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              Icon(Icons.email, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'fmsons514@gmail.com',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
              SizedBox(width: 20),
              Icon(Icons.location_on, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'PHQ Hospital Road modern gilas aluminium decoration centre',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // Dark Banner (With Line Box)
        Container(
          width: double.infinity,
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
          padding: const EdgeInsets.only(left: 20, top: 12),
          child: const Text(
            'Fm sons Government Contractor General\nOrder Supplier Vendor Number 30140988',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.customerName ?? '-',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 8),
              _metaRow('Invoice No.:', invoice.invoiceNumber),
              _metaRow(
                'Date:',
                invoice.invoiceDate.toString().split(' ').first,
              ),
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
              _cell('#', flex: 1, isHeader: true),
              _cell('Item Name', flex: 5, isHeader: true),
              _cell('Quantity', flex: 2, isHeader: true),
              _cell('Unit', flex: 2, isHeader: true),
              _cell('Price/ Unit', flex: 3, isHeader: true),
              _cell('Amount', flex: 3, isHeader: true),
            ],
          ),
        ),
        // Rows with Borders
        ...invoice.items.asMap().entries.map((e) => _itemRow(e.key, e.value)),
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
                  'Rs ${invoice.totalAmount}',
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
      ],
    );
  }

  Widget _itemRow(int index, item) {
    return Row(
      children: [
        Container(
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
              _cell(item.name, flex: 5, align: TextAlign.left),
              _cell('${item.quantity}', flex: 2),
              _cell(item.unit, flex: 2),
              _cell('Rs ${item.rate}', flex: 3, align: TextAlign.right),
              _cell(
                'Rs ${item.total}',
                flex: 3,
                align: TextAlign.right,
                isBold: true,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 260,
          child: Table(
            border: TableBorder.all(color: Colors.black, width: 1),
            children: [
              _totalTableRow('Sub Total', 'Rs ${invoice.totalAmount}'),
              _totalTableRow('Total', 'Rs ${invoice.totalAmount}', isRed: true),
              _totalTableRow('Received', 'Rs 0.00'),
              _totalTableRow('Balance', 'Rs ${invoice.totalAmount}'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildTotals(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invoice Amount In Words',
                style: TextStyle(
                  color: brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.amountInWords.isEmpty
                    ? "Zero Rupees only"
                    : invoice.amountInWords,
                style: const TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Terms And Conditions',
                style: TextStyle(
                  color: brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const Text(
                '1. Goods once sold will not be returned.',
                style: TextStyle(fontSize: 10),
              ),
              const Text(
                '2. Thank you for doing business with us.',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),

        // Summary Table with Full Borders and Red Highlights
      ],
    );
  }

  @override
  Widget buildFooter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.black, thickness: 1),
        const Text(
          'For: Fm sons Government Contractor General Order Supplier Vendor Number 30140988',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 50), // Gap for signature
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
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
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
