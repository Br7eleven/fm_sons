import 'package:flutter/material.dart';

class StatCardRow extends StatelessWidget {
  final String pendingAmountLabel;
  final String paidAmountLabel;
  final int totalInvoices;
  final int todayInvoices;

  const StatCardRow({
    super.key,
    required this.pendingAmountLabel,
    required this.paidAmountLabel,
    required this.totalInvoices,
    required this.todayInvoices,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Pending Amount',
            value: pendingAmountLabel,
            subtitle: 'Paid: $paidAmountLabel',
            icon: Icons.pending_actions,
            iconColor: Colors.deepOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Total Invoices',
            value: totalInvoices.toString(),
            subtitle: 'Today: $todayInvoices',
            icon: Icons.receipt_long,
            iconColor: Colors.green,
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}
