import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/masters/unit/unit_form_screen.dart';
import 'package:provider/provider.dart';

import '../unit/unit_controller.dart';
import '../unit/unit_model.dart';
import 'product_controller.dart';
import 'product_model.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = add, not null = edit

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  late TextEditingController _nameController;
  late TextEditingController _rateController;
  late TextEditingController _descriptionController;

  ProductType _type = ProductType.material;
  Unit? _selectedUnit;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _rateController = TextEditingController(
      text: widget.product?.defaultRate.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );

    _type = widget.product?.type ?? ProductType.material;
    _selectedUnit = widget.product?.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitController = context.watch<UnitController>();
    final productController = context.read<ProductController>();
    final units = unitController.units;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: FMSons.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Title
              Center(
                child: Text(
                  isEdit ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: FMSons.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Product Name
              _label('Product Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter product name'),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Required';
                  if (text.length < 2) return 'Enter at least 2 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Product Type
              _label('Product Type'),
              Row(
                children: [
                  _typeChip(ProductType.material, 'Material'),
                  const SizedBox(width: 12),
                  _typeChip(ProductType.service, 'Service'),
                ],
              ),

              const SizedBox(height: 16),

              /// Unit
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Unit of Measure'),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const UnitFormScreen(), //navigates to unit add screen
                        ),
                      );
                    },
                    child: const Text(
                      '+ Custom',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1E5EFF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              DropdownButtonFormField<String>(
                initialValue: _selectedUnit?.id,
                items: units
                    .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.name),
                        ))
                    .toList(),
                onChanged: (unitId) {
                  if (unitId != null) {
                    setState(() {
                      _selectedUnit = units.firstWhere((u) => u.id == unitId);
                    });
                  }
                },
                decoration: _inputDecoration('Select unit'),
                validator: (v) => v == null ? 'Unit required' : null,
              ),

              const SizedBox(height: 16),

              /// Default Rate
              _label('Default Rate'),
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('0.00'),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Required';
                  final parsed = double.tryParse(text);
                  if (parsed == null) return 'Invalid number';
                  if (parsed <= 0) return 'Must be greater than zero';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Description
              _label('Description (optional)'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration('Notes or remarks'),
              ),

              const SizedBox(height: 24),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: FMSons.bgWhite,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);

                          setState(() => _isSubmitting = true);

                          final product = Product(
                            id: isEdit
                                ? widget.product!.id
                                : DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                            name: _nameController.text.trim(),
                            type: _type,
                            unit: _selectedUnit!,
                            defaultRate: double.parse(
                              _rateController.text.trim(),
                            ),
                            description:
                                _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                          );

                          try {
                            if (isEdit) {
                              await productController.updateProduct(product);
                            } else {
                              await productController.addProduct(product);
                            }
                            if (!mounted) return;
                            navigator.pop();
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to save product: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEdit ? 'Update Product' : 'Save Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helpers

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: FMSons.textPrimary),
    );
  }

  Widget _typeChip(ProductType type, String label) {
    final selected = _type == type;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = type),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E5EFF)),
      ),
    );
  }
}
