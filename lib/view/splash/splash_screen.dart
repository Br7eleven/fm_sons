import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fm_sons/utils/constants/color_string.dart';
import 'package:fm_sons/view/auth/auth_screen.dart';
// import 'package:fm_sons/view/dashboard/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate app loading (DB init, settings load, etc.)
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FMSons.primary, // Vyapar-like blue
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: FMSons.bgWhite,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  size: 60,
                  color: FMSons.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'FM Sons',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: FMSons.textColor,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'BR7 Technologies.',
                style: TextStyle(fontSize: 14, color: FMSons.textColor2),
              ),

              const SizedBox(height: 40),

              // Loader
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
