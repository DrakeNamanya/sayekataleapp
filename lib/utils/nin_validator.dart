// Uganda National ID Number (NIN) Validator
// Based on NIRA (National Identification & Registration Authority) specifications
//
// NIN Format: 14 characters total
// - First character: 'C' (Citizen) or 'A' (Legal Foreign Resident)
// - Remaining 13 characters: Alphanumeric (Letters A-Z and Digits 0-9)
// - Example: CM12AB34CD56EF78 (Citizen) or AF98XY76ZW54QR32 (Foreign Resident)

class NINValidator {
  // Regular expression for NIN validation
  // Format: C or A followed by exactly 13 alphanumeric characters
  static final RegExp _ninRegex = RegExp(r'^[CA][A-Z0-9]{13}$');

  /// Validates if a NIN follows the correct format
  /// Returns true if valid, false otherwise
  static bool isValidFormat(String? nin) {
    if (nin == null || nin.isEmpty) {
      return false;
    }

    // Remove any whitespace and convert to uppercase
    final cleanNin = nin.replaceAll(RegExp(r'\s'), '').toUpperCase();

    return _ninRegex.hasMatch(cleanNin);
  }

  /// Formats a NIN for display with spacing for readability
  /// Example: CM90100000001234 → CM 9010 0000 0001234
  static String formatNIN(String nin) {
    if (!isValidFormat(nin)) {
      return nin; // Return as-is if invalid
    }

    final cleanNin = nin.replaceAll(RegExp(r'\s'), '').toUpperCase();

    // Format: C/A + space + 4 digits + space + 4 digits + space + 5 digits
    return '${cleanNin.substring(0, 1)} '
        '${cleanNin.substring(1, 5)} '
        '${cleanNin.substring(5, 9)} '
        '${cleanNin.substring(9, 14)}';
  }

  /// Removes formatting from NIN for storage/comparison
  /// Example: CM 9010 0000 0001234 → CM90100000001234
  static String cleanNIN(String nin) {
    return nin.replaceAll(RegExp(r'\s'), '').toUpperCase();
  }

  /// Checks if NIN indicates citizenship status
  /// Returns 'Citizen' or 'Foreign Resident' or 'Invalid'
  static String getNINType(String? nin) {
    if (!isValidFormat(nin)) {
      return 'Invalid';
    }

    final cleanNin = cleanNIN(nin!);

    if (cleanNin.startsWith('C')) {
      return 'Citizen';
    } else if (cleanNin.startsWith('A')) {
      return 'Foreign Resident';
    }

    return 'Invalid';
  }

  /// Validates NIN format and returns error message if invalid
  /// Returns null if valid
  static String? validateNIN(String? nin) {
    if (nin == null || nin.isEmpty) {
      return 'NIN is required';
    }

    final cleanNin = cleanNIN(nin);

    if (cleanNin.length != 14) {
      return 'NIN must be exactly 14 characters';
    }

    if (!cleanNin.startsWith('C') && !cleanNin.startsWith('A')) {
      return 'NIN must start with C (Citizen) or A (Foreign Resident)';
    }

    // Check if remaining 13 characters are alphanumeric (letters and digits)
    final remainingChars = cleanNin.substring(1);
    if (!RegExp(r'^[A-Z0-9]{13}$').hasMatch(remainingChars)) {
      return 'NIN must have 13 alphanumeric characters (letters and digits) after the first letter';
    }

    return null; // Valid
  }

  /// Compares two names for similarity
  /// Returns true if names match (case-insensitive, ignoring extra spaces)
  static bool namesMatch(String? name1, String? name2) {
    if (name1 == null || name2 == null) {
      return false;
    }

    // Normalize names: trim, lowercase, remove extra spaces
    final normalized1 = name1.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final normalized2 = name2.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return normalized1 == normalized2;
  }

  /// Checks if name1 contains all words from name2 (flexible matching)
  /// Useful for partial name matching (e.g., "John Doe" matches "Doe John")
  static bool namesContainSameWords(String? name1, String? name2) {
    if (name1 == null || name2 == null) {
      return false;
    }

    // Normalize and split into words
    final words1 = name1.trim().toLowerCase().split(RegExp(r'\s+'));
    final words2 = name2.trim().toLowerCase().split(RegExp(r'\s+'));

    // Check if both sets contain the same words (order-independent)
    if (words1.length != words2.length) {
      return false;
    }

    // Sort and compare
    words1.sort();
    words2.sort();

    return words1.join(' ') == words2.join(' ');
  }

