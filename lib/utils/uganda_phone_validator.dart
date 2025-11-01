/// Uganda Phone Number Validator
/// 
/// Validates Ugandan telephone numbers according to official specifications:
/// - Country code: +256
/// - National Significant Number (NSN): 9 digits
/// - Mobile numbers start with 7 (e.g., 70, 71, 72, 73, 74, 75, 76, 77, 78, 79)
/// - Format: +256 7XX XXX XXX or 07XX XXX XXX (domestic)

class UgandaPhoneValidator {
  // Mobile operator prefixes in Uganda
  static const Map<String, List<String>> operatorPrefixes = {
    'MTN Uganda': ['76', '77', '78', '79'],
    'Airtel Uganda': ['70', '74', '75'],
    'Africell Uganda': ['73'],
    'Uganda Telecom (UTel)': ['71'],
    'Lycamobile Uganda': ['72'],
  };

  // All valid mobile prefixes (first 2 digits after country code or trunk prefix)
  static const List<String> validMobilePrefixes = [
    '70', '71', '72', '73', '74', '75', '76', '77', '78', '79'
  ];

  /// Validates if the phone number is a valid Ugandan mobile number
  /// 
  /// Accepts formats:
  /// - +256712345678 (E.164 international format)
  /// - 256712345678 (without plus)
  /// - 0712345678 (domestic format with trunk prefix)
  /// - 712345678 (without prefix - less common but handled)
  /// 
  /// Returns error message if invalid, null if valid
  static String? validate(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces, dashes, and parentheses
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's a valid Uganda number format
    if (!isValidFormat(cleaned)) {
      return 'Invalid Uganda phone number format';
    }

    // Extract the mobile prefix (first 2 digits after country code/trunk)
    String prefix = extractMobilePrefix(cleaned);
    
    if (!validMobilePrefixes.contains(prefix)) {
      return 'Invalid mobile operator prefix. Must start with 70-79';
    }

    return null; // Valid
  }

  /// Checks if the phone number format is valid
  static bool isValidFormat(String phoneNumber) {
    // Remove spaces and special characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Format 1: +256 followed by 9 digits starting with 7
    if (RegExp(r'^\+2567\d{8}$').hasMatch(cleaned)) {
      return true;
    }

    // Format 2: 256 followed by 9 digits starting with 7 (without +)
    if (RegExp(r'^2567\d{8}$').hasMatch(cleaned)) {
      return true;
    }

    // Format 3: 0 followed by 9 digits starting with 7 (domestic format)
    if (RegExp(r'^07\d{8}$').hasMatch(cleaned)) {
      return true;
    }

    // Format 4: 9 digits starting with 7 (without any prefix)
    if (RegExp(r'^7\d{8}$').hasMatch(cleaned)) {
      return true;
    }

    return false;
  }

  /// Extracts the mobile operator prefix (first 2 digits after country code)
  static String extractMobilePrefix(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Remove country code and trunk prefix to get the mobile prefix
    if (cleaned.startsWith('+256')) {
      return cleaned.substring(4, 6); // Characters 4-5 (after +256)
    } else if (cleaned.startsWith('256')) {
      return cleaned.substring(3, 5); // Characters 3-4 (after 256)
    } else if (cleaned.startsWith('0')) {
      return cleaned.substring(1, 3); // Characters 1-2 (after 0)
    } else {
      return cleaned.substring(0, 2); // First 2 characters
    }
  }

  /// Gets the operator name from phone number
  static String? getOperatorName(String phoneNumber) {
    if (!isValidFormat(phoneNumber)) {
      return null;
    }

    String prefix = extractMobilePrefix(phoneNumber);

    for (var entry in operatorPrefixes.entries) {
      if (entry.value.contains(prefix)) {
        return entry.key;
      }
    }

    return 'Unknown Operator';
  }

