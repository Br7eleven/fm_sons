import 'package:flutter/material.dart';

void main() {
  runApp(const AbbasInvoiceApp());
}

class AbbasInvoiceApp extends StatelessWidget {
  const AbbasInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABBAS Invoice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Serif'),
      home: const InvoicePage(),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────────────────

class InvoiceItem {
  final int sNo;
  final String description;
  final String unit;
  final double qty;
  final double unitPrice;

  const InvoiceItem({
    required this.sNo,
    required this.description,
    required this.unit,
    required this.qty,
    required this.unitPrice,
  });

  double get total => qty * unitPrice;
}

class InvoiceData {
  final String ref;
  final String date;
  final String toName;
  final String toAddress;
  final String subject;
  final List<InvoiceItem> items;
  final double taxPercent;
  final String termsAndConditions;

  const InvoiceData({
    required this.ref,
    required this.date,
    required this.toName,
    required this.toAddress,
    required this.subject,
    required this.items,
    this.taxPercent = 0,
    this.termsAndConditions = '',
  });

  double get subtotal => items.fold(0, (s, i) => s + i.total);
  double get taxAmount => subtotal * (taxPercent / 100);
  double get grandTotal => subtotal + taxAmount;
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

final sampleInvoice = InvoiceData(
  ref: 'GC-2025-001',
  date: '09-May-2025',
  toName: 'Gilgit-Baltistan Works Department',
  toAddress: 'Gilgit, Gilgit-Baltistan',
  subject: 'Supply of General Construction Materials',
  items: const [
    InvoiceItem(
      sNo: 1,
      description: 'Cement (OPC 43 Grade)',
      unit: 'Bags',
      qty: 200,
      unitPrice: 1200,
    ),
    InvoiceItem(
      sNo: 2,
      description: 'Steel Rebar 12mm (TMT)',
      unit: 'Kg',
      qty: 500,
      unitPrice: 280,
    ),
    InvoiceItem(
      sNo: 3,
      description: 'Coarse Aggregate (3/4")',
      unit: 'CFT',
      qty: 150,
      unitPrice: 120,
    ),
    InvoiceItem(
      sNo: 4,
      description: 'Fine Sand (River)',
      unit: 'CFT',
      qty: 100,
      unitPrice: 80,
    ),
    InvoiceItem(
      sNo: 5,
      description: 'Transportation & Labour Charges',
      unit: 'LS',
      qty: 1,
      unitPrice: 15000,
    ),
  ],
  taxPercent: 5,
  termsAndConditions:
      '1. Payment due within 30 days of invoice.\n'
      '2. All goods remain property of ABBAS until full payment received.\n'
      '3. Disputes subject to Gilgit jurisdiction.',
);

// ─── Main Page ────────────────────────────────────────────────────────────────

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD0D0D0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          'ABBAS Invoice Preview',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: 'Print / Export PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connect a PDF/print plugin to export.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: AbbasInvoiceWidget(data: sampleInvoice),
        ),
      ),
    );
  }
}

// ─── Invoice Widget (A4 / Legal proportions) ──────────────────────────────────

class AbbasInvoiceWidget extends StatelessWidget {
  final InvoiceData data;

  const AbbasInvoiceWidget({super.key, required this.data});

  // A4: 210 × 297 mm  →  at 3.78 px/mm ≈  794 × 1123 px
  // Legal: 216 × 356 mm →  at 3.78 px/mm ≈  816 × 1344 px
  static const double _pageWidth = 794;

