import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

class SegmentedToggle extends StatelessWidget {
  final PageController pageController;
  final ValueChanged<int> onChanged;

  const SegmentedToggle({
    super.key,
    required this.pageController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedBuilder(
        animation: pageController,
        builder: (context, _) {
          double page = 0;
          if (pageController.hasClients &&
              pageController.position.haveDimensions) {
            page = pageController.page ?? 0;
          }
          page = page.clamp(0.0, 1.0);

          return Row(
            children: [
              Expanded(
                child: _PillTab(
                  label: 'Transaction Details',
                  t: (1 - page).clamp(0.0, 1.0),
                  onTap: () => onChanged(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PillTab(
                  label: 'Party Details',
                  t: page.clamp(0.0, 1.0),
                  onTap: () => onChanged(1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final double t;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Color.lerp(Colors.grey.shade300, FMSons.accent, t)!;
    final fillColor = Color.lerp(
      Colors.transparent,
      FMSons.accent.withValues(alpha: 0.1),
      t,
    )!;
    final textColor = Color.lerp(Colors.grey.shade500, FMSons.accent, t)!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
