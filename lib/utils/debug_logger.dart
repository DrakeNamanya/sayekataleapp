import 'package:flutter/foundation.dart';

/// Centralized debug logger for troubleshooting
class DebugLogger {
  static const String _profileTag = '🔍 PROFILE';
  static const String _productTag = '🔍 PRODUCT';
  static const String _storageTag = '🔍 STORAGE';
  static const String _firestoreTag = '🔍 FIRESTORE';
  static const String _authTag = '🔍 AUTH';

  /// Log profile-related operations
  static void profile(String message) {
    if (kDebugMode) {
      debugPrint('$_profileTag: $message');
    }
  }

  /// Log product-related operations
  static void product(String message) {
    if (kDebugMode) {
      debugPrint('$_productTag: $message');
    }
  }

  /// Log storage operations
  static void storage(String message) {
    if (kDebugMode) {
      debugPrint('$_storageTag: $message');
    }
  }

  /// Log Firestore operations
  static void firestore(String message) {
    if (kDebugMode) {
      debugPrint('$_firestoreTag: $message');
    }
  }

  /// Log authentication operations
  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('$_authTag: $message');
    }
  }

  /// Log error with full details
  static void error(
    String tag,
    String message,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR [$tag]: $message');
      debugPrint('   Error: $error');
      if (stackTrace != null) {
        debugPrint(
          '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}',
        );
      }
    }
  }

  /// Log data inspection
  static void inspect(String tag, String label, dynamic data) {
    if (kDebugMode) {
      debugPrint('🔎 INSPECT [$tag] $label:');
      if (data is Map) {
        data.forEach((key, value) {
          debugPrint('   - $key: $value');
        });
      } else {
        debugPrint('   $data');
      }
    }
  }

  /// Log separator for readability
  static void separator([String? title]) {
    if (kDebugMode) {
      if (title != null) {
        debugPrint('\n${'=' * 60}');
        debugPrint('  $title');
        debugPrint('=' * 60);
      } else {
        debugPrint('─' * 60);
      }
    }
  }
}
