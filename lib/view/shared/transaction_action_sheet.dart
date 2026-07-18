import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';

/// Unified 3-option bottom sheet for Print / Share PDF / View Invoice.
/// Used across home cards, history cards, view-mode AppBar, and payment-in.
class TransactionActionSheet extends StatelessWidget {
  final int invoiceId;

  const TransactionActionSheet({
    super.key,
    required this.invoiceId,
  });

  void _print(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoiceId),
      ),
    );
  }

  void _sharePdf(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          previewInvoiceId: invoiceId,
          autoShare: true,
        ),
      ),
    );
  }

  void _viewInvoice(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(previewInvoiceId: invoiceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Print
            _OptionTile(
              icon: Icons.print_outlined,
              label: 'Print',
              onTap: () => _print(context),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            // Share as PDF
            _OptionTile(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Share as PDF',
              onTap: () => _sharePdf(context),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            // View Invoice
            _OptionTile(
              icon: Icons.remove_red_eye_outlined,
              label: 'View Invoice',
              onTap: () => _viewInvoice(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: FMSons.accent),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
