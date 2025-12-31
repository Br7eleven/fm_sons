import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
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

class _ClientInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: const [
          _ReadOnlyField(
            label: 'Contract Reference',
            value: 'Select Contract...',
            isDropdown: true,
          ),
          SizedBox(height: 12),
          _ReadOnlyField(
            label: 'Billed To',
            value: 'Department of Transportation',
            icon: Icons.apartment,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool isDropdown;
  final IconData? icon;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.isDropdown = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              if (icon != null)
                Icon(icon, size: 18, color: Colors.grey.shade600),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 15)),
              ),
              if (isDropdown)
                Icon(Icons.expand_more, color: Colors.grey.shade600),
            ],
          ),
        ),
      ],
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
                '\$${controller.totalAmount.toStringAsFixed(2)}',
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
                //
                //  Navigate to invoice preview screen
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
