import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/create_invoice_controller.dart';
import 'billable_item_tile.dart';
import '../add_invoice_item_screen.dart';

class InvoiceItemsSection extends StatelessWidget {
  const InvoiceItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final items = controller.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Section Header
        Row(
          children: [
            const Text(
              'Billable Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              Text(
                '${items.length} item${items.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
          ],
        ),

        const SizedBox(height: 12),

        /// Empty State
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'No billable items added',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 6),
                Text(
                  'Add materials or work items with quantity, unit, and rate.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

        /// Items List
        if (items.isNotEmpty)
          ListView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return BillableItemTile(index: index);
            },
          ),

        const SizedBox(height: 14),

        /// Add Line Item Action
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddInvoiceItemScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Billable Item',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
