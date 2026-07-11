import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:open_filex/open_filex.dart';
import 'package:fm_sons/view/invoice/preview/invoice_preview_screen.dart';
import 'package:fm_sons/view/invoice/preview/theme_selector.dart';
import 'package:fm_sons/view/masters/customer/customer_controller.dart';
import 'package:fm_sons/view/masters/customer/add_party_form_sheet.dart';
import 'package:fm_sons/view/masters/customer/customer_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:fm_sons/data/local/dao/invoice_dao.dart';
import 'package:fm_sons/data/local/models/terms_condition_model.dart';
import 'package:fm_sons/utils/money_utils.dart';

import 'controller/create_invoice_controller.dart';
import 'terms_condition_editor_screen.dart';
import 'widgets/invoice_header.dart';
import 'widgets/invoice_items_section.dart';

/// Thin wrapper that ensures a fresh controller state on each navigation.
/// When [invoiceId] is provided, loads that invoice for editing.
/// Otherwise, resets the controller to a clean new-invoice state.
class CreateInvoiceScreen extends StatefulWidget {
  final int? invoiceId;
  const CreateInvoiceScreen({super.key, this.invoiceId});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final controller = context.read<InvoiceController>();
    if (widget.invoiceId != null) {
      await controller.loadInvoiceForEditing(widget.invoiceId!);
    } else {
      await controller.resetDraft();
    }
    if (mounted) setState(() => _isReady = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            widget.invoiceId != null ? 'Edit Invoice' : 'Sale',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return const _CreateInvoiceBody();
  }
}

