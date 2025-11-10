import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
// Temporarily commented out - has cart issues to fix later
// import 'screens/customer/customer_home_screen.dart';
// import 'screens/farmer/farmer_dashboard_screen.dart';
import 'screens/shg/shg_dashboard_screen.dart';
import 'screens/sme/sme_dashboard_screen.dart';
import 'screens/psa/psa_dashboard_screen.dart';
import 'screens/test/validation_test_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'services/firebase_test.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Test Firebase connection (only in debug mode)
  if (kDebugMode) {
    await FirebaseTest.runAllTests();
  }
  
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
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to light mode, user can change in settings
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/shg-dashboard': (context) => const SHGDashboardScreen(), // Farmer (SHG)
          '/sme-dashboard': (context) => const SMEDashboardScreen(), // Buyer (SME)
          '/psa-dashboard': (context) => const PSADashboardScreen(), // Supplier (PSA)
          '/validation-test': (context) => const ValidationTestScreen(), // Validation Test Screen
          '/admin-login': (context) => const AdminLoginScreen(), // Admin Portal
        },
      ),
    );
  }
}
