import 'package:flutter/material.dart';

class OverviewCard extends StatelessWidget {
  final String billedAmountLabel;
  final String trendLabel;

  const OverviewCard({
    super.key,
    required this.billedAmountLabel,
    this.trendLabel = 'Live',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // 🔹 full width like PNG
      padding: const EdgeInsets.all(20), // 🔹 correct padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Top row (icon + badge placeholder)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _IconBox(),
              _GrowthBadge(label: trendLabel),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            "Today's Billed Amount",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            billedAmountLabel,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 Left icon box (as in PNG)
class _IconBox extends StatelessWidget {
  const _IconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.payments, color: Colors.white),
    );
  }
}

/// 🔹 Right "+12% vs yest." badge
class _GrowthBadge extends StatelessWidget {
  final String label;

  const _GrowthBadge({this.label = 'Live'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
