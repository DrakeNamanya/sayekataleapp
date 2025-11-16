// Uganda Business Validation Utilities
// Validates TIN (Tax Identification Number) and Business Registration Numbers
// Based on Uganda Revenue Authority (URA) and URSB specifications

class UgandaBusinessValidators {
  // ============================================================================
  // TIN (Tax Identification Number) Validation
  // ============================================================================
  
  /// TIN Format: 10 digits
  /// - First digit: Entity type (1-9)
  ///   1 = Business/Company
  ///   2 = Individual taxpayer
  ///   3-9 = Other entity types
  /// - Next 8 digits: Unique identification number
  /// - Last digit: Checksum/validation digit
  /// Example: 1000123456
  static final RegExp _tinRegex = RegExp(r'^\d{10}$');
  
  /// Validates if a TIN follows the correct format
  /// Returns true if valid, false otherwise
  static bool isValidTINFormat(String? tin) {
    if (tin == null || tin.isEmpty) {
      return false;
    }
    
    // Remove any spaces, hyphens, or other separators
    final cleanTin = tin.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Must be exactly 10 digits
    if (!_tinRegex.hasMatch(cleanTin)) {
      return false;
    }
    
    // First digit should be 1-9 (entity type identifier)
    final firstDigit = int.parse(cleanTin[0]);
    if (firstDigit < 1 || firstDigit > 9) {
      return false;
    }
    
    return true;
  }
  
  /// Formats TIN for display with spacing
  /// Example: 1000123456 → 1 000 123 456
  static String formatTIN(String tin) {
    if (!isValidTINFormat(tin)) {
      return tin; // Return as-is if invalid
    }
    
    final cleanTin = cleanTIN(tin);
    
    // Format: 1 + space + 3 digits + space + 3 digits + space + 3 digits
    return '${cleanTin.substring(0, 1)} '
           '${cleanTin.substring(1, 4)} '
           '${cleanTin.substring(4, 7)} '
           '${cleanTin.substring(7, 10)}';
  }
  
  /// Removes formatting from TIN for storage/comparison
  /// Example: 1 000 123 456 → 1000123456
  static String cleanTIN(String tin) {
    return tin.replaceAll(RegExp(r'[\s\-]'), '');
  }
  
  /// Returns the entity type based on first digit
  static String getTINEntityType(String? tin) {
    if (!isValidTINFormat(tin)) {
      return 'Invalid';
    }
    
    final cleanTin = cleanTIN(tin!);
    final firstDigit = int.parse(cleanTin[0]);
    
    switch (firstDigit) {
      case 1:
        return 'Business/Company';
      case 2:
        return 'Individual Taxpayer';
      case 3:
        return 'Government Entity';
      case 4:
        return 'NGO/Non-Profit';
      case 5:
        return 'Partnership';
      default:
        return 'Other Entity Type';
    }
  }
  
  /// Validates TIN format and returns error message if invalid
  /// Returns null if valid
  static String? validateTIN(String? tin) {
    if (tin == null || tin.isEmpty) {
      return 'TIN is required';
    }
    
    final cleanTin = cleanTIN(tin);
    
    if (cleanTin.length != 10) {
      return 'TIN must be exactly 10 digits';
    }
    
    if (!_tinRegex.hasMatch(cleanTin)) {
      return 'TIN must contain only digits';
    }
    
    // Validate first digit (entity type)
    final firstDigit = int.parse(cleanTin[0]);
    if (firstDigit < 1 || firstDigit > 9) {
      return 'Invalid TIN format: First digit must be 1-9';
    }
    
    return null; // Valid
  }
  
  // ============================================================================
  // Business Registration Number Validation
  // ============================================================================
  
  /// Business Registration Number Format: 14 digits
  /// Issued by Uganda Registration Services Bureau (URSB)
  /// Example: 80034730481569
  static final RegExp _businessRegRegex = RegExp(r'^\d{14}$');
  
  /// Validates if a Business Registration Number follows the correct format
  /// Returns true if valid, false otherwise
  static bool isValidBusinessRegFormat(String? regNo) {
    if (regNo == null || regNo.isEmpty) {
      return false;
    }
    
    // Remove any spaces, hyphens, or other separators
    final cleanRegNo = regNo.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Must be exactly 14 digits
    return _businessRegRegex.hasMatch(cleanRegNo);
  }
  
