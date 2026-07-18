import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';

import '../controller/create_invoice_controller.dart';
import 'billable_item_tile.dart';
import '../add_invoice_item_screen.dart';

class InvoiceItemsSection extends StatefulWidget {
  const InvoiceItemsSection({super.key});

  @override
  State<InvoiceItemsSection> createState() => _InvoiceItemsSectionState();
}

class _InvoiceItemsSectionState extends State<InvoiceItemsSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final items = controller.items;

    if (items.isEmpty && !controller.isViewMode) {
      return _buildAddItemsButton(context);
    }
    if (items.isEmpty && controller.isViewMode) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Billed Items header — always visible when items exist
        InkWell(
          onTap: controller.isViewMode
              ? null
              : () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Billed Items',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: const BoxDecoration(
                    color: FMSons.accent,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    '${items.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!controller.isViewMode) ...[
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.keyboard_arrow_down, size: 22),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Expandable items area — wrapped with snackbar gesture in view mode
        GestureDetector(
          onTap: controller.isViewMode
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please click on Edit to change the item details.',
                      ),
                    ),
                  );
                }
              : null,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: ListView.builder(
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) =>
                            BillableItemTile(index: index),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Add Items button — hidden in view mode
        if (!controller.isViewMode) _buildAddItemsButton(context),
      ],
    );
  }

  Widget _buildAddItemsButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        FocusScope.of(context).unfocus();
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddInvoiceItemScreen()),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).unfocus();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: FMSons.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Add Items ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: FMSons.accent,
                    ),
                  ),
                  TextSpan(
                    text: '(Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
