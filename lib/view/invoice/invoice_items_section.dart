import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/create_invoice_controller.dart';
import 'widgets/billable_item_tile.dart';
import 'add_invoice_item_screen.dart';

class InvoiceItemsSection extends StatelessWidget {
  const InvoiceItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Billable Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text('${controller.items.length} items'),
          ],
        ),
        const SizedBox(height: 12),

        if (controller.items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              return BillableItemTile(
                item: controller.items[index],
                onDelete: () => controller.removeItem(index),
              );
            },
          ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: () async {
            final item = await Navigator.push<InvoiceItem>(
              context,
              MaterialPageRoute(builder: (_) => const AddInvoiceItemScreen()),
            );

            if (item != null) {
              controller.addItem(item);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue, width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Add Line Item',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Amount', style: TextStyle(fontSize: 16)),
            Text(
              '\$${controller.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
