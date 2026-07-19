import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
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
  bool _isSubmitting = false;

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
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Title
              Center(
                child: Text(
                  isEdit ? 'Edit Customer' : 'Add Customer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Customer Name
              _label(context, 'Customer Name'),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(context, 'Enter customer name'),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Required';
                  if (text.length < 2) return 'Enter at least 2 characters';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Phone
              _label(context, 'Phone (optional)'),
              TextFormField(
                controller: _phoneController,
                decoration: _inputDecoration(context, 'Phone number'),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return null;

                  final normalized = text.replaceAll(RegExp(r'\s+'), '');
                  final isValid = RegExp(
                    r'^[+]?[0-9]{7,15}$',
                  ).hasMatch(normalized);
                  if (!isValid) return 'Enter a valid phone number';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Address
              _label(context, 'Address (optional)'),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: _inputDecoration(context, 'Enter customer address'),
              ),

              const SizedBox(height: 24),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final navigator = Navigator.of(context);

                          setState(() => _isSubmitting = true);

                          final customer = Customer(
                            id: isEdit
                                ? widget.customer!.id
                                : DateTime.now().millisecondsSinceEpoch
                                      .toString(),
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim().isEmpty
                                ? null
                                : _phoneController.text.trim(),
                            address: _addressController.text.trim().isEmpty
                                ? null
                                : _addressController.text.trim(),
                          );

                          try {
                            final saved = isEdit
                                ? (await customerController
                                      .updateCustomer(customer)
                                      .then((_) => customer))
                                : await customerController.addOrGetCustomer(
                                    customer,
                                  );

                            if (!mounted) return;
                            navigator.pop(saved);
                          } catch (e) {
                            if (!mounted) return;
                            showAppSnackBar(
                              this.context,
                              'Failed to save customer: $e',
                              isError: true,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
