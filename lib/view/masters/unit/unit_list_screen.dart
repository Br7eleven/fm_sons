import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:provider/provider.dart';

import 'unit_controller.dart';
import 'unit_model.dart';
import 'unit_form_screen.dart';

class UnitListScreen extends StatelessWidget {
  const UnitListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UnitController>();
    final units = controller.units;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Units of Measure',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.hasError
          ? _ErrorState(
              message: controller.errorMessage ?? 'Failed to load units',
              onRetry: () => controller.refresh(),
            )
          : units.isEmpty
          ? _EmptyState(onAdd: () => _openAdd(context))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: units.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _UnitTile(unit: units[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnitFormScreen()),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               UNIT TILE                                    */
/* -------------------------------------------------------------------------- */

class _UnitTile extends StatelessWidget {
  final Unit unit;

  const _UnitTile({required this.unit});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<UnitController>();

    return GestureDetector(
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UnitFormScreen(unit: unit)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            /// Unit Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unit.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Symbol: ${unit.symbol} • '
                    '${unit.allowDecimal ? 'Decimals allowed' : 'No decimals'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            /// Edit (still works on tap)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UnitFormScreen(unit: unit)),
                );
              },
            ),

            /// Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                try {
                  await controller.removeUnit(unit.id);
                } catch (e) {
                  if (!context.mounted) return;
                  showAppSnackBar(context, e.toString(), isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               EMPTY STATE                                  */
/* -------------------------------------------------------------------------- */

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.straighten, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No units defined',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add units like Bag, Kg, RFT, Day before creating products.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAdd, child: const Text('Add Unit')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
