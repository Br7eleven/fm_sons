import 'package:flutter/material.dart';
import 'package:fm_sons/view/auth/auth_screen.dart';
import 'package:fm_sons/view/dashboard/dashboard_screen.dart';
import 'package:fm_sons/view/splash/splash_screen.dart';
import 'package:fm_sons/view/invoice/invoice_items_section.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FM Sons Billing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // professional blue
        ),
        fontFamily: 'Roboto',
      ),
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const DashboardScreen(),
        '/invoice': (context) => const InvoiceItemsSection(),
      },
    );
  }
}
