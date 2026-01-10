import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customer_controller.dart';
import 'customer_model.dart';
import 'customer_form_screen.dart';

class CustomerSelectorBottomSheet extends StatefulWidget {
  const CustomerSelectorBottomSheet({super.key});

  @override
  State<CustomerSelectorBottomSheet> createState() =>
      _CustomerSelectorBottomSheetState();
}

class _CustomerSelectorBottomSheetState
    extends State<CustomerSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerController = context.watch<CustomerController>();
    final query = _searchController.text;
    final customers = customerController.search(query);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () async {
                    final customer = await showModalBottomSheet<Customer>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) => const CustomerFormScreen(),
                    );

                    if (customer != null) {
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context, customer);
                    }
                  },
                  child: const Text('+ Add'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Search
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search customer',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Results
            if (customers.isEmpty && query.isNotEmpty)
              _AddTypedCustomerTile(name: query)
            else if (customers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No customers found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: customers.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return ListTile(
                      title: Text(customer.name),
                      onTap: () => Navigator.pop(context, customer),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                        ADD TYPED CUSTOMER TILE                              */
/* -------------------------------------------------------------------------- */

class _AddTypedCustomerTile extends StatelessWidget {
  final String name;

  const _AddTypedCustomerTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add),
      title: Text('Add "$name"'),
      onTap: () {
        Navigator.pop(context, Customer.temp(name));
      },
    );
  }
}
