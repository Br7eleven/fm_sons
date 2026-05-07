import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:provider/provider.dart';

import 'product_controller.dart';
import 'product_model.dart';
import 'product_form_screen.dart';

class ProductSelectorBottomSheet extends StatefulWidget {
  const ProductSelectorBottomSheet({super.key});

  @override
  State<ProductSelectorBottomSheet> createState() =>
      _ProductSelectorBottomSheetState();
}

class _ProductSelectorBottomSheetState
    extends State<ProductSelectorBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();

    final products = productController.products.where((product) {
      final query = _searchController.text.toLowerCase();
      return product.name.toLowerCase().contains(query);
    }).toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Drag Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: FMSons.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            /// Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                TextButton(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: FMSons.bgWhite,
                      builder: (_) => const ProductFormScreen(),
                    );
                  },
                  child: const Text(
                    '+ Add Product',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Search
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search product',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Product List
            if (productController.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (productController.hasError)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      productController.errorMessage ??
                          'Failed to load products',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => productController.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No products found',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductTile(
                      product: product,
                      onTap: () {
                        Navigator.pop(context, product);
                      },
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
/*                              PRODUCT TILE                                  */
/* -------------------------------------------------------------------------- */

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  Future<void> _openEditProduct(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductFormScreen(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _openEditProduct(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              /// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.unit.name} • ${product.type.name}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              /// Rate
              Text(
                'PKR ${product.defaultRate.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),

              const SizedBox(width: 4),

              /// Edit Button
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade600),
                onPressed: () => _openEditProduct(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit Product',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
