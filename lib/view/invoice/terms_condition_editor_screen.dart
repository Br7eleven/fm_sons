import 'package:flutter/material.dart';
import 'package:fm_sons/data/local/dao/terms_condition_dao.dart';
import 'package:fm_sons/data/local/models/terms_condition_model.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

class TermsConditionEditorScreen extends StatefulWidget {
  const TermsConditionEditorScreen({super.key});

  @override
  State<TermsConditionEditorScreen> createState() =>
      _TermsConditionEditorScreenState();
}

class _TermsConditionEditorScreenState
    extends State<TermsConditionEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _forInvoice = true;
  bool _forEstimate = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return false;
    }
    if (!_forInvoice && !_forEstimate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select at least one applicable type')),
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final applicable = <String>[];
      if (_forInvoice) applicable.add('invoice');
      if (_forEstimate) applicable.add('estimate');

      final dao = TermsConditionDao();
      final now = DateTime.now();
      final tc = TermsCondition(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        applicableFor: applicable.join(','),
        createdAt: now,
      );

      final id = await dao.insert(tc);
      if (!mounted) return;

      final created = tc.copyWith(id: id);
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Terms & condition',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text('Header / title',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Standard Terms',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: FMSons.accent, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description
            const Text('Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _descCtrl,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter terms and conditions details…',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: FMSons.accent, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Applicable for
            const Text('Applicable for',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _forInvoice,
              onChanged: (v) => setState(() => _forInvoice = v ?? false),
              title: const Text('Invoices'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: FMSons.accent,
            ),
            CheckboxListTile(
              value: _forEstimate,
              onChanged: (v) => setState(() => _forEstimate = v ?? false),
              title: const Text('Estimates'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: FMSons.accent,
            ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FMSons.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
