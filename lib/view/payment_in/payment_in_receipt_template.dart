import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/view/settings/company_profile_controller.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/utils/number_to_words.dart';

/// A4 receipt template for Payment-In records.
/// Uses same capture-based PDF approach as invoice templates.
class PaymentInReceiptTemplate extends StatelessWidget {
  final InvoiceModel record;
  final double amount;
  final String amountInWords;

  const PaymentInReceiptTemplate({
    super.key,
    required this.record,
    required this.amount,
    this.amountInWords = '',
  });

  static CompanyProfileController companyOf(BuildContext context) =>
      context.read<CompanyProfileController>();

  String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd-MM-yyyy').format(d);
  }

  String get _amountWords {
    final text = amountInWords.trim();
    if (text.isNotEmpty) return text;
    final words = numberToWords(amount.floor());
    return '$words Rupees only';
  }

  @override
  Widget build(BuildContext context) {
    final company = companyOf(context);

    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF1A1A1A), fontFamily: ''),
      child: Container(
        width: 794,
        height: 1123,
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Company header ──
            Text(
              company.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              company.email,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),

            const SizedBox(height: 24),

            // ── Divider ──
            Container(height: 1, color: Colors.grey.shade300),

            // ── Payment-In title ──
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Payment-In',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: FMSons.accent,
                  ),
                ),
              ),
            ),

            // ── Divider ──
            Container(height: 1, color: Colors.grey.shade300),

            const SizedBox(height: 28),

            // ── Body: Received From | Receipt Details ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Received From
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Received From',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Receipt Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Receipt Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _detailRow('Receipt No.', record.invoiceNumber),
                      const SizedBox(height: 4),
                      _detailRow('Date', _fmtDate(record.invoiceDate)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Amount section ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount in words
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amount In Words',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _amountWords,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // Received amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: 'Rs ',
                        decimalDigits: 2,
                      ).format(amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // ── Footer ──
            Container(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'For:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Signature
                    _buildSignature(company),
                    const SizedBox(height: 4),
                    const Text(
                      'Authorized Signatory',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignature(CompanyProfileController company) {
    final sigPath = company.signaturePath;
    if (sigPath == null) {
      return const SizedBox(height: 40);
    }
    return SizedBox(
      height: 40,
      child: Image.file(File(sigPath), height: 40, fit: BoxFit.contain),
    );
  }
}