class _CreateInvoiceBody extends StatelessWidget {
  const _CreateInvoiceBody();

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.watch<InvoiceController>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(
            'Sale',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            // Credit / Cash toggle — only for invoices
            if (!invoiceController.isEstimate) _CreditCashToggle(),
            if (!invoiceController.isEstimate) const SizedBox(width: 8),
            // Settings / more
            if (invoiceController.items.isNotEmpty ||
                invoiceController.customerName != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.settings_outlined),
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
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Discard Draft?'),
                        content: const Text(
                          'All unsaved changes will be lost.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          Builder(
                            builder: (ctx2) => ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  ctx2,
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
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  }
                },
              )
            else
              const SizedBox(width: 48, child: Icon(Icons.settings_outlined)),
            const SizedBox(width: 4),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Invoice No + Date row ──
                    const InvoiceHeader(),

                    const SizedBox(height: 8),

                    // ── Customer field ──
                    _CustomerField(),

                    const SizedBox(height: 10),

                    // ── Invoice / Estimate toggle ──
                    _DocTypeToggle(),

                    const SizedBox(height: 8),

                    // ── Add Items ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const InvoiceItemsSection(),
                    ),

                    const SizedBox(height: 8),

                    // ── Totals block ──
                    _TotalsSection(),

                    // ── Note + Image + Document (shown only when total > 0) ──
                    _ConditionalExtrasSection(),

                    const SizedBox(height: 8),

                    // ── Terms & Conditions + Custom Notes ──
                    const _TermsAndNotesSection(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom Bar ──
            const _InvoiceBottomBar(),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         CREDIT / CASH TOGGLE                                */
/* -------------------------------------------------------------------------- */

class _CreditCashToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final isCredit = controller.paymentStatus == 'unpaid';

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'Credit',
            selected: isCredit,
            selectedColor: FMSons.accent,
            onTap: () => controller.setPaymentStatus('unpaid'),
          ),
          _ToggleChip(
            label: 'Cash',
            selected: !isCredit,
            selectedColor: Colors.grey.shade700,
            onTap: () => controller.setPaymentStatus('paid'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                       INVOICE / ESTIMATE TOGGLE                             */
/* -------------------------------------------------------------------------- */

class _DocTypeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final isInvoice = !controller.isEstimate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'Type',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleChip(
                  label: 'Invoice',
                  selected: isInvoice,
                  selectedColor: FMSons.accent,
                  onTap: () => controller.setDocumentType('invoice'),
                ),
                _ToggleChip(
                  label: 'Estimate',
                  selected: !isInvoice,
                  selectedColor: FMSons.accent,
                  onTap: () => controller.setDocumentType('estimate'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                           CUSTOMER FIELD                                    */
/* -------------------------------------------------------------------------- */

class _CustomerField extends StatefulWidget {
  @override
  State<_CustomerField> createState() => _CustomerFieldState();
}

class _CustomerFieldState extends State<_CustomerField> {
  final InvoiceDao _invoiceDao = InvoiceDao();
  final Map<String, Map<String, dynamic>?> _balances = {};

  void _loadBalances(Iterable<Customer> customers) {
    for (final c in customers) {
      if (!_balances.containsKey(c.id)) {
        _balances[c.id] = null; // placeholder while loading
        _invoiceDao.getClientBalance(c.id).then((data) {
          if (mounted) setState(() => _balances[c.id] = data);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceController = context.read<InvoiceController>();
    final customerController = context.watch<CustomerController>();
    final initialName = invoiceController.customerName ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Autocomplete<Customer>(
        initialValue: TextEditingValue(text: initialName),
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = textEditingValue.text.trim();
          if (query.isEmpty) return const Iterable.empty();
          final results = customerController.search(query);
          _loadBalances(results);
          return results;
        },
        displayStringForOption: (c) => c.name,
        fieldViewBuilder: (context, textCtrl, focusNode, onSubmitted) {
          return TextField(
            controller: textCtrl,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 15),
            onChanged: (v) => invoiceController.setCustomerName(v),
            decoration: InputDecoration(
              labelText: 'Customer *',
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              filled: true,
              fillColor: Theme.of(context).cardColor,
              suffixIcon: const Icon(Icons.arrow_drop_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: FMSons.accent,
                  width: 1.5,
                ),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          final customers = options.toList();
          _loadBalances(customers);

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header: "Showing Saved Parties" + "Add new party" ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Showing Saved Parties',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final customer = await showModalBottomSheet<Customer>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (builderContext) => Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(builderContext)
                                        .scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: const AddPartyFormSheet(),
                                ),
                              );
                              if (customer != null && mounted) {
                                // ignore: use_build_context_synchronously
                                Navigator.pop(context, customer);
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add new party',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: FMSons.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey.shade200),

                    // ── Customer list ──
                    Flexible(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: customers.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          final bal = _balances[customer.id];
                          final hasTransactions = bal != null &&
                              (bal['totalInvoiced'] as double) > 0;
                          final due = hasTransactions
                              ? normalizeMoney((bal['totalInvoiced'] as double) -
                                  (bal['totalReceived'] as double))
                              : 0.0;

                          return InkWell(
                            onTap: () => onSelected(customer),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // Name on the left
                                  Expanded(
                                    child: Text(
                                      customer.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Balance indicator on the right
                                  if (bal == null)
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: Colors.grey.shade400,
                                      ),
                                    )
                                  else if (due > 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 14,
                                          color: Colors.green.shade600,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Rs. ${due.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (due < 0)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 14,
                                          color: Colors.red.shade600,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'Rs. ${(-due).toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      'Settled',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        onSelected: (customer) {
          invoiceController.setCustomer(customer);
        },
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             TOTALS SECTION                                  */
/* -------------------------------------------------------------------------- */

class _TotalsSection extends StatefulWidget {
  @override
  State<_TotalsSection> createState() => _TotalsSectionState();
}

class _TotalsSectionState extends State<_TotalsSection> {
  late final TextEditingController _totalCtrl;
  late final TextEditingController _receivedCtrl;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<InvoiceController>();
    _totalCtrl = TextEditingController(
      text: ctrl.totalAmount > 0 ? ctrl.totalAmount.toStringAsFixed(0) : '',
    );
    _receivedCtrl = TextEditingController(
      text: ctrl.receivedAmount > 0
          ? ctrl.receivedAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    _receivedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final hasItems = controller.items.isNotEmpty;
    final total = controller.totalAmount;
    final balance = controller.balanceDue;
    final showExtras = total > 0;

    // When items exist, keep total field in sync (read-only, derived)
    if (hasItems) {
      final totalText = total > 0 ? total.toStringAsFixed(0) : '';
      if (_totalCtrl.text != totalText) {
        _totalCtrl.text = totalText;
      }
    }

    // Sync received field from controller state (toggle may change it)
    final receivedText = controller.receivedAmount > 0
        ? controller.receivedAmount.toStringAsFixed(0)
        : '';
    if (_receivedCtrl.text != receivedText) {
      _receivedCtrl.text = receivedText;
    }

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Total Amount row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _totalCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  readOnly: hasItems,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 0,
                    ),
                    border: InputBorder.none,
                    hintText: '─ ─ ─ ─ ─ ─',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                      letterSpacing: 2,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FMSons.accent,
                        width: 1,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FMSons.accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (v) {
                    if (!hasItems) {
                      controller.setManualTotal(double.tryParse(v) ?? 0);
                    }
                  },
                ),
              ),
            ],
          ),

          // Received + Balance — only when total > 0
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: showExtras
                ? Column(
                    children: [
                      // Received row — only on Credit (unpaid) and not Estimate
                      if (!controller.isEstimate &&
                          controller.paymentStatus == 'unpaid') ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (controller.receivedAmount > 0) {
                                  controller.setReceivedAmount(0);
                                } else {
                                  controller.setReceivedAmount(total);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: controller.receivedAmount > 0
                                      ? FMSons.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: FMSons.accent,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: controller.receivedAmount > 0
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Received',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rs',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextField(
                                controller: _receivedCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 0,
                                  ),
                                  border: InputBorder.none,
                                  hintText: '─ ─ ─ ─ ─ ─',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                    letterSpacing: 2,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FMSons.accent,
                                      width: 1,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FMSons.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (v) {
                                  controller.setReceivedAmount(
                                    double.tryParse(v) ?? 0,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade200, height: 1),
                        const SizedBox(height: 10),
                      ],
                      // Balance Due row — only for invoices
                      if (!controller.isEstimate)
                        Row(
                          children: [
                            const Text(
                              'Balance Due',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: FMSons.accent,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Rs',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              balance.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: FMSons.accent,
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                     CONDITIONAL EXTRAS (notes + doc)                       */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                     TERMS & CONDITIONS + CUSTOM NOTES                       */
/* -------------------------------------------------------------------------- */

class _TermsAndNotesSection extends StatefulWidget {
  const _TermsAndNotesSection();

  @override
  State<_TermsAndNotesSection> createState() => _TermsAndNotesSectionState();
}

class _TermsAndNotesSectionState extends State<_TermsAndNotesSection> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final total = controller.totalAmount;
    final show = total > 0;
    final selected = controller.selectedTermsCondition;

    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // ── Collapsible header: Terms & condition ──
          GestureDetector(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Terms & conditions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isOpen
                              ? FMSons.accent
                              : Colors.grey.shade700,
                        ),
                      ),
                      if (selected != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '— ${selected.title}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: _isOpen
                        ? FMSons.accent
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Collapsible body ──
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isOpen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // T&C field row
                      GestureDetector(
                        onTap: () => setState(() => _isOpen = !_isOpen),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: selected != null
                                    ? Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              selected.title,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF1E5EFF,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              selected.applicableFor.contains(
                                                    'invoice',
                                                  )
                                                  ? selected.applicableFor
                                                            .contains(
                                                              'estimate',
                                                            )
                                                        ? 'Both'
                                                        : 'Invoice'
                                                  : 'Estimate',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: FMSons.accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Select T&C',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey.shade500,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Inline dropdown
                      _buildDropdown(controller),

                      const SizedBox(height: 12),

                      // Custom Notes textarea
                      _CustomNotesField(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(InvoiceController controller) {
    final terms = controller.availableTerms;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "+ Add terms & condition" at top
          InkWell(
            onTap: () async {
              setState(() => _isOpen = false);
              final created = await Navigator.push<TermsCondition>(
                context,
                MaterialPageRoute(
                  builder: (_) => const TermsConditionEditorScreen(),
                ),
              );
              if (created != null && mounted) {
                controller.setSelectedTerms(created);
                controller.loadAvailableTerms();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline,
                    color: FMSons.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '+ Add terms & condition',
                    style: TextStyle(
                      color: FMSons.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (controller.selectedTermsId != null)
                    GestureDetector(
                      onTap: () {
                        controller.setSelectedTerms(null);
                        setState(() => _isOpen = false);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          if (terms.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No terms & conditions available.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            )
          else
            ...terms.map(
              (tc) => InkWell(
                onTap: () {
                  controller.setSelectedTerms(tc);
                  setState(() => _isOpen = false);
                },
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tc.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            if (tc.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                tc.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FMSons.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tc.applicableFor.contains('invoice')
                              ? tc.applicableFor.contains('estimate')
                                    ? 'Both'
                                    : 'Invoice'
                              : 'Estimate',
                          style: const TextStyle(
                            fontSize: 10,
                            color: FMSons.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          CUSTOM NOTES TEXTAREA                              */
/* -------------------------------------------------------------------------- */

class _CustomNotesField extends StatefulWidget {
  @override
  State<_CustomNotesField> createState() => _CustomNotesFieldState();
}

class _CustomNotesFieldState extends State<_CustomNotesField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: context.read<InvoiceController>().customNotes,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    // Sync text when controller changes (e.g. T&C selection pre-fills description)
    if (_ctrl.text != controller.customNotes) {
      _ctrl.text = controller.customNotes;
    }
    return Container(
      height: 80,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: null,
        expands: true,
        onChanged: context.read<InvoiceController>().setCustomNotes,
        decoration: InputDecoration(
          hintText: 'Additional notes / description',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                     CONDITIONAL EXTRAS (notes + doc)                       */
/* -------------------------------------------------------------------------- */

class _ConditionalExtrasSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = context.select<InvoiceController, double>(
      (c) => c.totalAmount,
    );
    final show = total > 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: show
          ? Column(
              children: const [
                SizedBox(height: 8),
                _InvoiceNotesSection(),
                SizedBox(height: 8),
                _DocumentSection(),
              ],
            )
          : const SizedBox.shrink(),
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
    _notesController = TextEditingController(
      text: context.read<InvoiceController>().notes,
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _showPickerOptions(InvoiceController controller) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                await controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageOptions(InvoiceController controller) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ImageViewerDialog(
        imagePath: controller.attachedImagePath!,
        onDelete: () {
          Navigator.pop(ctx);
          controller.clearAttachedImage();
        },
        onChange: () async {
          Navigator.pop(ctx);
          await _showPickerOptions(controller);
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final imagePath = controller.attachedImagePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notes field (left)
          Expanded(
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                onChanged: controller.setNotes,
                decoration: InputDecoration(
                  hintText: 'Add Note',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Image attach box (right)
          GestureDetector(
            onTap: () => imagePath == null
                ? _showPickerOptions(controller)
                : _showImageOptions(controller),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: imagePath != null
                  ? Image.file(File(imagePath), fit: BoxFit.cover)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 26,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Photo',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          DOCUMENT ATTACHMENT                               */
/* -------------------------------------------------------------------------- */

class _DocumentSection extends StatelessWidget {
  const _DocumentSection();

  Future<void> _pick(BuildContext context, InvoiceController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'jpg',
        'jpeg',
        'png',
      ],
    );
    if (result != null && result.files.single.path != null) {
      controller.setAttachedDoc(result.files.single.path!);
    }
  }

  void _openViewer(BuildContext context, InvoiceController controller) {
    showDialog(
      context: context,
      builder: (_) => _DocViewerDialog(
        docPath: controller.attachedDocPath!,
        onDelete: () {
          Navigator.pop(context);
          controller.clearAttachedDoc();
        },
        onChange: () async {
          Navigator.pop(context);
          await _pick(context, controller);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final docPath = controller.attachedDocPath;
    final fileName = docPath?.split('/').last.split('\\').last;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => docPath != null
            ? _openViewer(context, controller)
            : _pick(context, controller),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: docPath != null
              ? Row(
                  children: [
                    Icon(
                      _docIcon(fileName ?? ''),
                      size: 22,
                      color: FMSons.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName ?? 'Attached Document',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: FMSons.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.attach_file,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Add Document ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: FMSons.accent,
                            ),
                          ),
                          TextSpan(
                            text: '(PDF, Word, Excel…)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _docIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_outlined;
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

/* -------------------------------------------------------------------------- */
/*                       DOCUMENT VIEWER DIALOG                               */
/* -------------------------------------------------------------------------- */

class _DocViewerDialog extends StatelessWidget {
  final String docPath;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onClose;

  const _DocViewerDialog({
    required this.docPath,
    required this.onDelete,
    required this.onChange,
    required this.onClose,
  });

  bool get _isImage {
    final ext = docPath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(ext);
  }

  String get _fileName => docPath.split('/').last.split('\\').last;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      _fileName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: _isImage
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 6.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: Center(
                        child: Image.file(File(docPath), fit: BoxFit.contain),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_fileIcon(), size: 80, color: Colors.white54),
                          const SizedBox(height: 16),
                          Text(
                            _fileName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await OpenFilex.open(docPath);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open with…'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FMSons.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // Bottom action buttons
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: onDelete,
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz_outlined,
                    label: 'Change',
                    color: Colors.white,
                    onTap: onChange,
                  ),
                  _ActionButton(
                    icon: Icons.close,
                    label: 'Close',
                    color: Colors.white70,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon() {
    final ext = docPath.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

/* -------------------------------------------------------------------------- */
/*                         FIXED BOTTOM BAR                                   */
/* -------------------------------------------------------------------------- */

class _InvoiceBottomBar extends StatefulWidget {
  const _InvoiceBottomBar();

  @override
  State<_InvoiceBottomBar> createState() => _InvoiceBottomBarState();
}

class _InvoiceBottomBarState extends State<_InvoiceBottomBar> {
  bool _isSaving = false;
  bool _isSavingNew = false;

  static const _templateColors = {
    InvoiceThemeType.taxTheme1: Color(0xFF6C63FF),
    InvoiceThemeType.taxTheme3: Color(0xFF0D47A1),
    InvoiceThemeType.orangeEstimate: Color(0xFFFF5722),
    InvoiceThemeType.blueEstimate: Color(0xFF1976D2),
    InvoiceThemeType.govtTemplate: Color(0xFF1A7A1A),
    InvoiceThemeType.zaiqaTemplate: Color(0xFFCC0000),
  };

  static const _templateLabels = {
    InvoiceThemeType.taxTheme1: 'Tax 1',
    InvoiceThemeType.taxTheme3: 'Tax 3',
    InvoiceThemeType.orangeEstimate: 'Green',
    InvoiceThemeType.blueEstimate: 'Blue',
    InvoiceThemeType.govtTemplate: 'Govt',
    InvoiceThemeType.zaiqaTemplate: 'Zaiqa',
  };

  bool _validate(InvoiceController controller) {
    if ((controller.customerName ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer name is required')),
      );
      return false;
    }
    return true;
  }

  // Items are optional — invoice can be saved with just a customer and amount

  Future<void> _saveInvoice(
    InvoiceController controller, {
    bool andNew = false,
  }) async {
    if (_isSaving || _isSavingNew || !_validate(controller)) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final wasEditing = controller.isEditingInvoice;

    setState(() {
      if (andNew) {
        _isSavingNew = true;
      } else {
        _isSaving = true;
      }
    });
    try {
      final id = await controller.saveCurrentInvoice();
      if (!mounted) return;
      // Refresh customer list so newly-typed names appear in future dropdowns
      context.read<CustomerController>().refresh();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasEditing
                ? 'Invoice updated (ID: $id)'
                : 'Invoice saved (ID: $id)',
          ),
        ),
      );
      if (andNew) {
        await controller.resetDraft();
      } else {
        navigator.pop();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSavingNew = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();
    final selectedTheme = invoiceThemeFromId(controller.templateId);
    final busy = _isSaving || _isSavingNew || controller.isLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Template selector strip
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: InvoiceThemeType.values.map((type) {
                final color = _templateColors[type]!;
                final label = _templateLabels[type]!;
                final isSelected = type == selectedTheme;
                return GestureDetector(
                  onTap: () => context.read<InvoiceController>().setTemplateId(
                    type.name,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.1),
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

          const SizedBox(height: 8),

          // Save & New | Save | ⋮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Save & New
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        foregroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy
                          ? null
                          : () => _saveInvoice(controller, andNew: true),
                      child: _isSavingNew
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save & New',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Save (primary)
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FMSons.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: busy ? null : () => _saveInvoice(controller),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              controller.isEditingInvoice ? 'Update' : 'Save',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ⋮ More (preview)
                SizedBox(
                  height: 50,
                  width: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: busy
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
                    child: const Icon(Icons.more_horiz, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                         IMAGE VIEWER DIALOG                                 */
/* -------------------------------------------------------------------------- */

class _ImageViewerDialog extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onClose;

  const _ImageViewerDialog({
    required this.imagePath,
    required this.onDelete,
    required this.onChange,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Attached Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // Pinch-to-zoom image
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: Center(
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),

            // Bottom action buttons
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: onDelete,
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz_outlined,
                    label: 'Change',
                    color: Colors.white,
                    onTap: onChange,
                  ),
                  _ActionButton(
                    icon: Icons.close,
                    label: 'Close',
                    color: Colors.white70,
                    onTap: onClose,
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
