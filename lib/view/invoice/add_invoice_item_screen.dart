import 'package:flutter/material.dart';
import 'controller/create_invoice_controller.dart';
import 'widgets/calculation_card.dart';

class AddInvoiceItemScreen extends StatefulWidget {
  const AddInvoiceItemScreen({super.key});

  @override
  State<AddInvoiceItemScreen> createState() => _AddInvoiceItemScreenState();
}

class _AddInvoiceItemScreenState extends State<AddInvoiceItemScreen> {
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  String unit = 'Bag';

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Invoice Item'),
        leading: const CloseButton(),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                InvoiceItem(
                  name: 'Portland Cement (Grade 43)',
                  unit: unit,
                  quantity: qty,
                  rate: rate,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Product / Service'),
              controller: null,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: unit,
              items: const [
                DropdownMenuItem(value: 'Bag', child: Text('Bag')),
                DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                DropdownMenuItem(value: 'Meter', child: Text('Meter')),
                DropdownMenuItem(
                  value: 'Labor-Hour',
                  child: Text('Labor-Hour'),
                ),
              ],
              onChanged: (v) => setState(() => unit = v!),
              decoration: const InputDecoration(labelText: 'Unit of Measure'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate per Unit'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            CalculationCard(quantity: qty, rate: rate, unit: unit),
          ],
        ),
      ),
    );
  }
}
