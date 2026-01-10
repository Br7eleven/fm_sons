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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const CloseButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'New Invoice',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
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
                if (controller.items.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one item')),
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