  /// Normalizes phone number to E.164 format (+256XXXXXXXXX)
  static String normalizeToE164(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Already in E.164 format
    if (cleaned.startsWith('+256')) {
      return cleaned;
    }

    // Has country code but missing +
    if (cleaned.startsWith('256')) {
      return '+$cleaned';
    }

    // Domestic format with trunk prefix (0)
    if (cleaned.startsWith('0')) {
      return '+256${cleaned.substring(1)}';
    }

    // No prefix at all (assume it's a valid 9-digit number)
    if (cleaned.length == 9 && cleaned.startsWith('7')) {
      return '+256$cleaned';
    }

    return phoneNumber; // Return as-is if can't normalize
  }

  /// Formats phone number for display
  /// Returns format: +256 7XX XXX XXX
  static String formatForDisplay(String phoneNumber) {
    String e164 = normalizeToE164(phoneNumber);
    
    if (e164.startsWith('+256') && e164.length == 13) {
      // +256 7XX XXX XXX
      return '${e164.substring(0, 4)} ${e164.substring(4, 7)} ${e164.substring(7, 10)} ${e164.substring(10)}';
    }

    return phoneNumber; // Return as-is if can't format
  }

  /// Formats phone number for domestic display
  /// Returns format: 07XX XXX XXX
  static String formatForDomesticDisplay(String phoneNumber) {
    String e164 = normalizeToE164(phoneNumber);
    
    if (e164.startsWith('+256') && e164.length == 13) {
      String nsn = e164.substring(4); // Remove +256
      // 07XX XXX XXX
      return '0${nsn.substring(0, 3)} ${nsn.substring(3, 6)} ${nsn.substring(6)}';
    }

    return phoneNumber; // Return as-is if can't format
  }

  /// Gets validation rules as a user-friendly message
  static String getValidationRules() {
    return '''
Uganda Phone Number Format:
• Must be a Ugandan mobile number
• Country code: +256
• Must start with 70, 71, 72, 73, 74, 75, 76, 77, 78, or 79
• Total: 9 digits after country code
• Examples:
  - +256 712 345 678
  - 0712 345 678
  - 256712345678
  
Valid Operators:
• MTN: 76, 77, 78, 79
• Airtel: 70, 74, 75
• Africell: 73
• UTel: 71
• Lycamobile: 72
''';
  }

  /// Quick validation for forms - returns true if valid
  static bool isValid(String? phoneNumber) {
    return validate(phoneNumber) == null;
  }

  /// Checks if phone number belongs to a specific operator
  static bool isOperator(String phoneNumber, String operatorName) {
    String? operator = getOperatorName(phoneNumber);
    return operator?.toLowerCase().contains(operatorName.toLowerCase()) ?? false;
  }

  /// Gets a list of example valid phone numbers
  static List<String> getExamples() {
    return [
      '+256 712 345 678',
      '+256 774 123 456',
      '0712 345 678',
      '0774 123 456',
    ];
  }

  /// Validates multiple phone numbers (e.g., for mobile money)
  static Map<String, String?> validateMultiple(List<String> phoneNumbers) {
    Map<String, String?> results = {};
    for (String number in phoneNumbers) {
      results[number] = validate(number);
    }
    return results;
  }
}

/// Extension methods for String to make validation easier
extension UgandaPhoneStringExtension on String {
  /// Check if this string is a valid Uganda phone number
  bool get isValidUgandaPhone => UgandaPhoneValidator.isValid(this);

  /// Get operator name for this phone number
  String? get ugandaOperator => UgandaPhoneValidator.getOperatorName(this);

  /// Normalize to E.164 format
  String get toE164 => UgandaPhoneValidator.normalizeToE164(this);

  /// Format for display
  String get formatUgandaPhone => UgandaPhoneValidator.formatForDisplay(this);

  /// Format for domestic display
  String get formatUgandaPhoneDomestic => UgandaPhoneValidator.formatForDomesticDisplay(this);
}
