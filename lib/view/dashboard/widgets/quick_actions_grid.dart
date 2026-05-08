import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/notes/notes_screen.dart';
import 'quick_action_tile.dart';

class QuickActionGrid extends StatelessWidget {
  final Future<void> Function()? onNewInvoiceTap;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onClientsTap;

  const QuickActionGrid({
    super.key,
    this.onNewInvoiceTap,
    this.onHistoryTap,
    this.onClientsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // 🔹 Main Action
        QuickActionTile(
          icon: Icons.add,
          title: 'New Invoice',
          subtitle: 'Create a new government contract bill',
          onTap: () {
            if (onNewInvoiceTap != null) {
              unawaited(onNewInvoiceTap!());
              return;
            }

            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // 🔹 Secondary Actions
        Row(
          children: [
            Expanded(
              child: _SmallActionTile(
                icon: Icons.history,
                title: 'History',
                subtitle: 'View past records',
                onTap: onHistoryTap ?? () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallActionTile(
                icon: Icons.people,
                title: 'Clients',
                subtitle: 'Manage database',
                onTap: onClientsTap ?? () {},
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 🔹 Notes Action
        _SmallActionTile(
          icon: Icons.note_alt_outlined,
          title: 'Notes',
          subtitle: 'Quick notes & memos',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotesScreen()),
            );
          },
        ),
      ],
    );
  }
}

/// 🔹 Smaller square-style action tile
class _SmallActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SmallActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
