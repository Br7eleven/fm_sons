import 'package:flutter/material.dart';

/// Enum for available invoice themes
enum InvoiceThemeType { taxTheme1, taxTheme3, orangeEstimate, blueEstimate }

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
        type: InvoiceThemeType.orangeEstimate,
        color: const Color(0xFFFF5722),
      ),
      _ThemeItem(
        type: InvoiceThemeType.blueEstimate,
        color: const Color(0xFF1976D2),
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
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
