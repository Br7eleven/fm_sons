import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fm_sons/view/masters/customer/customer_controller.dart';
import 'package:provider/provider.dart';
import 'package:fm_sons/view/auth/auth_screen.dart';
import 'package:fm_sons/view/dashboard/dashboard_screen.dart';
import 'package:fm_sons/view/splash/splash_screen.dart';
import 'package:fm_sons/view/masters/unit/unit_controller.dart';
import 'package:fm_sons/view/invoice/create_invoice_screen.dart';
import 'package:fm_sons/view/invoice/controller/create_invoice_controller.dart';
import 'view/masters/product/product_controller.dart';
import 'view/notes/note_controller.dart';
import 'view/settings/company_profile_controller.dart';
import 'view/settings/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Request the platform to render as fast as possible (hints OS scheduler).
  // On Android this feeds through to Choreographer and lets 120Hz VSync fire.
  timeDilation = 1.0;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => InvoiceController()),
        ChangeNotifierProvider(create: (_) => UnitController()),
        ChangeNotifierProvider(
          create: (context) =>
              ProductController(unitController: context.read<UnitController>()),
        ),
        ChangeNotifierProvider(create: (_) => CustomerController()),
        ChangeNotifierProvider(create: (_) => NoteController()),
        ChangeNotifierProvider(create: (_) => CompanyProfileController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'FM Sons Billing',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // professional blue
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A), // same brand blue
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF121212)),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey,
        ),
      ),
      routes: {
        '/': (context) => SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const DashboardScreen(),
        '/invoice': (context) => const CreateInvoiceScreen(),
        // '/invoice': (context) => const InvoiceItemsSection(),
      },
    );
  }
}
