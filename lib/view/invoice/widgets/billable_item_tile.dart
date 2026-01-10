import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../masters/unit/unit_controller.dart';

import '../controller/create_invoice_controller.dart';

class BillableItemTile extends StatelessWidget {
  final int index;

  const BillableItemTile({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final item = controller.items[index];

    final unitController = context.read<UnitController>();
    final unit = unitController.getUnitById(item.unit);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Item name + delete
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => controller.removeItem(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Measurement row (govt style)
          Row(
            children: [
              _InfoChip(
                label: 'Qty',
                value: '${item.quantity} ${unit?.name ?? ''}',
              ),

              const SizedBox(width: 12),
              _InfoChip(
                label: 'Rate',
                value:
                    'PKR ${item.rate.toStringAsFixed(2)} / ${unit?.name ?? ''}',
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Calculation hint (optional but powerful)
          Text(
            '${item.quantity} ${unit?.name ?? ''} × PKR ${item.rate.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 8),

          /// Amount (final)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'PKR ${item.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               INFO CHIP                                    */
/* -------------------------------------------------------------------------- */

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
