// Environment Configuration
// Manages environment-specific variables and secrets
//
// Usage:
// Build with environment variables:
// flutter build apk --release \
//   --dart-define=PRODUCTION=true \
//   --dart-define=PAWAPAY_API_TOKEN=your_token \
//   --dart-define=API_BASE_URL=https://api.sayekatale.com

class Environment {
  // ========================================
  // App Environment
  // ========================================

  /// Production environment flag
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  /// Debug mode flag
  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: true,
  );

  /// App version
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // ========================================
  // API Configuration
  // ========================================

  /// Base API URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.sayekatale.com',
  );

  /// API timeout in milliseconds
  static const int apiTimeout = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 30000,
  );

  // ========================================
  // PawaPay Configuration
  // ========================================

  /// PawaPay API Token (MUST be provided via --dart-define in production)
  static const String pawaPayToken = String.fromEnvironment(
    'PAWAPAY_API_TOKEN',
    defaultValue: '', // Empty for security - must be provided at build time
  );

  /// PawaPay Deposit Callback URL
  static const String pawaPayDepositCallback = String.fromEnvironment(
    'PAWAPAY_DEPOSIT_CALLBACK',
    defaultValue: 'https://api.sayekatale.com/webhooks/pawapay/deposit',
  );

  /// PawaPay Withdrawal Callback URL
  static const String pawaPayWithdrawalCallback = String.fromEnvironment(
    'PAWAPAY_WITHDRAWAL_CALLBACK',
    defaultValue: 'https://api.sayekatale.com/webhooks/pawapay/withdrawal',
  );

  // ========================================
  // Firebase Configuration
  // ========================================

  /// Firebase Project ID
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'sayekatale-prod',
  );

  /// Firebase API Key
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  /// Firebase Auth Domain
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'sayekatale-prod.firebaseapp.com',
  );

  /// Firebase Storage Bucket
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'sayekatale-prod.appspot.com',
  );

  /// Firebase Messaging Sender ID
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  // ========================================
  // AdMob Configuration
  // ========================================

  /// AdMob App ID for Android
  /// Production: ca-app-pub-6557386913540479~2174503706
  static const String admobAppIdAndroid = String.fromEnvironment(
    'ADMOB_APP_ID_ANDROID',
    defaultValue: 'ca-app-pub-6557386913540479~2174503706',
  );

  /// AdMob Banner Ad Unit ID for Android
  /// Production: ca-app-pub-6557386913540479/5529911893
  static const String admobBannerIdAndroid = String.fromEnvironment(
    'ADMOB_BANNER_ID_ANDROID',
    defaultValue: 'ca-app-pub-6557386913540479/5529911893',
  );

  // ========================================
  // Feature Flags
  // ========================================

  /// Enable PawaPay integration
  static const bool enablePawaPay = bool.fromEnvironment(
    'ENABLE_PAWAPAY',
    defaultValue: true,
  );

  /// Enable analytics
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  /// Enable crashlytics
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
  );

  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = bool.fromEnvironment(
    'ENABLE_PERFORMANCE_MONITORING',
    defaultValue: true,
  );

  // ========================================
  // Validation Methods
  // ========================================

  /// Validate that all required environment variables are set
  static bool validateEnvironment() {
    if (isProduction) {
      // In production, these MUST be set
      if (pawaPayToken.isEmpty) {
        throw Exception('PAWAPAY_API_TOKEN must be set for production builds');
      }
      if (firebaseApiKey.isEmpty) {
        throw Exception('FIREBASE_API_KEY must be set for production builds');
      }
      if (firebaseMessagingSenderId.isEmpty) {
        throw Exception(
          'FIREBASE_MESSAGING_SENDER_ID must be set for production builds',
        );
      }
    }
    return true;
  }

  /// Get environment name as string
  static String get environmentName {
    return isProduction ? 'Production' : 'Development';
  }

  /// Print environment configuration (for debugging)
  static void printConfig() {
    // Only print in debug mode
    assert(() {
      // ignore: avoid_print
      print('========================================');
      // ignore: avoid_print
      print('Environment Configuration');
      // ignore: avoid_print
      print('========================================');
      // ignore: avoid_print
      print('Environment: $environmentName');
      // ignore: avoid_print
      print('Debug Mode: $debugMode');
      // ignore: avoid_print
      print('App Version: $appVersion');
      // ignore: avoid_print
      print('API Base URL: $apiBaseUrl');
      // ignore: avoid_print
      print('API Timeout: ${apiTimeout}ms');
      // ignore: avoid_print
      print('PawaPay Enabled: $enablePawaPay');
      // ignore: avoid_print
      print('PawaPay Token Set: ${pawaPayToken.isNotEmpty ? "Yes" : "No"}');
      // ignore: avoid_print
      print('PawaPay Deposit Callback: $pawaPayDepositCallback');
      // ignore: avoid_print
      print('PawaPay Withdrawal Callback: $pawaPayWithdrawalCallback');
      // ignore: avoid_print
      print('Firebase Project: $firebaseProjectId');
      // ignore: avoid_print
      print('Analytics Enabled: $enableAnalytics');
      // ignore: avoid_print
      print('Crashlytics Enabled: $enableCrashlytics');
      // ignore: avoid_print
      print('Performance Monitoring: $enablePerformanceMonitoring');
      // ignore: avoid_print
      print('========================================');
      return true;
    }());
  }
}
