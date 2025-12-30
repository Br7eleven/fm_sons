import 'package:flutter/material.dart';

class StatCardRow extends StatelessWidget {
  const StatCardRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: StatCard(
            title: "This Month's Total",
            value: '₹ 12.5L',
            subtitle: '+5%',
            icon: Icons.calendar_month,
            iconColor: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Invoices Today',
            value: '3',
            subtitle: 'Pending: 1',
            icon: Icons.receipt_long,
            iconColor: Colors.orange,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey)),
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
