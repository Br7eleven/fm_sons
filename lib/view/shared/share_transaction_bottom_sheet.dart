import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';

/// Bottom sheet for sharing a transaction as Image or PDF.
/// Routes to the appropriate preview screen per document type.
class ShareTransactionBottomSheet extends StatefulWidget {
  final int invoiceId;
  final String documentType; // 'payment_in', 'invoice', 'estimate'

  const ShareTransactionBottomSheet({
    super.key,
    required this.invoiceId,
    required this.documentType,
  });

  @override
  State<ShareTransactionBottomSheet> createState() =>
      _ShareTransactionBottomSheetState();
}

class _ShareTransactionBottomSheetState
    extends State<ShareTransactionBottomSheet> {
  bool _makeDefault = false;

  Future<void> _shareAsPdf() async {
    if (_makeDefault) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_share_format', 'pdf');
    }
    if (!mounted) return;
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          previewInvoiceId: widget.invoiceId,
        ),
      ),
    );
  }

  Future<void> _shareAsImage() async {
    if (_makeDefault) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_share_format', 'image');
    }
    if (!mounted) return;
    Navigator.pop(context);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePreviewScreen(
          previewInvoiceId: widget.invoiceId,
          autoShare: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text(
              'Share transaction',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FMSons.accent,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _shareAsImage,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: const Text('Share as Image'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _shareAsPdf,
                      icon:
                          const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: const Text('Share as PDF'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _makeDefault,
                    onChanged: (v) =>
                        setState(() => _makeDefault = v ?? false),
                    activeColor: FMSons.accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Make this as default',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'To change later go to transaction settings*',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
