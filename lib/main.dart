import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'config/environment.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/app_loader_screen.dart';
// Temporarily commented out - has cart issues to fix later
// import 'screens/customer/customer_home_screen.dart';
// import 'screens/farmer/farmer_dashboard_screen.dart';
import 'screens/shg/shg_dashboard_screen.dart';
import 'screens/sme/sme_dashboard_screen.dart';
import 'screens/psa/psa_dashboard_screen.dart';
import 'screens/test/validation_test_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/admin/admin_web_portal.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'services/firebase_test.dart';
import 'services/fcm_service.dart';

void main() async {
  // Wrap initialization in try-catch to prevent white screen
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // ========================================
    // PHASE 1: Environment Validation
    // ========================================
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('🔧 SayeKatale App Initialization');
      debugPrint('========================================');
    }

    // Validate environment configuration
    try {
      Environment.validateEnvironment();
      if (kDebugMode) {
        Environment.printConfig();
        debugPrint('✅ Environment validation passed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Environment validation failed: $e');
        debugPrint(
          '⚠️ App may not function correctly without proper configuration',
        );
      }
      // In development, continue despite validation failure
      // In production, this would throw and prevent app startup
      if (Environment.isProduction) {
        rethrow;
      }
    }

    // ========================================
    // PHASE 2: Firebase Initialization
    // ========================================
    if (kDebugMode) {
      debugPrint('🔄 Initializing Firebase...');
    }

    // Initialize Firebase with longer timeout for slow networks
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Firebase initialization timeout after 30 seconds');
      },
    );

    if (kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }

    // Verify Firebase app is accessible
    final app = Firebase.app();
    if (kDebugMode) {
      debugPrint('✅ Firebase app verified: ${app.name}');
    }

    // Register FCM background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (kDebugMode) {
      debugPrint('✅ FCM background handler registered');
    }

    // Test Firebase connection (only in debug mode)
    if (kDebugMode) {
      await FirebaseTest.runAllTests();
    }

    // ========================================
    // PHASE 3: Local Storage Initialization
    // ========================================
    if (kDebugMode) {
      debugPrint('🔄 Initializing Hive local storage...');
    }

    await Hive.initFlutter();

    if (kDebugMode) {
      debugPrint('✅ Hive initialized successfully');
    }

    // ========================================
    // PHASE 4: AdMob Initialization (Android only)
    // ========================================
    if (!kIsWeb) {
      if (kDebugMode) {
        debugPrint('🔄 Initializing Google Mobile Ads SDK...');
      }

      await MobileAds.instance.initialize();

      if (kDebugMode) {
        debugPrint('✅ Google Mobile Ads SDK initialized for Android');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          'ℹ️ Skipping AdMob initialization on Web platform (not supported)',
        );
      }
    }

    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('🚀 App initialization complete!');
      debugPrint('========================================');
    }
  } catch (e, stackTrace) {
    // CRITICAL: If Firebase init fails, we must still run the app
    // The App Loader Screen will detect this and show error UI
    debugPrint('❌ CRITICAL: Initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // Run app anyway - App Loader will handle Firebase check
    // This ensures user sees error message instead of crash
  }

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
        themeMode: ThemeMode
            .light, // Default to light mode, user can change in settings
        home: const SplashScreen(),
        routes: {
          '/app-loader': (context) => const AppLoaderScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/shg-dashboard': (context) =>
              const SHGDashboardScreen(), // Farmer (SHG)
          '/sme-dashboard': (context) =>
              const SMEDashboardScreen(), // Buyer (SME)
          '/psa-dashboard': (context) =>
              const PSADashboardScreen(), // Supplier (PSA)
          '/validation-test': (context) =>
              const ValidationTestScreen(), // Validation Test Screen
          '/admin-login': (context) => const AdminLoginScreen(), // Admin Login
          '/admin': (context) => const AdminWebPortal(), // Admin Web Portal (Desktop)
        },
      ),
    );
  }
}
