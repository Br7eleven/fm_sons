import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';

import 'unit_controller.dart';
import 'unit_model.dart';

class UnitFormScreen extends StatefulWidget {
  final Unit? unit;

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
  Widget build(BuildContext context) {
    final controller = context.read<UnitController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEdit ? 'Edit Unit' : 'Add Unit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // TextButton(
          //   onPressed: () => _save(controller),
          //   child: const Text(
          //     'Save',
          //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          //   ),
          // ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _card(
                title: 'Unit Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Bag, Kg, RFT',
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),

              const SizedBox(height: 16),

              _card(
                title: 'Symbol',
                child: TextFormField(
                  controller: _symbolController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. bag, kg, rft',
                    border: InputBorder.none,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),

              const SizedBox(height: 16),

              _card(
                title: 'Quantity Rules',
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Decimal Quantity'),
                  subtitle: const Text('Enable for Kg, RFT, SqFt, Cum'),
                  value: _allowDecimal,
                  onChanged: (v) => setState(() => _allowDecimal = v),
                ),
              ),

              const SizedBox(height: 16),

              _card(
                title: 'Description',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Govt notes or clarification (optional)',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      /// Bottom Button (same style as Add to Invoice)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5EFF),
              foregroundColor: FMSons.bgWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              isEdit ? 'Update Unit' : 'Save Unit',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _save(controller),
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  void _save(UnitController controller) {
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

    isEdit ? controller.updateUnit(unit) : controller.addUnit(unit);
    Navigator.pop(context);
  }
}
