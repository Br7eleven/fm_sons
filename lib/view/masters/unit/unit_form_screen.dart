import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'unit_controller.dart';
import 'unit_model.dart';

class UnitFormScreen extends StatefulWidget {
  final Unit? unit; // null = add, non-null = edit

  const UnitFormScreen({super.key, this.unit});

  @override
  State<UnitFormScreen> createState() => _UnitFormScreenState();
}

class _UnitFormScreenState extends State<UnitFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _descriptionController;

  bool _allowDecimal = false;

  bool get isEdit => widget.unit != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _symbolController = TextEditingController(text: widget.unit?.symbol ?? '');
    _descriptionController = TextEditingController(
      text: widget.unit?.description ?? '',
    );

    _allowDecimal = widget.unit?.allowDecimal ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<UnitController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Unit' : 'Add Unit',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// Unit Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Unit Name',
                  hintText: 'e.g. Bag, Kg, RFT',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unit name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Symbol
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Symbol',
                  hintText: 'e.g. bag, kg, rft',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Symbol is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Allow Decimal
              SwitchListTile(
                title: const Text('Allow Decimal Quantity'),
                subtitle: const Text(
                  'Enable for units like Kg, RFT, SqFt, Cum',
                ),
                value: _allowDecimal,
                onChanged: (value) {
                  setState(() => _allowDecimal = value);
                },
              ),

              const SizedBox(height: 16),

              /// Description (optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Any clarification or govt note',
                ),
              ),

              const Spacer(),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    final unit = Unit(
                      id: isEdit
                          ? widget.unit!.id
                          : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      symbol: _symbolController.text.trim(),
                      allowDecimal: _allowDecimal,
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                    );

                    try {
                      if (isEdit) {
                        controller.updateUnit(unit);
                      } else {
                        controller.addUnit(unit);
                      }

                      Navigator.pop(context);
                    } catch (e) {
                      _showError(context, e.toString());
                    }
                  },
                  child: Text(
                    isEdit ? 'Update Unit' : 'Save Unit',
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
