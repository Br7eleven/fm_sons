import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customer_controller.dart';
import 'customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer; // null = add, not null = edit

  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );
    _addressController = TextEditingController(
      text: widget.customer?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerController = context.read<CustomerController>();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Title
              Center(
                child: Text(
                  isEdit ? 'Edit Customer' : 'Add Customer',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _label('Customer Name'),
              TextFormField(
                controller: _nameController,
                decoration: _input('Enter customer name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              _label('Phone (optional)'),
              TextFormField(
                controller: _phoneController,
                decoration: _input('Phone number'),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              _label('Address (optional)'),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: _input('Address'),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;

                    final customer = Customer(
                      id: isEdit
                          ? widget.customer!.id
                          : DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim(),
                      address: _addressController.text.trim().isEmpty
                          ? null
                          : _addressController.text.trim(),
                    );

                    final saved = isEdit
                        ? customer
                        : customerController.addOrGetCustomer(customer);

                    Navigator.pop(context, saved);
                  },
                  child: Text(
                    isEdit ? 'Update Customer' : 'Save Customer',
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

  /* -------------------------------------------------------------------------- */
  /*                                  HELPERS                                   */
  /* -------------------------------------------------------------------------- */

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey));

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
