import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/masters/unit/unit_controller.dart';
import 'package:fm_sons/view/masters/unit/unit_model.dart';
import 'package:fm_sons/view/shared/app_dialog.dart';
import 'package:fm_sons/view/shared/field_decoration.dart';
import 'package:provider/provider.dart';

class UnitSelectionBottomSheet extends StatefulWidget {
  const UnitSelectionBottomSheet({super.key});

  @override
  State<UnitSelectionBottomSheet> createState() =>
      _UnitSelectionBottomSheetState();
}

class _UnitSelectionBottomSheetState extends State<UnitSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addNewUnit() async {
    final nameCtrl = TextEditingController();
    final symbolCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newUnit = await showDialog<Unit?>(
      context: context,
      builder: (ctx) {
        final unitController = ctx.read<UnitController>();
        final navigator = Navigator.of(ctx);
        return AppDialog(
          title: 'Add New Unit',
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: appInputDecoration(
                    ctx,
                    'Unit Name',
                  ).copyWith(hintText: 'e.g. Bag, Kg, RFT'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Required';
                    if (t.length < 2) return 'At least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: symbolCtrl,
                  decoration: appInputDecoration(
                    ctx,
                    'Short Name',
                  ).copyWith(hintText: 'e.g. bag, kg, rft'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Required';
                    if (!RegExp(r'^[a-zA-Z0-9_-]{1,10}$').hasMatch(t)) {
                      return 'Use 1-10 letters/numbers (_,- allowed)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            dialogTextButton(label: 'Cancel', onPressed: () => navigator.pop()),
            dialogPrimaryButton(
              label: 'Save',
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final unit = Unit(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  symbol: symbolCtrl.text.trim(),
                  allowDecimal: false,
                );
                try {
                  await unitController.addUnit(unit);
                  if (!mounted) return;
                  navigator.pop(unit);
                } catch (e) {
                  if (!ctx.mounted) return;
                  showAppSnackBar(
                    ctx, 'Failed to add unit: $e', isError: true);
                }
              },
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    symbolCtrl.dispose();

    if (newUnit != null && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pop(context, newUnit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unitController = context.watch<UnitController>();
    final query = _searchController.text.toLowerCase();
    final units = query.isEmpty
        ? unitController.units
        : unitController.units
            .where((u) => u.name.toLowerCase().contains(query))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Drag handle (at very top of sheet, not inside the ListView)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              /// Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Select Unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              /// Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search for a Unit',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: FMSons.accent),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// Results
              Expanded(
                child: units.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: units.length + 2,
                        separatorBuilder: (_, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            /// No Unit / Skip option
                            return InkWell(
                              onTap: () => Navigator.pop(context, null),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 20,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'No Unit (Service)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          if (index == 1) {
                            /// Add New Unit tile (pinned at top of list)
                            return InkWell(
                              onTap: _addNewUnit,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 20,
                                      color: FMSons.accent,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Add New Unit',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: FMSons.accent,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final unit = units[index - 2];
                          return InkWell(
                            onTap: () => Navigator.pop(context, unit),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 4,
                              ),
                              child: Text(
                                '${unit.name} (${unit.symbol})',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final unitController = context.watch<UnitController>();

    if (unitController.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      );
    }

    if (unitController.hasError) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              unitController.errorMessage ?? 'Failed to load units',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => unitController.refresh(),
              style: ElevatedButton.styleFrom(
                backgroundColor: FMSons.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.straighten_outlined,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            'No units found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a new unit to get started',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}