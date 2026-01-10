import 'package:flutter/material.dart';
import '../../controller/create_invoice_controller.dart';

/// Base class for all invoice templates
///
/// IMPORTANT:
/// - Contains NO business logic
/// - Only renders UI from invoice data
/// - Every template MUST extend this
abstract class InvoiceTemplate extends StatelessWidget {
  final InvoiceController invoice;

  const InvoiceTemplate({super.key, required this.invoice});

  /// Template header (logo, company name, etc.)
  Widget buildHeader(BuildContext context);

  /// Customer + invoice meta (date, number)
  Widget buildInvoiceInfo(BuildContext context);

  /// Items table
  Widget buildItems(BuildContext context);

  /// Totals section
  Widget buildTotals(BuildContext context);

  /// Footer (terms, signature, notes)
  Widget buildFooter(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(context),
          const SizedBox(height: 16),

          buildInvoiceInfo(context),
          const SizedBox(height: 16),

          buildItems(context),
          const SizedBox(height: 16),

          buildTotals(context),
          const SizedBox(height: 24),

          buildFooter(context),
        ],
      ),
    );
  }
}
