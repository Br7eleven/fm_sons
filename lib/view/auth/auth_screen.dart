import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controller/pin_controller.dart';
import 'widgets/auth_header.dart';
import 'widgets/pin_indicator.dart';
import 'widgets/pin_keypad.dart';
import 'widgets/face_id_button.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PinController(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: Column(
            children: const [
              SizedBox(height: 20),
              AuthHeader(),
              SizedBox(height: 40),
              PinIndicator(),
              SizedBox(height: 10),
              PinKeypad(),
              SizedBox(height: 10),
              FaceIdButton(),
              SizedBox(height: 16),
              Text('Forgot PIN?', style: TextStyle(color: Colors.grey)),
              // SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
