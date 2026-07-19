import 'package:flutter/material.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';

/// Prints an invoice using the full template rendering pipeline
/// (_captureAllPagePngs → _buildPdfBytes → Printing.layoutPdf) without
/// showing the InvoicePreviewScreen UI on screen.
///
/// Renders InvoicePreviewScreen off-screen inside a dialog Stack so that
/// RepaintBoundary capture works for styled, coloured, multi-page output
/// while the user only sees a loading spinner.
Future<void> printInvoiceDirectly(BuildContext context, int invoiceId) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: Stack(
          children: [
            // Off-screen preview — renders, paints, and is captured by
            // RepaintBoundary.toImage(), but never visible to the user.
            Positioned(
              left: -5000,
              top: 0,
              child: SizedBox(
                width: 794, // A4 width at 96 DPI
                child: UnconstrainedBox(
                  constrainedAxis: Axis.vertical,
                  alignment: Alignment.topCenter,
                  child: InvoicePreviewScreen(
                    previewInvoiceId: invoiceId,
                    autoPrint: true,
                    onPrintComplete: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ),
            ),
            // Visible loading spinner
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    },
  );
}
