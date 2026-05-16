import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'letterheads_registry.dart';

class LetterheadViewerScreen extends StatelessWidget {
  final Letterhead letterhead;

  const LetterheadViewerScreen({super.key, required this.letterhead});

  Future<Uint8List> _loadPdf() async {
    final bytes = await rootBundle.load(letterhead.assetPath);
    return bytes.buffer.asUint8List();
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await _loadPdf();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${letterhead.id}_letterhead.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${letterhead.name} Letterhead',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Future<void> _printPdf(BuildContext context) async {
    try {
      final bytes = await _loadPdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          letterhead.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print',
            onPressed: () => _printPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _sharePdf(context),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
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
            pdfPreviewPageDecoration: const BoxDecoration(
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
