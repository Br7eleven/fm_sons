import 'package:flutter/material.dart';

class CalculationCard extends StatelessWidget {
  final int quantity;
  final double rate;
  final String unit;

  const CalculationCard({
    super.key,
    required this.quantity,
    required this.rate,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final total = quantity * rate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$quantity $unit × \$${rate.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
