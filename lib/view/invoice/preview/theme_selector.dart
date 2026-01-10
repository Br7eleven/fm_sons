import 'package:flutter/material.dart';

/// Enum for available invoice themes
enum InvoiceThemeType { taxTheme1, taxTheme3, modernRed, modernDark }

class ThemeSelector extends StatelessWidget {
  final InvoiceThemeType selectedTheme;
  final ValueChanged<InvoiceThemeType> onChanged;

  const ThemeSelector({
    super.key,
    required this.selectedTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      _ThemeItem(
        type: InvoiceThemeType.taxTheme1,
        color: const Color(0xFF6C63FF),
      ),
      _ThemeItem(
        type: InvoiceThemeType.taxTheme3,
        color: const Color(0xFF0D47A1),
      ),
      _ThemeItem(
        type: InvoiceThemeType.modernRed,
        color: const Color(0xFFD32F2F),
      ),
      _ThemeItem(
        type: InvoiceThemeType.modernDark,
        color: const Color(0xFF263238),
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = theme.type == selectedTheme;

          return GestureDetector(
            onTap: () => onChanged(theme.type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: theme.color, width: 2)
                    : null,
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.color,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Internal theme config holder
class _ThemeItem {
  final InvoiceThemeType type;
  final Color color;

  _ThemeItem({required this.type, required this.color});
}
