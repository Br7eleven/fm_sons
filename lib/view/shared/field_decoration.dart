import 'package:flutter/material.dart';

import 'package:fm_sons/utils/constants/color_string.dart';

/// Shared outline input decoration used across the app (matches the Sale
/// screen's Customer field): floating label, filled card background, light
/// grey unfocused border, and the brand [FMSons.accent] on focus.
InputDecoration appInputDecoration(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    filled: true,
    fillColor: Theme.of(context).cardColor,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: FMSons.accent, width: 1.5),
    ),
  );
}
