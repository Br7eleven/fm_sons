import 'package:flutter/material.dart';

class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'Invoice #INV-2023-089',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text('27/10/2023'),
        ],
      ),
    );
  }
}
