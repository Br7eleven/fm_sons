import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fm_sons/utils/app_snackbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'company_profile_controller.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _vendorNumber;

  @override
  void initState() {
    super.initState();
    final cp = context.read<CompanyProfileController>();
    _name = TextEditingController(text: cp.name);
    _tagline = TextEditingController(text: cp.tagline);
    _email = TextEditingController(text: cp.email);
    _phone = TextEditingController(text: cp.phone);
    _address = TextEditingController(text: cp.address);
    _vendorNumber = TextEditingController(text: cp.vendorNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _vendorNumber.dispose();
    super.dispose();
  }

  Future<void> _pickSignature() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      // No size limit — preserve full signature quality
      final picked = await picker.pickImage(source: source, imageQuality: 90);
      if (picked == null || !mounted) return;
      await context.read<CompanyProfileController>().setSignaturePath(picked.path);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Could not pick image: $e', isError: true);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      await context.read<CompanyProfileController>().setLogoPath(picked.path);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Could not pick image: $e', isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<CompanyProfileController>().save(
        name: _name.text,
        tagline: _tagline.text,
        email: _email.text,
        phone: _phone.text,
        address: _address.text,
        vendorNumber: _vendorNumber.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CompanyProfileController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Company Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// Logo avatar
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                      backgroundImage: cp.logoPath != null
                          ? FileImage(File(cp.logoPath!))
                          : null,
                      child: cp.logoPath == null
                          ? Text(
                              _initials(cp.name),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E3A8A),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E3A8A),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Tap to change logo',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _field(
              controller: _name,
              label: 'Company Name',
              hint: 'e.g. FM Sons',
              required: true,
            ),
            _field(
              controller: _tagline,
              label: 'Tagline / Business Type',
              hint: 'e.g. Government Contractor',
            ),
            _field(
              controller: _email,
              label: 'Email',
              hint: 'e.g. fmsons514@gmail.com',
              keyboard: TextInputType.emailAddress,
            ),
            _field(
              controller: _phone,
              label: 'Phone',
              hint: 'e.g. 0312-4115209',
              keyboard: TextInputType.phone,
            ),
            _field(
              controller: _address,
              label: 'Address',
              hint: 'Full business address',
              maxLines: 2,
            ),
            _field(
              controller: _vendorNumber,
              label: 'Vendor Number',
              hint: 'e.g. 30140988',
            ),
            const SizedBox(height: 8),
            _SignaturePicker(onTap: _pickSignature),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(
              _saving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'FM';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            decoration: InputDecoration(
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
                borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
              ),
            ),
            validator: required
                ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────────────────────────────── */
/*                         SIGNATURE PICKER WIDGET                        */
/* ─────────────────────────────────────────────────────────────────────── */

class _SignaturePicker extends StatelessWidget {
  final VoidCallback onTap;
  const _SignaturePicker({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CompanyProfileController>();
    final sigPath = cp.signaturePath;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF1E3A8A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Signature',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 110,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sigPath != null ? primary.withValues(alpha: 0.4) : Theme.of(context).dividerColor,
                  width: sigPath != null ? 1.5 : 1,
                ),
              ),
              child: sigPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(
                        File(sigPath),
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.draw_outlined, size: 32, color: primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add signature',
                          style: TextStyle(
                            fontSize: 13,
                            color: primary.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG, WEBP supported',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (sigPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton.icon(
                onPressed: onTap,
                icon: Icon(Icons.refresh, size: 16, color: primary),
                label: Text('Change Signature', style: TextStyle(fontSize: 12, color: primary)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
