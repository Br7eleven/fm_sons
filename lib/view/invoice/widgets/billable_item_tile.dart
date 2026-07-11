import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';
import '../../masters/unit/unit_controller.dart';

import '../add_invoice_item_screen.dart';
import '../controller/create_invoice_controller.dart';

class BillableItemTile extends StatelessWidget {
  final int index;

  const BillableItemTile({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final item = controller.items[index];

    final unitController = context.read<UnitController>();
    final unit = item.unitId == null
        ? null
        : unitController.getUnitById(item.unitId!);
    final unitLabel = unit?.symbol ?? item.unit;
    final displayUnit = unitLabel.isEmpty ? '-' : unitLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
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
              const SizedBox(width: 6),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddInvoiceItemScreen(
                        itemIndex: index,
                        initialItem: item,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: FMSons.accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: FMSons.accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
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
              _InfoChip(label: 'Qty', value: '${item.quantity} $displayUnit'),

              const SizedBox(width: 12),
              _InfoChip(
                label: 'Rate',
                value: 'Rs ${item.rate.toStringAsFixed(2)} / $displayUnit',
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// Calculation hint (optional but powerful)
          Text(
            '${item.quantity} $displayUnit × Rs ${item.rate.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),

          const SizedBox(height: 8),

          /// Amount (final)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Rs ${item.total.toStringAsFixed(2)}',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13),
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
