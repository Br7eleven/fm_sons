import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/models/invoice_model.dart';
import 'package:fm_sons/utils/number_to_words.dart';
import 'payment_in_receipt_template.dart';

class PaymentInReceiptPreviewScreen extends StatefulWidget {
  final int invoiceId;
  final bool autoShare;

  const PaymentInReceiptPreviewScreen({
    super.key,
    required this.invoiceId,
    this.autoShare = false,
  });

  @override
  State<PaymentInReceiptPreviewScreen> createState() =>
      _PaymentInReceiptPreviewScreenState();
}

class _PaymentInReceiptPreviewScreenState
    extends State<PaymentInReceiptPreviewScreen> {
  final GlobalKey _previewBoundaryKey = GlobalKey();
  final InvoiceDao _invoiceDao = InvoiceDao();
  InvoiceModel? _record;
  bool _isLoading = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final record = await _invoiceDao.getInvoiceById(widget.invoiceId);
    if (mounted) {
      setState(() {
        _record = record;
        _isLoading = false;
      });
    }
    if (widget.autoShare) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) await _sharePdf();
        if (mounted && widget.autoShare) Navigator.pop(context);
      });
    }
  }

  Future<Uint8List?> _capturePng() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject =
          _previewBoundaryKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) continue;
      if (renderObject.debugNeedsPaint || renderObject.size.isEmpty) continue;
      final image = await renderObject.toImage(pixelRatio: 6.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }
    return null;
  }

  Future<void> _sharePdf() async {
    if (_isSharing || _record == null) return;
    setState(() => _isSharing = true);

    try {
      final png = await _capturePng();
      if (png == null) throw StateError('Could not capture preview');

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (_) =>
              pw.Center(child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain)),
        ),
      );
      final bytes = await doc.save();
      final fileName = '${_record!.invoiceNumber}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Failed to share PDF: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareImage() async {
    if (_isSharing || _record == null) return;
    setState(() => _isSharing = true);

    try {
      final png = await _capturePng();
      if (png == null) throw StateError('Could not capture preview');

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/${_record!.invoiceNumber}.png');
      await file.writeAsBytes(png);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Payment Receipt ${_record!.invoiceNumber}',
        text: 'Payment Receipt ${_record!.invoiceNumber}',
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Failed to share image: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  String _amountWords(InvoiceModel r) {
    final words = numberToWords(r.total.floor());
    return '$words Rupees only';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment Receipt'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined),
            tooltip: 'Share as Image',
            onPressed: _isSharing ? null : _shareImage,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Share as PDF',
            onPressed: _isSharing ? null : _sharePdf,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _record == null
              ? const Center(child: Text('Receipt not found'))
              : SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        RepaintBoundary(
                          key: _previewBoundaryKey,
                          child: PaymentInReceiptTemplate(
                            record: _record!,
                            amount: _record!.total,
                            amountInWords: _amountWords(_record!),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }
}