  /// Calculates name similarity score (0.0 to 1.0)
  /// 1.0 = perfect match, 0.0 = no match
  static double calculateNameSimilarity(String? name1, String? name2) {
    if (name1 == null || name2 == null) {
      return 0.0;
    }

    if (namesMatch(name1, name2)) {
      return 1.0;
    }

    if (namesContainSameWords(name1, name2)) {
      return 0.9; // Very high similarity, just different order
    }

    // Calculate word overlap
    final words1 = name1.trim().toLowerCase().split(RegExp(r'\s+'));
    final words2 = name2.trim().toLowerCase().split(RegExp(r'\s+'));

    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;

    return commonWords / totalWords;
  }
}

/// Verification result for user identity validation
class VerificationResult {
  final bool ninFormatValid;
  final bool nameMatchesNIN;
  final bool nameMatchesProfile;
  final double nameSimilarityScore;
  final String ninType;
  final List<String> issues;
  final List<String> warnings;

  VerificationResult({
    required this.ninFormatValid,
    required this.nameMatchesNIN,
    required this.nameMatchesProfile,
    required this.nameSimilarityScore,
    required this.ninType,
    required this.issues,
    required this.warnings,
  });

  bool get isFullyVerified =>
      ninFormatValid && nameMatchesNIN && nameMatchesProfile && issues.isEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasCriticalIssues => issues.isNotEmpty;

  String get verificationStatus {
    if (isFullyVerified) return 'Verified';
    if (hasCriticalIssues) return 'Failed';
    if (hasWarnings) return 'Partial';
    return 'Pending';
  }
}

/// User verification service
class UserVerificationService {
  /// Verifies user identity based on NIN, ID photo data, and profile name
  ///
  /// Parameters:
  /// - nin: National ID Number from user input
  /// - nameOnIdPhoto: Name extracted from National ID photo (OCR/manual)
  /// - profileName: Name from user profile
  static VerificationResult verifyUserIdentity({
    required String? nin,
    required String? nameOnIdPhoto,
    required String? profileName,
  }) {
    final issues = <String>[];
    final warnings = <String>[];

    // 1. Validate NIN format
    final ninFormatValid = NINValidator.isValidFormat(nin);
    if (!ninFormatValid) {
      issues.add(
        'Invalid NIN format. Must be C/A followed by 13 alphanumeric characters.',
      );
    }

    // 2. Check name matching between ID photo and NIN
    bool nameMatchesNIN = false;
    if (nameOnIdPhoto != null && nameOnIdPhoto.isNotEmpty) {
      // In real implementation, this would compare against NIRA database
      // For now, we check if names are provided
      nameMatchesNIN = true; // Placeholder - needs NIRA API integration
    } else {
      warnings.add('Name from ID photo not provided or not readable.');
    }

    // 3. Check name matching between profile and ID photo
    bool nameMatchesProfile = false;
    double nameSimilarityScore = 0.0;

    if (profileName != null && nameOnIdPhoto != null) {
      nameMatchesProfile = NINValidator.namesMatch(profileName, nameOnIdPhoto);
      nameSimilarityScore = NINValidator.calculateNameSimilarity(
        profileName,
        nameOnIdPhoto,
      );

      if (!nameMatchesProfile) {
        if (nameSimilarityScore >= 0.8) {
          warnings.add(
            'Names are similar but not exact match. Review required.',
          );
        } else if (nameSimilarityScore >= 0.5) {
          issues.add('Names have partial match only. Verification required.');
        } else {
          issues.add(
            'Names do not match. Profile name and ID photo name must be identical.',
          );
        }
      }
    } else {
      issues.add('Profile name or ID photo name is missing.');
    }

    // 4. Determine NIN type
    final ninType = NINValidator.getNINType(nin);

    return VerificationResult(
      ninFormatValid: ninFormatValid,
      nameMatchesNIN: nameMatchesNIN,
      nameMatchesProfile: nameMatchesProfile,
      nameSimilarityScore: nameSimilarityScore,
      ninType: ninType,
      issues: issues,
      warnings: warnings,
    );
  }
}