  static const Color _navyBlue = Color(0xFF1A237E);
  static const Color _bodyText = Color(0xFF212121);
  static const Color _lightGrey = Color(0xFFF5F5F5);
  static const Color _borderGrey = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _pageWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildRefDateRow(),
          _buildToBlock(),
          _buildSubjectLine(),
          const SizedBox(height: 16),
          _buildItemsTable(),
          const SizedBox(height: 12),
          _buildTotalsBlock(),
          const SizedBox(height: 24),
          if (data.termsAndConditions.isNotEmpty) _buildTerms(),
          const SizedBox(height: 40),
          _buildSignatureRow(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _navyBlue, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Name block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ABBAS styled text logo
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ABBAS',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: _navyBlue,
                          letterSpacing: 6,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Address: Khomer Chowk Gilgit',
                  style: TextStyle(
                    fontSize: 11,
                    color: _bodyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Right block: business type + phone
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Government Contractor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _bodyText,
                ),
              ),
              const Text(
                '& General Order Supplier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _bodyText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cell No. 0312-4115209',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _bodyText,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _navyBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'INVOICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ref / Date row ────────────────────────────────────────────────────────

  Widget _buildRefDateRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: _lightGrey,
        border: const Border(bottom: BorderSide(color: _borderGrey)),
      ),
      child: Row(
        children: [
          _labelValue('Ref No:', data.ref),
          const Spacer(),
          _labelValue('Date:', data.date),
        ],
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _bodyText,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _navyBlue),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: _bodyText),
          ),
        ),
      ],
    );
  }

  // ── To Block ─────────────────────────────────────────────────────────────

  Widget _buildToBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To,',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _bodyText,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.toName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navyBlue,
                ),
              ),
              Text(
                data.toAddress,
                style: const TextStyle(fontSize: 12, color: _bodyText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Subject ───────────────────────────────────────────────────────────────

  Widget _buildSubjectLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _bodyText,
            ),
          ),
          Expanded(
            child: Text(
              data.subject,
              style: const TextStyle(
                fontSize: 12,
                color: _bodyText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Items Table ───────────────────────────────────────────────────────────

  Widget _buildItemsTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Table(
        border: TableBorder.all(color: _navyBlue, width: 0.8),
        columnWidths: const {
          0: FixedColumnWidth(40), // S.No
          1: FlexColumnWidth(4), // Description
          2: FixedColumnWidth(56), // Unit
          3: FixedColumnWidth(60), // Qty
          4: FixedColumnWidth(90), // Unit Price
          5: FixedColumnWidth(90), // Total
        },
        children: [_tableHeader(), ...data.items.map(_tableRow)],
      ),
    );
  }

  TableRow _tableHeader() {
    const headers = [
      'S.No',
      'Description',
      'Unit',
      'Qty',
      'Unit Price (Rs)',
      'Total (Rs)',
    ];
    return TableRow(
      decoration: const BoxDecoration(color: _navyBlue),
      children: headers.map((h) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          child: Text(
            h,
            textAlign: h == 'Description' ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  TableRow _tableRow(InvoiceItem item) {
    final isEven = item.sNo % 2 == 0;
    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFEEF0FB) : Colors.white,
      ),
      children: [
        _cell(item.sNo.toString(), center: true),
        _cell(item.description),
        _cell(item.unit, center: true),
        _cell(_fmt(item.qty, decimals: 0), center: true),
        _cell(_fmtCurrency(item.unitPrice), center: true),
        _cell(_fmtCurrency(item.total), center: true, bold: true),
      ],
    );
  }

  Widget _cell(String text, {bool center = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 11,
          color: _bodyText,
          fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }

  // ── Totals ────────────────────────────────────────────────────────────────

  Widget _buildTotalsBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 300,
          child: Table(
            border: TableBorder.all(color: _navyBlue, width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.5),
            },
            children: [
              _totalRow('Subtotal', _fmtCurrency(data.subtotal)),
              if (data.taxPercent > 0)
                _totalRow(
                  'Tax (${data.taxPercent.toStringAsFixed(0)}%)',
                  _fmtCurrency(data.taxAmount),
                ),
              _totalRow(
                'GRAND TOTAL',
                _fmtCurrency(data.grandTotal),
                highlight: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _totalRow(String label, String value, {bool highlight = false}) {
    return TableRow(
      decoration: BoxDecoration(color: highlight ? _navyBlue : Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.white : _bodyText,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? Colors.white : _bodyText,
            ),
          ),
        ),
      ],
    );
  }

  // ── Terms ─────────────────────────────────────────────────────────────────

  Widget _buildTerms() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms & Conditions:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _navyBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.termsAndConditions,
            style: const TextStyle(fontSize: 10, color: _bodyText, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Signature Row ─────────────────────────────────────────────────────────

  Widget _buildSignatureRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _signatureBlock('Prepared By'),
          _signatureBlock('Checked By'),
          _signatureBlock('Authorized Signatory\nABBAS – GC & GOS'),
        ],
      ),
    );
  }

  Widget _signatureBlock(String label) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 48,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _navyBlue, width: 1.2)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _bodyText,
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: const BoxDecoration(color: _navyBlue),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'ABBAS – Government Contractor & General Order Supplier',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Cell: 0312-4115209 | Khomer Chowk, Gilgit',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v, {int decimals = 2}) {
    return v.toStringAsFixed(decimals);
  }

  String _fmtCurrency(double v) {
    // Simple comma-formatting; swap with intl NumberFormat if available
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()}.${parts[1]}';
  }
}
