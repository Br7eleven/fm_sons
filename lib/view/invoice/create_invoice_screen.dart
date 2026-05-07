import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/masters/customer/customer_selector_bottom_sheet.dart.dart';
import 'package:provider/provider.dart';

import 'controller/create_invoice_controller.dart';
import 'widgets/invoice_header.dart';
import 'widgets/invoice_items_section.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.watch<InvoiceController>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Draft is automatically saved via _saveDraft() on each change
        // No need to clear draft when navigating away
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              // Just navigate back, draft is preserved automatically
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, color: Colors.black),
          ),
          centerTitle: true,
          title: Text(
            invoiceController.isEditingInvoice ? 'Edit Invoice' : 'New Invoice',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (invoiceController.items.isNotEmpty ||
                invoiceController.customerName != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'discard',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text(
                          'Discard Draft',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'discard') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Discard Draft?'),
                        content: const Text(
                          'All unsaved changes will be lost. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Discard'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await context.read<InvoiceController>().resetDraft();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  }
                },
              ),
          ],
        ),

      /// MAIN LAYOUT
      body: Column(
        children: [
          /// 🔹 Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const InvoiceHeader(),
                  const SizedBox(height: 24),

                  /// Client Information
                  const Text(
                    'Client Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  _ClientInfoSection(),

                  const SizedBox(height: 24),

                  /// Billable Items
                  const InvoiceItemsSection(),

                  const SizedBox(height: 24),

                  /// Notes
                  const _InvoiceNotesSection(),

                  /// Space for fixed bottom bar
                  // const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          /// 🔹 Fixed Bottom Bar
          const _InvoiceBottomBar(),
        ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           CLIENT INFO SECTION                               */
/* -------------------------------------------------------------------------- */

class _ClientInfoSection extends StatefulWidget {
  @override
  State<_ClientInfoSection> createState() => _ClientInfoSectionState();
}

class _ClientInfoSectionState extends State<_ClientInfoSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final invoiceController = context.read<InvoiceController>();

    _controller = TextEditingController(
      text: invoiceController.customerName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Name',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: _controller,
            onChanged: invoiceController.setCustomerName,
            decoration: InputDecoration(
              hintText: 'Enter customer name',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () async {
                  final customer = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    barrierColor: Colors.black26,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    builder: (_) => const CustomerSelectorBottomSheet(),
                  );

                  if (customer != null) {
                    invoiceController.setCustomer(customer);
                    _controller.text = customer.name; // 🔥 keep sync
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         FIXED BOTTOM SUMMARY BAR                             */
/* -------------------------------------------------------------------------- */

class _InvoiceBottomBar extends StatelessWidget {
  const _InvoiceBottomBar();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                'PKR ${controller.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          /// Preview Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E5EFF),
                foregroundColor: FMSons.bgWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (controller.isLoading) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please wait...')),
                  );
                  return;
                }

                if (controller.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one item')),
                  );
                  return;
                }

                if ((controller.customerName ?? '').trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Customer name is required')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InvoicePreviewScreen(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Preview Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               NOTES SECTION                                */
/* -------------------------------------------------------------------------- */

class _InvoiceNotesSection extends StatefulWidget {
  const _InvoiceNotesSection();

  @override
  State<_InvoiceNotesSection> createState() => _InvoiceNotesSectionState();
}

class _InvoiceNotesSectionState extends State<_InvoiceNotesSection> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<InvoiceController>();
    _notesController = TextEditingController(text: controller.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Note',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            onChanged: controller.setNotes,
            decoration: InputDecoration(
              hintText: 'Add note or description',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
