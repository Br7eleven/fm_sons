import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../settings/company_profile_controller.dart';
import 'letterhead_govt_widget.dart';
import 'letterheads_registry.dart';

class LetterheadViewerScreen extends StatefulWidget {
  final Letterhead letterhead;

  const LetterheadViewerScreen({super.key, required this.letterhead});

  @override
  State<LetterheadViewerScreen> createState() => _LetterheadViewerScreenState();
}

class _LetterheadViewerScreenState extends State<LetterheadViewerScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isBusy = false;

  bool get _isCoded => widget.letterhead.assetPath == null;

  Future<Uint8List> _loadPdf() async {
    final bytes = await rootBundle.load(widget.letterhead.assetPath!);
    return bytes.buffer.asUint8List();
  }

  Future<Uint8List> _buildCodedPdfBytes() async {
    const pixelRatio = 6.0;
    for (var attempt = 0; attempt < 5; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      final ro = _boundaryKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) continue;
      if (ro.debugNeedsPaint || ro.size.isEmpty) continue;

      final image = await ro.toImage(pixelRatio: pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('Failed to encode image');
        final pngBytes = byteData.buffer.asUint8List();

        final doc = pw.Document();
        final pdfImage = pw.MemoryImage(pngBytes);
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
          ),
        );
        return doc.save();
      } finally {
        image.dispose();
      }
    }
    throw StateError('Preview still rendering. Please try again.');
  }

  Future<void> _print() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bytes = _isCoded ? await _buildCodedPdfBytes() : await _loadPdf();
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: '${widget.letterhead.id}_letterhead.pdf',
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to print: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _share() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final bytes = _isCoded ? await _buildCodedPdfBytes() : await _loadPdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.letterhead.id}_letterhead.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${widget.letterhead.name} Letterhead',
      );
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to share: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.letterhead.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
              onPressed: _print,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share',
              onPressed: _share,
            ),
          ],
        ],
      ),
      body: _isCoded ? _buildCodedViewer() : _buildPdfViewer(),
    );
  }

  Widget _buildCodedViewer() {
    return InteractiveViewer(
      minScale: 0.3,
      maxScale: 5.0,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: ChangeNotifierProvider.value(
                  value: context.read<CompanyProfileController>(),
                  child: const LetterheadGovtWidget(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return FutureBuilder<Uint8List>(
      future: _loadPdf(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                const Text('Failed to load letterhead'),
              ],
            ),
          );
        }
        return PdfPreview(
          build: (_) async => snapshot.data!,
          canChangePageFormat: false,
          canChangeOrientation: false,
          canDebug: false,
          allowPrinting: false,
          allowSharing: false,
          maxPageWidth: 900,
          pdfPreviewPageDecoration: const BoxDecoration(color: Colors.white),
        );
      },
    );
  }
}
