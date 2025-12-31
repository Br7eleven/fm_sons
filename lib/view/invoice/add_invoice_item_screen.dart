import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';

import 'controller/create_invoice_controller.dart';

class AddInvoiceItemScreen extends StatefulWidget {
  const AddInvoiceItemScreen({super.key});

  @override
  State<AddInvoiceItemScreen> createState() => _AddInvoiceItemScreenState();
}

class _AddInvoiceItemScreenState extends State<AddInvoiceItemScreen> {
  // TEMP: mocked product & unit (until masters exist)
  final String _selectedProduct = 'Portland Cement (Grade 43)';
  String _selectedUnit = 'Bag';

  final _qtyController = TextEditingController(text: '1');
  final _rateController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = qty * rate;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Add Invoice Item',
          style: TextStyle(fontWeight: FontWeight.w600),
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
      body: Column(
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
                  _selectorField(_selectedProduct),

                  const SizedBox(height: 20),

                  /// Unit of Measure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Unit of Measure',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        '+ Custom',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E5EFF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: ['Bag', 'Kg', 'Meter', 'Labor-Hour']
                        .map(
                          (unit) => ChoiceChip(
                            label: Text(unit),
                            selected: _selectedUnit == unit,
                            onSelected: (_) {
                              setState(() => _selectedUnit = unit);
                            },
                          ),
                        )
                        .toList(),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _labeledField(
                          label: 'Rate per Unit',
                          controller: _rateController,
                          prefix: '\$ ',
                          onChanged: () => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// Calculation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calculation',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$qty $_selectedUnit × \$${rate.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
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
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add to Invoice',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5EFF),
                  foregroundColor: FMSons.bgWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  controller.addItem(
                    InvoiceItem(
                      name: _selectedProduct,
                      unit: _selectedUnit,
                      quantity: qty,
                      rate: rate,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- small helpers (UI only) ---

  Widget _selectorField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(child: Text(value)),
          Icon(Icons.expand_more, color: Colors.grey.shade600),
        ],
      ),
    );
  }

  Widget _labeledField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            prefixText: prefix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
