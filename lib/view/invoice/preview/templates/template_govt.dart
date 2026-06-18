import 'dart:io';

import 'package:flutter/material.dart';

import 'invoice_template_base.dart';

class TemplateGovt extends InvoiceTemplate {
  const TemplateGovt({super.key, required super.invoice});

  // Override base build() to avoid Expanded gap — items grow naturally,
  // the outer fixed-height container clips any extreme overflow.
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF1A1A1A), fontFamily: ''),
      child: IconTheme(
        data: const IconThemeData(color: Color(0xFF1A1A1A)),
        child: Container(
          width: 794,
          height: 1123,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildHeader(context),
              const SizedBox(height: 20),
              buildInvoiceInfo(context),
              const SizedBox(height: 15),
              buildItems(context),
              const SizedBox(height: 16),
              buildTotals(context),
              const SizedBox(height: 20),
              buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  static const Color _green = Color(0xFF1A7A1A);
  static const Color _borderGrey = Color(0xFFCCCCCC);

  // ── Header ──────────────────────────────────────────────────────────────────

  @override
  Widget buildHeader(BuildContext context) {
    final co = InvoiceTemplate.companyOf(context);
    return Container(
      width: double.infinity,
      color: _green,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Text(
            '${co.name} ${co.tagline} Vendor Number',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            co.vendorNumber,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Address: ${co.address}    Email: ${co.email}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Invoice Info ─────────────────────────────────────────────────────────────

  @override
  Widget buildInvoiceInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centered document type title
        Center(
          child: Text(
            documentTypeLabel[0] + documentTypeLabel.substring(1).toLowerCase(),
            style: const TextStyle(
              color: _green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Single green header bar: "Bill To" left, "Invoice Details" right
        Container(
          color: _green,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bill To',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const Text(
                'Invoice Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        // Data row: customer name left, invoice no + date right
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  customerDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Invoice No.: ${invoice.invoiceNumber}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  Text(
                    'Date: $invoiceDateLabel',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Items ────────────────────────────────────────────────────────────────────

  @override
  Widget buildItems(BuildContext context) {
    return Table(
      border: TableBorder.all(color: _borderGrey),
      columnWidths: const {
        0: FixedColumnWidth(30),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(70),
        3: FixedColumnWidth(70),
        4: FixedColumnWidth(80),
        5: FixedColumnWidth(90),
      },
      children: [
        _tableHeader(),
        ...previewItems.asMap().entries.map(
          (e) => _tableRow(e.key + 1, e.value),
        ),
        _tableTotalRow(),
        if (hiddenItemsCount > 0) _hiddenItemsRow(),
      ],
    );
  }

  TableRow _tableHeader() {
    const headers = [
      '#',
      'Item Name',
      'Quantity',
      'Unit',
      'Price/Unit',
      'Amount',
    ];
    return TableRow(
      decoration: const BoxDecoration(color: _green),
      children: headers
          .map(
            (h) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              child: Text(
                h,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _tableRow(int index, dynamic item) {
    return TableRow(
      children: [
        _cell('$index'),
        _cell(item.name, bold: true),
        _cell(formatQuantity(item.quantity), align: TextAlign.right),
        _cell(item.unit, align: TextAlign.right),
        _cell(formatMoney(item.rate), align: TextAlign.right),
        _cell(formatMoney(item.total), align: TextAlign.right),
      ],
    );
  }

  TableRow _tableTotalRow() {
    final totalQty = previewItems.fold<num>(0, (s, i) => s + i.quantity);
    return TableRow(
      children: [
        _cell(''),
        _cell('Total', bold: true),
        _cell(formatQuantity(totalQty), bold: true, align: TextAlign.right),
        _cell(''),
        _cell(''),
        _cell(
          formatMoney(grandTotalAmount),
          bold: true,
          align: TextAlign.right,
        ),
      ],
    );
  }

  TableRow _hiddenItemsRow() {
    return TableRow(
      children: [
        const SizedBox(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Text(
            '+$hiddenItemsCount more item(s) not shown',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(),
        const SizedBox(),
        const SizedBox(),
        const SizedBox(),
      ],
    );
  }

  Widget _cell(
    String text, {
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // ── Totals ───────────────────────────────────────────────────────────────────

  @override
  Widget buildTotals(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Amount in words + Terms
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _greenLabel('Invoice Amount In Words:'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: _borderGrey),
                ),
                child: Text(
                  amountInWordsLabel,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              _greenLabel('Terms and Conditions'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: _borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTermsCondition) ...[
                      Text(
                        termsConditionTitle,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(termsConditionDescription,
                          style: const TextStyle(fontSize: 11)),
                      if (customNotes != null) ...[
                        const SizedBox(height: 8),
                        const Text('Notes',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(customNotes!,
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ] else ...[
                      Text(
                        invoice.notes.trim().isEmpty
                            ? 'Thank you for doing business with us.'
                            : invoice.notes.trim(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right: Amounts summary
        SizedBox(
          width: 220,
          child: Column(
            children: [
              _greenLabel('Amounts'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _borderGrey),
                ),
                child: Column(
                  children: [
                    _amountRow('Sub Total', subtotalAmount),
                    _amountRow('Total', grandTotalAmount, bold: true),
                    if (!isEstimate) _amountRow('Received', receivedAmount),
                    if (!isEstimate) _amountRow('Balance', balanceDue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _greenLabel(String text) {
    return Container(
      width: double.infinity,
      color: _green,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _amountRow(String label, double value, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderGrey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatMoney(value),
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer / Signature ───────────────────────────────────────────────────────

  @override
  Widget buildFooter(BuildContext context) {
    final co = InvoiceTemplate.companyOf(context);
    final sigPath = co.signaturePath;

    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'For, ${co.name} ${co.tagline} Vendor Number ${co.vendorNumber}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
            const SizedBox(height: 8),
            if (sigPath != null)
              Image.file(File(sigPath), height: 50, fit: BoxFit.contain)
            else
              const SizedBox(height: 50),
            Container(height: 1, color: Colors.black),
            const SizedBox(height: 4),
            const Text('Authorized Signatory', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
