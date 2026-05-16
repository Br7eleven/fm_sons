import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/invoice/preview/theme_selector.dart';
import 'package:fm_sons/view/masters/customer/customer_selector_bottom_sheet.dart.dart';
import 'package:provider/provider.dart';

import 'controller/create_invoice_controller.dart';
import 'widgets/invoice_header.dart';
import 'widgets/invoice_items_section.dart';

class CreateInvoiceScreen extends StatelessWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.watch<InvoiceController>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Draft is automatically saved via _saveDraft() on each change
        // No need to clear draft when navigating away
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              // Just navigate back, draft is preserved automatically
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
          centerTitle: true,
          title: Text(
            invoiceController.isEditingInvoice ? 'Edit Invoice' : 'New Invoice',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            if (invoiceController.items.isNotEmpty ||
                invoiceController.customerName != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'discard',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Discard Draft',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'discard') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Discard Draft?'),
                        content: const Text(
                          'All unsaved changes will be lost. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          Builder(
                            builder: (context) => ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Discard'),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await context.read<InvoiceController>().resetDraft();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  }
                },
              ),
          ],
        ),

        /// MAIN LAYOUT
        body: Column(
          children: [
            /// 🔹 Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InvoiceHeader(),
                    const SizedBox(height: 24),

                    /// Client Information
                    const Text(
                      'Client Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _ClientInfoSection(),

                    const SizedBox(height: 24),

                    /// Billable Items
                    const InvoiceItemsSection(),

                    const SizedBox(height: 24),

                    /// Notes
                    const _InvoiceNotesSection(),

                    /// Space for fixed bottom bar
                    // const SizedBox(height: 120),
                  ],
                ),
              ),
            ),

            /// 🔹 Fixed Bottom Bar
            const _InvoiceBottomBar(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           CLIENT INFO SECTION                               */
/* -------------------------------------------------------------------------- */

class _ClientInfoSection extends StatefulWidget {
  @override
  State<_ClientInfoSection> createState() => _ClientInfoSectionState();
}

class _ClientInfoSectionState extends State<_ClientInfoSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final invoiceController = context.read<InvoiceController>();

    _controller = TextEditingController(
      text: invoiceController.customerName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Name',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 6),

          TextField(
            controller: _controller,
            onChanged: invoiceController.setCustomerName,
            decoration: InputDecoration(
              hintText: 'Enter customer name',
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () async {
                  final customer = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const CustomerSelectorBottomSheet(),
                  );

                  if (customer != null) {
                    invoiceController.setCustomer(customer);
                    _controller.text = customer.name; // 🔥 keep sync
                  }
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         FIXED BOTTOM SUMMARY BAR                             */
/* -------------------------------------------------------------------------- */

class _InvoiceBottomBar extends StatefulWidget {
  const _InvoiceBottomBar();

  @override
  State<_InvoiceBottomBar> createState() => _InvoiceBottomBarState();
}

class _InvoiceBottomBarState extends State<_InvoiceBottomBar> {
  bool _isSaving = false;

  static const _templateColors = {
    InvoiceThemeType.taxTheme1: Color(0xFF6C63FF),
    InvoiceThemeType.taxTheme3: Color(0xFF0D47A1),
    InvoiceThemeType.orangeEstimate: Color(0xFFFF5722),
    InvoiceThemeType.blueEstimate: Color(0xFF1976D2),
  };

  static const _templateLabels = {
    InvoiceThemeType.taxTheme1: 'Tax 1',
    InvoiceThemeType.taxTheme3: 'Tax 3',
    InvoiceThemeType.orangeEstimate: 'Orange',
    InvoiceThemeType.blueEstimate: 'Blue',
  };

  bool _validate(InvoiceController controller) {
    if (controller.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return false;
    }
    if ((controller.customerName ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveInvoice(InvoiceController controller) async {
    if (_isSaving || !_validate(controller)) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final wasEditing = controller.isEditingInvoice;

    setState(() => _isSaving = true);
    try {
      final id = await controller.saveCurrentInvoice();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasEditing ? 'Invoice updated (ID: $id)' : 'Invoice saved (ID: $id)',
          ),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final selectedTheme = invoiceThemeFromId(controller.templateId);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                'PKR ${controller.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Template selector
          Row(
            children: [
              const Text(
                'Template:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: InvoiceThemeType.values.map((type) {
                      final color = _templateColors[type]!;
                      final label = _templateLabels[type]!;
                      final isSelected = type == selectedTheme;
                      return GestureDetector(
                        onTap: () => context
                            .read<InvoiceController>()
                            .setTemplateId(type.name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color,
                              width: isSelected ? 0 : 1,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Action buttons row
          Row(
            children: [
              /// Preview button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1E5EFF)),
                      foregroundColor: const Color(0xFF1E5EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: controller.isLoading
                        ? null
                        : () {
                            if (!_validate(controller)) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvoicePreviewScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// Save button
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E5EFF),
                      foregroundColor: FMSons.bgWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving || controller.isLoading
                        ? null
                        : () => _saveInvoice(controller),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      controller.isEditingInvoice ? 'Update' : 'Save',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               NOTES SECTION                                */
/* -------------------------------------------------------------------------- */

class _InvoiceNotesSection extends StatefulWidget {
  const _InvoiceNotesSection();

  @override
  State<_InvoiceNotesSection> createState() => _InvoiceNotesSectionState();
}

class _InvoiceNotesSectionState extends State<_InvoiceNotesSection> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<InvoiceController>();
    _notesController = TextEditingController(text: controller.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            onChanged: controller.setNotes,
            decoration: InputDecoration(
              hintText: 'Add note or description',
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
