import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_blue.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_orange.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_1.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_3.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../controller/create_invoice_controller.dart';
import 'theme_selector.dart';

class InvoicePreviewScreen extends StatefulWidget {
  const InvoicePreviewScreen({super.key});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  InvoiceThemeType _selectedTheme = InvoiceThemeType.taxTheme1;
  final GlobalKey _previewBoundaryKey = GlobalKey();
  bool _isGeneratingPdf = false;
  bool _isSavingInvoice = false;

  Future<void> _handlePdfAction(
    InvoiceController invoice, {
    required bool printOnly,
  }) async {
    if (_isGeneratingPdf) return;

    setState(() => _isGeneratingPdf = true);
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
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<Uint8List> _buildPdfBytes(InvoiceController invoice) async {
    try {
      final previewPng = await _capturePreviewPng();
      return _buildImagePdfBytes(previewPng);
    } catch (_) {
      // Fallback keeps print/pdf working even if preview capture is temporarily unavailable.
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
                'Grand Total: PKR ${invoice.totalAmount.toStringAsFixed(2)}',
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
    final pixelRatio = ui
        .PlatformDispatcher
        .instance
        .views
        .first
        .devicePixelRatio
        .clamp(2.0, 3.0);

    final renderObject = _previewBoundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Preview render boundary not found');
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      if (renderObject.debugNeedsPaint || renderObject.size.isEmpty) {
        await WidgetsBinding.instance.endOfFrame;
        continue;
      }

      final image = await renderObject.toImage(
        pixelRatio: pixelRatio.toDouble(),
      );
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
    final invoice = context.watch<InvoiceController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        leading: const CloseButton(),
        title: const Text('Preview'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isGeneratingPdf
                ? null
                : () => _handlePdfAction(invoice, printOnly: true),
          ),
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            onPressed: _isGeneratingPdf
                ? null
                : () => _handlePdfAction(invoice, printOnly: false),
          ),
        ],
      ),

      body: Column(
        children: [
          /// 🔹 Theme Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ThemeSelector(
              selectedTheme: _selectedTheme,
              onChanged: (theme) {
                setState(() => _selectedTheme = theme);
              },
            ),
          ),

          /// 🔹 Invoice Preview
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: _previewBoundaryKey,
                  child: _buildInvoiceByTheme(invoice),
                ),
              ),
            ),
          ),

          /// 🔹 Bottom Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSavingInvoice
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final wasEditing = invoice.isEditingInvoice;

                        setState(() => _isSavingInvoice = true);

                        try {
                          final id = await invoice.saveCurrentInvoice();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                wasEditing
                                    ? 'Invoice updated (ID: $id)'
                                    : 'Invoice saved (ID: $id)',
                              ),
                            ),
                          );
                          navigator.pop();
                          navigator.pop();
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSavingInvoice = false);
                          }
                        }
                      },
                child: _isSavingInvoice
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        invoice.isEditingInvoice
                            ? 'Update & Close'
                            : 'Save & Close',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Switch invoice template based on selected theme
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

      default:
        return TemplateTax1(invoice: invoice);
    }
  }
}
