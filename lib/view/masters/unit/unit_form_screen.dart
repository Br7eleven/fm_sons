import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
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
  bool _isSubmitting = false;

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
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return 'Required';
                    if (text.length < 2) return 'Enter at least 2 characters';
                    return null;
                  },
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
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return 'Required';
                    final isValid = RegExp(
                      r'^[a-zA-Z0-9_-]{1,10}$',
                    ).hasMatch(text);
                    if (!isValid) {
                      return 'Use 1-10 letters/numbers (_,- allowed)';
                    }
                    return null;
                  },
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
              backgroundColor: FMSons.accent,
              foregroundColor: FMSons.bgWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(
              _isSubmitting
                  ? 'Saving...'
                  : (isEdit ? 'Update Unit' : 'Save Unit'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed: _isSubmitting ? null : () => _save(controller),
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
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
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _save(UnitController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    setState(() => _isSubmitting = true);

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
        await controller.updateUnit(unit);
      } else {
        await controller.addUnit(unit);
      }

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Failed to save unit: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