  /// Formats Business Registration Number for display
  /// Example: 80034730481569 → 8003 4730 4815 69
  static String formatBusinessReg(String regNo) {
    if (!isValidBusinessRegFormat(regNo)) {
      return regNo; // Return as-is if invalid
    }
    
    final cleanRegNo = cleanBusinessReg(regNo);
    
    // Format: 4 digits + space + 4 digits + space + 4 digits + space + 2 digits
    return '${cleanRegNo.substring(0, 4)} '
           '${cleanRegNo.substring(4, 8)} '
           '${cleanRegNo.substring(8, 12)} '
           '${cleanRegNo.substring(12, 14)}';
  }
  
  /// Removes formatting from Business Registration Number
  /// Example: 8003 4730 4815 69 → 80034730481569
  static String cleanBusinessReg(String regNo) {
    return regNo.replaceAll(RegExp(r'[\s\-]'), '');
  }
  
  /// Validates Business Registration Number and returns error message if invalid
  /// Returns null if valid
  static String? validateBusinessReg(String? regNo) {
    if (regNo == null || regNo.isEmpty) {
      return 'Business Registration Number is required';
    }
    
    final cleanRegNo = cleanBusinessReg(regNo);
    
    if (cleanRegNo.length != 14) {
      return 'Business Registration Number must be exactly 14 digits';
    }
    
    if (!_businessRegRegex.hasMatch(cleanRegNo)) {
      return 'Business Registration Number must contain only digits';
    }
    
    return null; // Valid
  }
  
  // ============================================================================
  // Combined Business Verification
  // ============================================================================
  
  /// Verification result for business validation
  static BusinessVerificationResult verifyBusiness({
    required String? tin,
    required String? businessRegNo,
    required String? businessName,
  }) {
    final issues = <String>[];
    final warnings = <String>[];
    
    // 1. Validate TIN format
    final tinFormatValid = isValidTINFormat(tin);
    if (!tinFormatValid) {
      issues.add('Invalid TIN format. Must be 10 digits starting with 1-9.');
    }
    
    // 2. Validate Business Registration Number
    final businessRegFormatValid = isValidBusinessRegFormat(businessRegNo);
    if (!businessRegFormatValid) {
      issues.add('Invalid Business Registration Number. Must be 14 digits.');
    }
    
    // 3. Check business name
    if (businessName == null || businessName.isEmpty) {
      issues.add('Business name is required.');
    } else if (businessName.length < 3) {
      warnings.add('Business name seems too short. Please verify.');
    }
    
    // 4. Get entity type
    String? tinEntityType;
    if (tinFormatValid) {
      tinEntityType = getTINEntityType(tin);
    }
    
    return BusinessVerificationResult(
      tinFormatValid: tinFormatValid,
      businessRegFormatValid: businessRegFormatValid,
      tinEntityType: tinEntityType,
      issues: issues,
      warnings: warnings,
    );
  }
}

/// Business verification result class
class BusinessVerificationResult {
  final bool tinFormatValid;
  final bool businessRegFormatValid;
  final String? tinEntityType;
  final List<String> issues;
  final List<String> warnings;
  
  BusinessVerificationResult({
    required this.tinFormatValid,
    required this.businessRegFormatValid,
    this.tinEntityType,
    required this.issues,
    required this.warnings,
  });
  
  bool get isFullyValid => tinFormatValid && businessRegFormatValid && issues.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues => issues.isNotEmpty;
  
  String get verificationStatus {
    if (isFullyValid && !hasWarnings) return 'Verified';
    if (isFullyValid && hasWarnings) return 'Valid with Warnings';
    if (hasCriticalIssues) return 'Failed';
    return 'Incomplete';
  }
  
  /// Get a summary message of the verification
  String getSummaryMessage() {
    if (isFullyValid && !hasWarnings) {
      return 'All business details are valid';
    }
    
    if (issues.isNotEmpty) {
      return issues.first;
    }
    
    if (warnings.isNotEmpty) {
      return warnings.first;
    }
    
    return 'Business verification incomplete';
  }
}
