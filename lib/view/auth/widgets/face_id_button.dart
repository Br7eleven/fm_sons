import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';

class FaceIdButton extends StatelessWidget {
  const FaceIdButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: 160,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.face),
          label: Text('Use Face ID'),
          style: ElevatedButton.styleFrom(
            backgroundColor: FMSons.secondary,
            foregroundColor: FMSons.bgWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
