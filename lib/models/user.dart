import 'dart:math' as math;

class AppUser {
  final String id; // Auto-generated: SHG-XXXXX, SME-XXXXX, PSA-XXXXX
  final String name;
  final String phone;
  final String? email; // Email address for authentication
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
  final bool isSuspended; // Account suspension status
  final DateTime? suspendedAt; // When account was suspended
  final String? suspensionReason; // Reason for suspension
  final String? suspendedBy; // Admin ID who suspended the account
  final PartnerInfo? partnerInfo; // Partner information for tracking user sources
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // System Rating Fields (Auto-calculated based on performance)
  final double systemRating; // 0-5 stars, automatically calculated
  final int totalCompletedOrders; // Total successfully completed orders
  final double averageCustomerRating; // 0-5, average from customer reviews
  final double orderFulfillmentRate; // 0-100%, percentage of successful deliveries
  final DateTime? lastRatingUpdate; // When rating was last calculated

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
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
    this.isSuspended = false,
    this.suspendedAt,
    this.suspensionReason,
    this.suspendedBy,
    this.partnerInfo,
    required this.createdAt,
    required this.updatedAt,
    this.systemRating = 0.0,
    this.totalCompletedOrders = 0,
    this.averageCustomerRating = 0.0,
    this.orderFulfillmentRate = 0.0,
    this.lastRatingUpdate,
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
    // Helper function to parse DateTime from Firestore Timestamp or String
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }
    
    return AppUser(
      id: data['id'] ?? id, // Use stored ID if available, fallback to document ID
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().toLowerCase() == 'userrole.${(data['role'] as String).toLowerCase()}',
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
      profileCompletionDeadline: parseDateTime(data['profile_completion_deadline']),
      isVerified: data['is_verified'] ?? false,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.toString() == 'VerificationStatus.${data['verification_status']}',
        orElse: () => VerificationStatus.pending,
      ),
      verifiedAt: parseDateTime(data['verified_at']),
      isSuspended: data['is_suspended'] ?? false,
      suspendedAt: parseDateTime(data['suspended_at']),
      suspensionReason: data['suspension_reason'],
      suspendedBy: data['suspended_by'],
      partnerInfo: data['partner_info'] != null
          ? PartnerInfo.fromMap(data['partner_info'])
          : null,
      createdAt: parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updated_at']) ?? DateTime.now(),
      systemRating: (data['system_rating'] as num?)?.toDouble() ?? 0.0,
      totalCompletedOrders: (data['total_completed_orders'] as num?)?.toInt() ?? 0,
      averageCustomerRating: (data['average_customer_rating'] as num?)?.toDouble() ?? 0.0,
      orderFulfillmentRate: (data['order_fulfillment_rate'] as num?)?.toDouble() ?? 0.0,
      lastRatingUpdate: parseDateTime(data['last_rating_update']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id, // Store the user ID in the document
      'name': name,
      'phone': phone,
      'email': email,
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
      'is_suspended': isSuspended,
      'suspended_at': suspendedAt?.toIso8601String(),
      'suspension_reason': suspensionReason,
      'suspended_by': suspendedBy,
      'partner_info': partnerInfo?.toMap(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'system_rating': systemRating,
      'total_completed_orders': totalCompletedOrders,
      'average_customer_rating': averageCustomerRating,
      'order_fulfillment_rate': orderFulfillmentRate,
      'last_rating_update': lastRatingUpdate?.toIso8601String(),
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
}

extension SexExtension on Sex {
  String get displayName {
    switch (this) {
      case Sex.male:
        return 'Male';
      case Sex.female:
        return 'Female';
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
  final String? district;  // Optional - can be null when only GPS provided
  final String? subcounty; // Optional - can be null when only GPS provided
  final String? parish;    // Optional - can be null when only GPS provided
  final String? village;   // Optional - can be null when only GPS provided
  final String? address;   // Full address for display

  Location({
    required this.latitude,
    required this.longitude,
    this.district,
    this.subcounty,
    this.parish,
    this.village,
    this.address,
  });
  
  String get fullAddress {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    
    // Build address from administrative divisions if available
    final parts = <String>[];
    if (village != null && village!.isNotEmpty) parts.add(village!);
    if (parish != null && parish!.isNotEmpty) parts.add(parish!);
    if (subcounty != null && subcounty!.isNotEmpty) parts.add(subcounty!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    
    // Fallback to GPS coordinates if no address parts available
    return 'GPS: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
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

/// Partner information for tracking user acquisition sources
class PartnerInfo {
  final PartnerType partner;
  final String? heiferAgrihubName;
  final String? heiferSHGName;
  final String? heiferSHGId;
  final String? heiferParticipantId;
  final String? fsmeGroupName;
  final String? fsmeGroupId;
  final String? fsmeParticipantId;

  PartnerInfo({
    required this.partner,
    this.heiferAgrihubName,
    this.heiferSHGName,
    this.heiferSHGId,
    this.heiferParticipantId,
    this.fsmeGroupName,
    this.fsmeGroupId,
    this.fsmeParticipantId,
  });

  factory PartnerInfo.fromMap(Map<String, dynamic> data) {
    return PartnerInfo(
      partner: PartnerType.values.firstWhere(
        (e) => e.toString() == 'PartnerType.${data['partner']}',
        orElse: () => PartnerType.heifer,
      ),
      heiferAgrihubName: data['heifer_agrihub_name'],
      heiferSHGName: data['heifer_shg_name'],
      heiferSHGId: data['heifer_shg_id'],
      heiferParticipantId: data['heifer_participant_id'],
      fsmeGroupName: data['fsme_group_name'],
      fsmeGroupId: data['fsme_group_id'],
      fsmeParticipantId: data['fsme_participant_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partner': partner.toString().split('.').last,
      'heifer_agrihub_name': heiferAgrihubName,
      'heifer_shg_name': heiferSHGName,
      'heifer_shg_id': heiferSHGId,
      'heifer_participant_id': heiferParticipantId,
      'fsme_group_name': fsmeGroupName,
      'fsme_group_id': fsmeGroupId,
      'fsme_participant_id': fsmeParticipantId,
    };
  }
}

/// Partner organizations
enum PartnerType {
  heifer,
  fsme,
  curad,
  asgima,
}

extension PartnerTypeExtension on PartnerType {
  String get displayName {
    switch (this) {
      case PartnerType.heifer:
        return 'Heifer';
      case PartnerType.fsme:
        return 'FSME';
      case PartnerType.curad:
        return 'CURAD';
      case PartnerType.asgima:
        return 'ASGIMA';
    }
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
