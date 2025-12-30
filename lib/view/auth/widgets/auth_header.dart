import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.lock, size: 36, color: Color(0xFF2563EB)),
        ),
        const SizedBox(height: 16),
        const Text(
          'FM SONS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Government Contracting Solutions',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        // const Text(
        //   'Welcome back, CEO',
        //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        // ),
        // const SizedBox(height: 6),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 40),
        //   child: Text(
        //     'Please authenticate to access sensitive billing data.',
        //     textAlign: TextAlign.center,
        //     style: TextStyle(color: Colors.grey),
        //   ),
        // ),
      ],
    );
  }
}
