import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/shared/field_decoration.dart';
import 'package:fm_sons/view/masters/product/product_controller.dart';
import 'package:fm_sons/view/masters/product/product_form_screen.dart';
import 'package:fm_sons/view/masters/product/product_model.dart';
import 'package:fm_sons/view/masters/unit/unit_controller.dart';
import 'package:fm_sons/view/masters/unit/unit_model.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/view/invoice/widgets/unit_selection_bottom_sheet.dart';
import 'controller/create_invoice_controller.dart';

class AddInvoiceItemScreen extends StatefulWidget {
  final int? itemIndex;
  final InvoiceItem? initialItem;

  const AddInvoiceItemScreen({super.key, this.itemIndex, this.initialItem});

  bool get isEditing => itemIndex != null && initialItem != null;

  @override
  State<AddInvoiceItemScreen> createState() => _AddInvoiceItemScreenState();
}

class _AddInvoiceItemScreenState extends State<AddInvoiceItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  Product? _matchedProduct;
  Unit? _selectedUnit;

  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameFocus.addListener(() => setState(() {}));

    final initialItem = widget.initialItem;
    if (initialItem == null) return;

    final productController = context.read<ProductController>();
    final unitController = context.read<UnitController>();

    _matchedProduct = initialItem.productId == null
        ? null
        : productController.getById(initialItem.productId!);
    _nameController.text = initialItem.name;

    _selectedUnit = initialItem.unitId == null
        ? null
        : unitController.getUnitById(initialItem.unitId!);
    _selectedUnit ??= _matchedProduct?.unit;
    if (_selectedUnit == null) {
      for (final unit in unitController.units) {
        if (unit.name.toLowerCase() == initialItem.unit.toLowerCase()) {
          _selectedUnit = unit;
          break;
        }
      }
    }
    _qtyController.text = initialItem.quantity.toString();
    _rateController.text = initialItem.rate.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  List<Product> get _productMatches {
    final q = _nameController.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return context
        .read<ProductController>()
        .products
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = qty * rate;

    final showNameSuggestions =
        _nameFocus.hasFocus && _nameController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.isEditing ? 'Edit Invoice Item' : 'Add Invoice Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            /// Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Item Name (inline autocomplete)
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      decoration: appInputDecoration(context, 'Item Name'),
                      onChanged: (_) => setState(() {}),
                      onTap: () => setState(() {}),
                    ),
                    if (showNameSuggestions) _productSuggestions(),

                    const SizedBox(height: 20),

                    /// Unit of Measure (bottom sheet selector)
                    InkWell(
                      onTap: () async {
                        final unit = await showModalBottomSheet<Unit>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const UnitSelectionBottomSheet(),
                        );
                        if (mounted) {
                          setState(() => _selectedUnit = unit);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedUnit?.symbol ?? 'Unit of Measure',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedUnit != null
                                      ? Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Quantity & Rate
                    Row(
                      children: [
                        Expanded(
                          child: _labeledField(
                            label: 'Quantity',
                            controller: _qtyController,
                            onChanged: () => setState(() {}),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Required';
                              final parsed = double.tryParse(text);
                              if (parsed == null) return 'Invalid number';
                              if (parsed <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _labeledField(
                            label: 'Rate per Unit',
                            controller: _rateController,
                            prefix: 'Rs ',
                            onChanged: () => setState(() {}),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Required';
                              final parsed = double.tryParse(text);
                              if (parsed == null) return 'Invalid number';
                              if (parsed < 0) return 'Cannot be negative';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Calculation
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calculation',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedUnit == null
                                ? '-'
                                : '$qty ${_selectedUnit!.symbol} × Rs ${rate.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rs ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: FMSons.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: Icon(
                    widget.isEditing ? Icons.save_outlined : Icons.add,
                  ),
                  label: Text(
                    widget.isEditing ? 'Save Item' : 'Add item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FMSons.accent,
                    foregroundColor: FMSons.bgWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an item name'),
                        ),
                      );
                      return;
                    }

                    if (!_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fix invalid quantity/rate values',
                          ),
                        ),
                      );
                      return;
                    }

                    final rate = double.tryParse(_rateController.text) ?? 0;

                    // Resolve product id:
                    // 1) currently matched product (if its name still matches)
                    // 2) exact (case-insensitive, trimmed) existing match
                    // 3) soft auto-create
                    final key = name.toLowerCase();
                    final matched =
                        _matchedProduct != null &&
                            _matchedProduct!.name.trim().toLowerCase() == key
                        ? _matchedProduct
                        : null;

                    String? productId = matched?.id;
                    if (productId == null) {
                      final existing = context
                          .read<ProductController>()
                          .products
                          .where((p) => p.name.trim().toLowerCase() == key)
                          .toList();
                      if (existing.isNotEmpty) {
                        productId = existing.first.id;
                        _matchedProduct = existing.first;
                      }
                    }

                    if (productId == null && _selectedUnit != null) {
                      final created = await context
                          .read<ProductController>()
                          .ensureProductByName(name, _selectedUnit!, rate);
                      productId = created?.id;
                      _matchedProduct = created ?? _matchedProduct;
                    }

                    final item = InvoiceItem(
                      productId: productId,
                      name: name,
                      unitId: _selectedUnit?.id,
                      unit: _selectedUnit?.symbol ?? '',
                      quantity: double.tryParse(_qtyController.text) ?? 0,
                      rate: rate,
                    );

                    if (widget.isEditing) {
                      controller.updateItem(widget.itemIndex!, item);
                    } else {
                      controller.addItem(item);
                    }
                    if (!mounted) return;
                    navigator.pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* --------------------------- product suggestions -------------------------- */

  Widget _productSuggestions() {
    final matches = _productMatches;
    final query = _nameController.text.trim();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: FMSons.accent),
            title: Text(
              query.isEmpty ? 'Add New Item' : 'Add New Item: "$query"',
            ),
            onTap: () async {
              _nameFocus.unfocus();
              final productController = context.read<ProductController>();
              final typed = _nameController.text.trim();
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ProductFormScreen(initialName: typed),
              );
              if (!mounted) return;
              // Select the product that was just created (by name).
              final created = productController.products
                  .where(
                    (p) => p.name.trim().toLowerCase() == typed.toLowerCase(),
                  )
                  .toList();
              if (created.isNotEmpty) {
                setState(() {
                  _matchedProduct = created.first;
                  _nameController.text = created.first.name;
                  _selectedUnit = created.first.unit;
                  _rateController.text = created.first.defaultRate
                      .toStringAsFixed(2);
                });
              }
            },
          ),
          if (matches.isNotEmpty) const Divider(height: 1),
          ...matches.map(
            (product) => ListTile(
              title: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(product.unit.name),
              trailing: Text(
                'Rs ${product.defaultRate.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                _nameFocus.unfocus();
                setState(() {
                  _matchedProduct = product;
                  _nameController.text = product.name;
                  _selectedUnit = product.unit;
                  _rateController.text = product.defaultRate.toStringAsFixed(2);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /* ------------------------------- helpers --------------------------------- */

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    required VoidCallback onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => onChanged(),
      validator: validator,
      decoration: appInputDecoration(
        context,
        label,
      ).copyWith(prefixText: prefix),
    );
  }
}
