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
        // Items list (shown only when items exist)
        if (items.isNotEmpty) ...[
          ListView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => BillableItemTile(index: index),
          ),
          const SizedBox(height: 8),
        ],

        // Add Items button
        InkWell(
          borderRadius: BorderRadius.circular(12),
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E5EFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Add Items ',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E5EFF),
                        ),
                      ),
                      TextSpan(
                        text: '(Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
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
