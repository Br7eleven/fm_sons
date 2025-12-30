import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/pin_controller.dart';

class PinIndicator extends StatelessWidget {
  const PinIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinController>();
    // // Temporary static count (later connect controller)
    // const int filled = 1;
    // const int total = 6;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PinController.pinLength, (index) {
        final filled = index < controller.enteredPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF2563EB) : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
