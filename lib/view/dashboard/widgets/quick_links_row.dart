import 'package:flutter/material.dart';

/// 4 flat icon buttons — no icon-boxes per DESIGN.md rule 3.
class QuickLinksRow extends StatelessWidget {
  final VoidCallback onAddTxn;
  final VoidCallback onSaleReport;
  final VoidCallback onTxnSettings;
  final VoidCallback onShowAll;

  const QuickLinksRow({
    super.key,
    required this.onAddTxn,
    required this.onSaleReport,
    required this.onTxnSettings,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _link(context, Icons.add_circle_outline, 'Add Txn', onAddTxn),
          _link(context, Icons.bar_chart_outlined, 'Sale Report', onSaleReport),
          _link(context, Icons.tune_outlined, 'Txn Settings', onTxnSettings),
          _link(context, Icons.list_outlined, 'Show All', onShowAll),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
