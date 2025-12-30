import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/pin_controller.dart';
import '../.././dashboard/dashboard_screen.dart';

class PinKeypad extends StatelessWidget {
  const PinKeypad({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PinController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
        ),
        itemBuilder: (context, index) {
          if (index == 9) return const SizedBox();

          if (index == 11) {
            return _Key(
              // ignore: sort_child_properties_last
              child: const Icon(Icons.backspace),
              onTap: controller.removeDigit,
            );
          }

          final number = index == 10 ? 0 : index + 1;

          return _Key(
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 22),
            ),
            onTap: () {
              controller.addDigit(number);

              if (controller.isComplete) {
                final valid = controller.validatePin();

                if (valid) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                } else {
                  controller.clear();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Invalid PIN')));
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _Key({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(40),
      onTap: onTap,
      child: Center(child: child),
    );
  }
}
