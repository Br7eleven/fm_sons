import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_blue.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_govt.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_green.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_1.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_3.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_zaiqa.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../controller/create_invoice_controller.dart';
import '../../settings/company_profile_controller.dart';
import 'theme_selector.dart';

class InvoicePreviewScreen extends StatefulWidget {
  /// When set, creates a scoped read-only controller for this invoice ID.
  /// The shared [InvoiceController] is never touched in that case.
  final int? previewInvoiceId;

  /// When true (requires [previewInvoiceId]), renders the template then
  /// immediately triggers the PDF share sheet and pops on completion.
  final bool autoShare;

  const InvoicePreviewScreen({
    super.key,
    this.previewInvoiceId,
    this.autoShare = false,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  late InvoiceThemeType _selectedTheme;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  bool _isPrinting = false;
  bool _isSharingPdf = false;

  // Zoom hint
  bool _showZoomHint = true;
  Timer? _zoomHintTimer;

  // Non-null only when opened from history/clients (read-only scoped view).
  InvoiceController? _scopedController;
  bool _scopedLoading = false;
  String? _scopedError;

  @override
  void initState() {
    super.initState();
    if (widget.previewInvoiceId != null) {
      _loadScoped(widget.previewInvoiceId!);
    } else {
      final controller = context.read<InvoiceController>();
      _selectedTheme = invoiceThemeFromId(controller.templateId);
    }
    // Hide the zoom hint after 2.5 seconds.
    _zoomHintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showZoomHint = false);
    });
  }

  Future<void> _loadScoped(int id) async {
    setState(() => _scopedLoading = true);
    try {
      final ctrl = InvoiceController(autoInitialize: false);
      await ctrl.loadInvoiceForEditing(id);
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _scopedController = ctrl;
        _selectedTheme = invoiceThemeFromId(ctrl.templateId);
        _scopedLoading = false;
      });
      // autoShare: wait for template to be painted, then share PDF and pop.
      if (widget.autoShare) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // Extra frame to ensure RepaintBoundary has fully painted.
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          await _handlePdfAction(ctrl, printOnly: false);
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scopedError = 'Failed to load invoice: $e';
        _scopedLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _zoomHintTimer?.cancel();
    _scopedController?.dispose();
    super.dispose();
  }

  Future<void> _handlePdfAction(
    InvoiceController invoice, {
    required bool printOnly,
  }) async {
    if (printOnly && _isPrinting) return;
    if (!printOnly && _isSharingPdf) return;

    setState(() {
      if (printOnly) {
        _isPrinting = true;
      } else {
        _isSharingPdf = true;
      }
    });
    try {
      final bytes = await _buildPdfBytes(invoice);
      final fileName = '${invoice.invoiceNumber}.pdf';

      if (printOnly) {
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (!mounted) return;
      final message = e is MissingPluginException
          ? 'PDF feature needs a full app restart. Hot reload is not enough after plugin changes.'
          : 'Unable to generate PDF from preview. Please try again.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          if (printOnly) {
            _isPrinting = false;
          } else {
            _isSharingPdf = false;
          }
        });
      }
    }
  }

  Future<Uint8List> _buildPdfBytes(InvoiceController invoice) async {
    try {
      final previewPng = await _capturePreviewPng();
      return _buildImagePdfBytes(previewPng);
    } catch (_) {
      return _buildDataPdfBytes(invoice);
    }
  }

  Future<Uint8List> _buildImagePdfBytes(Uint8List previewPng) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(previewPng);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );

    return await doc.save();
  }

  Future<Uint8List> _buildDataPdfBytes(InvoiceController invoice) async {
    final doc = pw.Document();
    final customerName = (invoice.customerName?.trim().isNotEmpty ?? false)
        ? invoice.customerName!.trim()
        : '-';
    final amountInWords = invoice.amountInWords.trim().isEmpty
        ? 'Zero Rupees only'
        : invoice.amountInWords.trim();

    final rows = invoice.items
        .map(
          (item) => <String>[
            item.name,
            item.quantity.toString(),
            item.unit,
            item.rate.toStringAsFixed(2),
            item.total.toStringAsFixed(2),
          ],
        )
        .toList(growable: false);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          pw.Text(
            'FM Sons Invoice',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Invoice #: ${invoice.invoiceNumber}'),
          pw.Text('Date: ${invoice.invoiceDate.toString().split(' ').first}'),
          pw.Text('Customer: $customerName'),
          pw.SizedBox(height: 12),
          if (rows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: const ['Item', 'Qty', 'Unit', 'Rate', 'Amount'],
              data: rows,
            )
          else
            pw.Text('No line items available.'),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Grand Total: Rs ${invoice.totalAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Amount in words: $amountInWords'),
        ],
      ),
    );

    return await doc.save();
  }

  Future<Uint8List> _capturePreviewPng() async {
    // 6.0 pixel ratio = ~300 DPI for A4 (794px * 6 = ~4764px wide).
    const pixelRatio = 6.0;

    // Wait up to 5 frames for the RepaintBoundary to finish painting.
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;

      final renderObject = _previewBoundaryKey.currentContext
          ?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) continue;
      if (renderObject.debugNeedsPaint || renderObject.size.isEmpty) continue;

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('Failed to encode preview image');
        }
        return byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    }

    throw StateError('Preview is still rendering. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    // Use scoped controller for read-only history previews; shared for create-flow.
    final InvoiceController invoice;
    if (_scopedController != null) {
      invoice = _scopedController!;
    } else {
      invoice = context.watch<InvoiceController>();
    }

    if (_scopedLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          title: const Text('Preview'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_scopedError != null) {
      return Scaffold(
        appBar: AppBar(
          leading: const CloseButton(),
          title: const Text('Preview'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(_scopedError!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Preview'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            onPressed: _isPrinting
                ? null
                : () => _handlePdfAction(invoice, printOnly: true),
          ),
          IconButton(
            icon: _isSharingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isSharingPdf
                ? null
                : () => _handlePdfAction(invoice, printOnly: false),
          ),
        ],
      ),

      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // FittedBox scales the fixed 794x1123 canvas to fit the screen.
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _previewBoundaryKey,
                    child: _buildInvoiceByTheme(invoice),
                  ),
                ),
              ),
            ),
          ),
          // Fade-out zoom hint
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showZoomHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pinch, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Pinch to zoom',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZaiqaTemplate(InvoiceController invoice) {
    final items = invoice.items
        .map(
          (it) => ZaiqaLineItem(
            qty: it.quantity,
            description: it.name,
            rate: it.rate,
          ),
        )
        .toList();
    final signaturePath = context
        .read<CompanyProfileController>()
        .signaturePath;
    return Container(
      width: 794,
      height: 1123,
      decoration: const BoxDecoration(color: Colors.white),
      child: ZaiqaInvoiceWidget(
        customerName: invoice.customerName ?? 'Walk-in Customer',
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.invoiceDate,
        items: items,
        advance: invoice.receivedAmount,
        signaturePath: signaturePath,
      ),
    );
  }

  Widget _buildInvoiceByTheme(InvoiceController invoice) {
    switch (_selectedTheme) {
      case InvoiceThemeType.taxTheme1:
        return TemplateTax1(invoice: invoice);
      case InvoiceThemeType.taxTheme3:
        return TemplateTax3(invoice: invoice);
      case InvoiceThemeType.orangeEstimate:
        return TemplateOrange(invoice: invoice);
      case InvoiceThemeType.blueEstimate:
        return TemplateBlue(invoice: invoice);
      case InvoiceThemeType.govtTemplate:
        return TemplateGovt(invoice: invoice);
      case InvoiceThemeType.zaiqaTemplate:
        return _buildZaiqaTemplate(invoice);
      // ignore: unreachable_switch_default
      default:
        return TemplateTax1(invoice: invoice);
    }
  }
}
