import 'package:flutter/material.dart';
import '../controller/create_invoice_controller.dart';

class BillableItemTile extends StatelessWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;

  const BillableItemTile({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text('${item.quantity} ${item.unit} × \$${item.rate}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
