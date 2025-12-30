import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/create_invoice_controller.dart';
import 'widgets/invoice_header.dart';
import 'invoice_items_section.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvoiceController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New Invoice'),
          leading: const CloseButton(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InvoiceHeader(),
              const SizedBox(height: 20),

              // Client info (static for now – matches Stitch)
              const Text(
                'Client Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Contract Reference',
                  hintText: 'Select Contract...',
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Billed To',
                  hintText: 'Department of Transportation',
                ),
              ),

              const SizedBox(height: 24),
              const InvoiceItemsSection(),

              const SizedBox(height: 24),

              // Preview button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // navigate to invoice preview later
                  },
                  child: const Text('Preview Invoice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
