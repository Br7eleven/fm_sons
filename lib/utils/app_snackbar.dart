import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

/// Top-sliding snackbar replacement — slides in from top, auto-dismisses.
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  final overlay = Overlay.of(context);
  final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 8;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SnackBarWidget(
      message: message,
      isError: isError,
      topPadding: topPadding,
      onDismiss: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _SnackBarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final double topPadding;
  final VoidCallback onDismiss;

  const _SnackBarWidget({
    required this.message,
    required this.isError,
    required this.topPadding,
    required this.onDismiss,
  });

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    // Auto-dismiss after 2.8 seconds
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isError
        ? Colors.red.shade50
        : Theme.of(context).cardColor;
    final accentColor = widget.isError ? Colors.red.shade600 : FMSons.accent;
    final icon = widget.isError ? Icons.error_outline : Icons.check_circle_outline;

    return Positioned(
      top: widget.topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: accentColor, width: 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isError ? Colors.red.shade800 : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
