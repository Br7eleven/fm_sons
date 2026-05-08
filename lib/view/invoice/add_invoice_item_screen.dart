import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/masters/product/product_controller.dart';
import 'package:fm_sons/view/masters/product/product_selector_bottom_sheet.dart';
import 'package:fm_sons/view/masters/product/product_model.dart';
import 'package:fm_sons/view/masters/unit/unit_controller.dart';
import 'package:fm_sons/view/masters/unit/unit_model.dart';
import 'package:provider/provider.dart';
import '.././masters/unit/unit_form_screen.dart';
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

  // TEMP: mocked product & unit (until masters exist)
  // final String _selectedProduct = 'Portland Cement (Grade 43)';
  Product? _selectedProduct;

  Unit? _selectedUnit;

  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialItem = widget.initialItem;
    if (initialItem == null) return;

    final productController = context.read<ProductController>();
    final unitController = context.read<UnitController>();
    final units = unitController.units;

    _selectedProduct = initialItem.productId == null
        ? null
        : productController.getById(initialItem.productId!);

    _selectedUnit = initialItem.unitId == null
        ? null
        : unitController.getUnitById(initialItem.unitId!);
    _selectedUnit ??= _selectedProduct?.unit;
    if (_selectedUnit == null) {
      for (final unit in units) {
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
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    final unitController = context.watch<UnitController>();
    final units = unitController.units;

    final qty = double.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = qty * rate;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.isEditing ? 'Edit Invoice Item' : 'Add Invoice Item',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            // child: Center(
            //   child: Text(
            //     'Save',
            //     style: TextStyle(
            //       color: Color(0xFF1E5EFF),
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
          ),
        ],
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
                    /// Product / Service
                    const Text(
                      'Product / Service',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    // _selectorField(_selectedProduct),
                    _selectorField(
                      _selectedProduct?.name ??
                          widget.initialItem?.name ??
                          'Select Product',
                      onTap: () async {
                        final product = await showModalBottomSheet<Product>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const ProductSelectorBottomSheet(),
                        );

                        if (product != null) {
                          setState(() {
                            _selectedProduct = product;
                            _selectedUnit = product.unit;
                            _rateController.text = product.defaultRate
                                .toStringAsFixed(2);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 20),

                    /// Unit of Measure
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     const Text(
                    //       'Unit of Measure',
                    //       style: TextStyle(fontSize: 13, color: Colors.grey),
                    //     ),
                    //     InkWell(
                    //       onTap: () async {
                    //         await Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (_) => const UnitFormScreen(),
                    //           ),
                    //         );
                    //         // No setState needed — Provider will auto-update
                    //       },
                    //       child: const Text(
                    //         '+ Custom',
                    //         style: TextStyle(
                    //           fontSize: 13,
                    //           color: Color(0xFF1E5EFF),
                    //           fontWeight: FontWeight.w500,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 4,
                      children: units.map((unit) {
                        return GestureDetector(
                          onLongPress: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UnitFormScreen(unit: unit),
                              ),
                            );
                          },
                          child: ChoiceChip(
                            label: Text(unit.name),
                            selected: _selectedUnit?.id == unit.id,
                            onSelected: (_) {
                              setState(() => _selectedUnit = unit);
                            },
                          ),
                        );
                      }).toList(),
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
                            prefix: 'PKR ',
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
                            _selectedProduct == null
                                ? '-'
                                : '$qty ${_selectedUnit?.name ?? _selectedProduct!.unit.name} × PKR ${rate.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PKR ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
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
                    widget.isEditing ? 'Save Item' : 'Add to Invoice',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5EFF),
                    foregroundColor: FMSons.bgWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (_selectedProduct == null && !widget.isEditing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a product first'),
                        ),
                      );
                      return;
                    }

                    if (_selectedUnit == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a unit for this item'),
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

                    final initialItem = widget.initialItem;
                    final item = InvoiceItem(
                      productId: _selectedProduct?.id ?? initialItem?.productId,
                      name: _selectedProduct?.name ?? initialItem!.name,
                      unitId: _selectedUnit!.id,
                      unit: _selectedUnit!.name,
                      quantity: qty,
                      rate: rate,
                    );

                    if (widget.isEditing) {
                      controller.updateItem(widget.itemIndex!, item);
                    } else {
                      controller.addItem(item);
                    }
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- small helpers (UI only) ---

  Widget _selectorField(String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value)),
            Icon(Icons.expand_more, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    required VoidCallback onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          validator: validator,
          decoration: InputDecoration(
            prefixText: prefix,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
      ],
    );
  }
}
