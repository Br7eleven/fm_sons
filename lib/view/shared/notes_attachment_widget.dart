import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Reusable notes field + photo attachment widget.
/// Mirrors the pattern from Sale/Invoice screen but as a self-contained component.
/// When [editable] is false, all fields are read-only and non-interactive.
class NotesAttachmentWidget extends StatefulWidget {
  final String notes;
  final String? attachedImagePath;
  final ValueChanged<String> onNotesChanged;
  final ValueChanged<String?> onImageChanged;
  final bool editable;

  const NotesAttachmentWidget({
    super.key,
    required this.notes,
    this.attachedImagePath,
    required this.onNotesChanged,
    required this.onImageChanged,
    this.editable = true,
  });

  @override
  State<NotesAttachmentWidget> createState() => _NotesAttachmentWidgetState();
}

class _NotesAttachmentWidgetState extends State<NotesAttachmentWidget> {
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(NotesAttachmentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notes != oldWidget.notes && widget.notes != _notesCtrl.text) {
      _notesCtrl.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _showPickerOptions() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      widget.onImageChanged(file.path);
    }
  }

  Future<void> _showImageOptions() async {
    await showDialog(
      context: context,
      builder: (ctx) => _ImageViewerDialog(
        imagePath: widget.attachedImagePath!,
        onDelete: () {
          Navigator.pop(ctx);
          widget.onImageChanged(null);
        },
        onChange: () async {
          Navigator.pop(ctx);
          await _showPickerOptions();
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.attachedImagePath;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Notes field (left)
        Expanded(
          child: Container(
            height: 80,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _notesCtrl,
              maxLines: null,
              expands: true,
              readOnly: !widget.editable,
              onChanged: widget.editable ? widget.onNotesChanged : null,
              decoration: InputDecoration(
                hintText: 'Add Note',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Image attach box (right)
        GestureDetector(
          onTap: widget.editable
              ? (imagePath == null
                  ? _showPickerOptions
                  : _showImageOptions)
              : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.antiAlias,
            child: imagePath != null
                ? Image.file(File(imagePath), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 26,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Photo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                          IMAGE VIEWER DIALOG                               */
/* -------------------------------------------------------------------------- */

class _ImageViewerDialog extends StatelessWidget {
  final String imagePath;
  final VoidCallback onDelete;
  final VoidCallback onChange;
  final VoidCallback onClose;

  const _ImageViewerDialog({
    required this.imagePath,
    required this.onDelete,
    required this.onChange,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text(
                    'Attached Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            // Pinch-to-zoom image
            Expanded(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 6.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: Center(
                  child: Image.file(File(imagePath), fit: BoxFit.contain),
                ),
              ),
            ),
            // Bottom action buttons
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Colors.redAccent,
                    onTap: onDelete,
                  ),
                  _ActionButton(
                    icon: Icons.swap_horiz_outlined,
                    label: 'Change',
                    color: Colors.white,
                    onTap: onChange,
                  ),
                  _ActionButton(
                    icon: Icons.close,
                    label: 'Close',
                    color: Colors.white70,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
