import 'package:flutter/material.dart';

import 'package:fm_sons/utils/constants/color_string.dart';

/// App-styled modal dialog: rounded corners and title typography consistent
/// with the app's cards/sheets, so dialogs no longer look like the default
/// Flutter [AlertDialog]. Reuse this for any future modal.
class AppDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: content,
      actions: actions,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}

/// Primary (filled) dialog button — matches the app's primary action button.
Widget dialogPrimaryButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: FMSons.accent,
      foregroundColor: FMSons.bgWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

/// Secondary/text dialog button (e.g. Cancel).
Widget dialogTextButton({
  required String label,
  required VoidCallback onPressed,
}) {
  return TextButton(
    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
    onPressed: onPressed,
    child: Text(label),
  );
}
