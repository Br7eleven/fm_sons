import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../controller/create_invoice_controller.dart';

class InvoiceHeader extends StatelessWidget {
  const InvoiceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvoiceController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Invoice No (Locked)
          Row(
            children: [
              Text(
                'Invoice No',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
              const Spacer(),
              Icon(
                Icons.lock,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Text(
              controller.invoiceNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 20),

          /// Invoice Date
          Text(
            'Invoice Date',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: controller.invoiceDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (pickedDate != null) {
                controller.updateInvoiceDate(pickedDate);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd MMM yyyy').format(controller.invoiceDate),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
