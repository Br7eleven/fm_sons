import 'package:flutter/material.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_modern.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_1.dart';
import 'package:fm_sons/view/invoice/preview/templates/template_tax_3.dart';
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
            onPressed: () {
              // TODO: print logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: template settings
            },
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
              child: AspectRatio(
                aspectRatio: 1 / 1.414, // A4 ratio
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
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
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Save & Close'),
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

      case InvoiceThemeType.modernRed:
        return TemplateModern(invoice: invoice);

      default:
        return TemplateTax1(invoice: invoice);
    }
  }
}
