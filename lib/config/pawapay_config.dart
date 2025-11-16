import 'environment.dart';

/// PawaPay Mobile Money Configuration
/// Contains API credentials and provider settings
/// 
/// SECURITY: Tokens and sensitive URLs are now loaded from environment variables.
/// Build with: flutter build apk --dart-define=PAWAPAY_API_TOKEN=your_token
class PawaPayConfig {
  // API Token from Environment Variables (SECURE)
  static String get apiToken => Environment.pawaPayToken;
  
  // Webhook URLs from Environment Variables
  static String get depositCallbackUrl => Environment.pawaPayDepositCallback;
  
  static String get payoutCallbackUrl => Environment.pawaPayWithdrawalCallback;
  
  // Mobile Money Providers (Correspondent IDs)
  static const String mtnUganda = 'MTN_MOMO_UGA';
  static const String airtelUganda = 'AIRTEL_OAPI_UGA';
  
  // Currency
  static const String currency = 'UGX';
  
  // Minimum deposit amount
  static const double minDepositAmount = 1000.0;
  
  // Maximum deposit amount (adjust as needed)
  static const double maxDepositAmount = 10000000.0;
  
  /// Get provider display name
  static String getProviderName(String correspondentId) {
    switch (correspondentId) {
      case mtnUganda:
        return 'MTN Mobile Money';
      case airtelUganda:
        return 'Airtel Money';
      default:
        return correspondentId;
    }
  }
  
  /// Get provider logo/icon
  static String getProviderIcon(String correspondentId) {
    switch (correspondentId) {
      case mtnUganda:
        return '🟡'; // MTN yellow
      case airtelUganda:
        return '🔴'; // Airtel red
      default:
        return '💰';
    }
  }
  
  /// Validate phone number format
  static bool isValidPhoneNumber(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Uganda format: +256... or 0...
    if (cleaned.startsWith('+256')) {
      return cleaned.length == 13; // +256700123456
    } else if (cleaned.startsWith('0')) {
      return cleaned.length == 10; // 0700123456
    }
    
    return false;
  }
  
  /// Format phone number for PawaPay API
  static String formatPhoneNumber(String phone) {
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Convert to international format
    if (cleaned.startsWith('0')) {
      return '+256${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      return '+256$cleaned';
    }
    
    return cleaned;
  }
}
