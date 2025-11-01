import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/customer/customer_home_screen.dart';
import 'screens/farmer/farmer_dashboard_screen.dart';
import 'screens/shg/shg_dashboard_screen.dart';
import 'screens/sme/sme_dashboard_screen.dart';
import 'screens/psa/psa_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'SAYE Katale - Demand Meets Supply',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/shg-dashboard': (context) => const SHGDashboardScreen(), // Farmer (SHG)
          '/sme-dashboard': (context) => const SMEDashboardScreen(), // Buyer (SME)
          '/psa-dashboard': (context) => const PSADashboardScreen(), // Supplier (PSA)
        },
      ),
    );
  }
}
