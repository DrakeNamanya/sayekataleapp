import 'dart:math' as math;

class AppUser {
  final String id; // Auto-generated: SHG-XXXXX, SME-XXXXX, PSA-XXXXX
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final String? nationalId;
  final String? nationalIdPhoto;
  final String? nameOnIdPhoto; // Name extracted from National ID photo for verification
  final Sex? sex;
  final DisabilityStatus disabilityStatus;
  final Location? location;
  final bool isProfileComplete;
  final DateTime? profileCompletionDeadline; // 24 hours from registration
  final bool isVerified; // Identity verified (NIN + name match)
  final VerificationStatus verificationStatus;
  final DateTime? verifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImage,
    this.nationalId,
    this.nationalIdPhoto,
    this.nameOnIdPhoto,
    this.sex,
    this.disabilityStatus = DisabilityStatus.no,
    this.location,
    this.isProfileComplete = false,
    this.profileCompletionDeadline,
    this.isVerified = false,
    this.verificationStatus = VerificationStatus.pending,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Check if user can sell (profile must be complete)
  bool get canSell {
    if (role != UserRole.shg) return false;
    if (!isProfileComplete) return false;
    if (profileCompletionDeadline != null && DateTime.now().isAfter(profileCompletionDeadline!)) {
      return isProfileComplete;
    }
    return true;
  }
  
  // Calculate remaining time to complete profile
  Duration? get timeRemainingToCompleteProfile {
    if (isProfileComplete) return null;
    if (profileCompletionDeadline == null) return null;
    final remaining = profileCompletionDeadline!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.shg,
      ),
      profileImage: data['profile_image'],
      nationalId: data['national_id'],
      nationalIdPhoto: data['national_id_photo'],
      nameOnIdPhoto: data['name_on_id_photo'],
      sex: data['sex'] != null 
          ? Sex.values.firstWhere(
              (e) => e.toString() == 'Sex.${data['sex']}',
              orElse: () => Sex.male,
            )
          : null,
      disabilityStatus: DisabilityStatus.values.firstWhere(
        (e) => e.toString() == 'DisabilityStatus.${data['disability_status']}',
        orElse: () => DisabilityStatus.no,
      ),
      location: data['location'] != null
          ? Location.fromMap(data['location'])
          : null,
      isProfileComplete: data['is_profile_complete'] ?? false,
      profileCompletionDeadline: data['profile_completion_deadline'] != null
          ? DateTime.parse(data['profile_completion_deadline'])
          : null,
      isVerified: data['is_verified'] ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.toString() == 'VerificationStatus.${data['verification_status']}',
        orElse: () => VerificationStatus.pending,
      ),
      verifiedAt: data['verified_at'] != null
          ? DateTime.parse(data['verified_at'])
          : null,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profile_image': profileImage,
      'national_id': nationalId,
      'national_id_photo': nationalIdPhoto,
      'name_on_id_photo': nameOnIdPhoto,
      'sex': sex?.toString().split('.').last,
      'disability_status': disabilityStatus.toString().split('.').last,
      'location': location?.toMap(),
      'is_profile_complete': isProfileComplete,
      'profile_completion_deadline': profileCompletionDeadline?.toIso8601String(),
      'is_verified': isVerified,
      'verification_status': verificationStatus.toString().split('.').last,
      'verified_at': verifiedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  // Generate user ID based on role
  static String generateUserId(UserRole role, int count) {
    String prefix;
    switch (role) {
      case UserRole.shg:
        prefix = 'SHG';
        break;
      case UserRole.sme:
        prefix = 'SME';
        break;
      case UserRole.psa:
        prefix = 'PSA';
        break;
      case UserRole.admin:
        prefix = 'ADM';
        break;
    }
    return '$prefix-${(count + 1).toString().padLeft(5, '0')}';
  }
}

enum UserRole {
  shg,      // Self-Help Group (Farmers) - Sell products, buy inputs
  sme,      // Small & Medium Enterprise (Buyers) - Purchase agricultural products
  psa,      // Private Sector Aggregator (Suppliers) - Sell seeds, fertilizers, equipment
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.shg:
        return 'Farmer (SHG)';
      case UserRole.sme:
        return 'Buyer (SME)';
      case UserRole.psa:
        return 'Supplier (PSA)';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get description {
    switch (this) {
      case UserRole.shg:
        return 'Sell agricultural products, buy farming inputs';
      case UserRole.sme:
        return 'Purchase agricultural products from farmers';
      case UserRole.psa:
        return 'Supply seeds, fertilizers, and equipment';
      case UserRole.admin:
        return 'System administrator';
    }
  }
}

enum Sex {
  male,
  female,
  other,
}

extension SexExtension on Sex {
  String get displayName {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
      case Sex.other:
        return 'Other';
    }
  }
}

enum DisabilityStatus {
  yes, // Person With Disability (PWD)
  no,
}

extension DisabilityStatusExtension on DisabilityStatus {
  String get displayName {
    switch (this) {
      case DisabilityStatus.yes:
        return 'Yes (PWD)';
      case DisabilityStatus.no:
        return 'No';
    }
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String district;
  final String subcounty;
  final String parish;
  final String village;
  final String? address; // Full address for display

  Location({
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.subcounty,
    required this.parish,
    required this.village,
    this.address,
  });
  
  String get fullAddress {
    return address ?? '$village, $parish, $subcounty, $district';
  }
  
  /// Calculate distance to another location using Haversine formula (in kilometers)
  double distanceTo(Location other) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    // Convert degrees to radians
    final lat1Rad = latitude * (math.pi / 180.0);
    final lat2Rad = other.latitude * (math.pi / 180.0);
    final deltaLatRad = (other.latitude - latitude) * (math.pi / 180.0);
    final deltaLonRad = (other.longitude - longitude) * (math.pi / 180.0);
    
    // Haversine formula
    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }
  
  /// Get formatted distance string
  String distanceTextTo(Location other) {
    final distance = distanceTo(other);
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  factory Location.fromMap(Map<String, dynamic> data) {
    return Location(
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      district: data['district'] ?? '',
      subcounty: data['subcounty'] ?? '',
      parish: data['parish'] ?? '',
      village: data['village'] ?? '',
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'district': district,
      'subcounty': subcounty,
      'parish': parish,
      'village': village,
      'address': address,
    };
  }
}

/// Verification status for user identity
enum VerificationStatus {
  pending,    // Initial state - not yet verified
  inReview,   // Under manual review
  verified,   // Fully verified (NIN + name match confirmed)
  rejected,   // Verification failed
  suspended,  // Account suspended due to verification issues
}

extension VerificationStatusExtension on VerificationStatus {
  String get displayName {
    switch (this) {
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.inReview:
        return 'Under Review';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Verification Failed';
      case VerificationStatus.suspended:
        return 'Suspended';
    }
  }
  
  String get description {
    switch (this) {
      case VerificationStatus.pending:
        return 'Complete your profile with valid NIN and ID photo';
      case VerificationStatus.inReview:
        return 'Your identity is being verified by our team';
      case VerificationStatus.verified:
        return 'Your identity has been verified';
      case VerificationStatus.rejected:
        return 'Verification failed. Please update your information';
      case VerificationStatus.suspended:
        return 'Account suspended. Contact support for assistance';
    }
  }
}
