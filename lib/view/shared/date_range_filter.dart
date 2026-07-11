import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:intl/intl.dart';

class DateRangeFilter extends StatelessWidget {
  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;

  const DateRangeFilter({
    super.key,
    required this.range,
    required this.onChanged,
  });

  static final _fmt = DateFormat('dd MMM yyyy');

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: range ??
          DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                primary: FMSons.accent,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = range != null;

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasRange
              ? FMSons.accent.withValues(alpha: 0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasRange
                ? FMSons.accent.withValues(alpha: 0.3)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today,
                size: 14,
                color: hasRange ? FMSons.accent : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              hasRange
                  ? '${_fmt.format(range!.start)}  →  ${_fmt.format(range!.end)}'
                  : 'Pick date range',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasRange ? FMSons.accent : Colors.grey.shade600,
              ),
            ),
            if (hasRange) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
