import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription types available
enum SubscriptionType {
  smeDirectory, // SHG premium access to SME directory
}

/// Subscription status
enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending, // Payment pending
}

/// Premium subscription model
class Subscription {
  final String id;
  final String userId; // SHG user ID
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount; // UGX 50,000
  final String paymentMethod;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.paymentMethod,
    this.paymentReference,
    required this.createdAt,
    this.cancelledAt,
  });

  /// Check if subscription is currently active
  bool get isActive {
    return status == SubscriptionStatus.active &&
        DateTime.now().isBefore(endDate);
  }

  /// Days remaining in subscription
  int get daysRemaining {
    if (!isActive) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Create from Firestore document
  factory Subscription.fromFirestore(Map<String, dynamic> data, String id) {
    return Subscription(
      id: id,
      userId: data['user_id'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'smeDirectory'),
        orElse: () => SubscriptionType.smeDirectory,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['payment_method'] ?? '',
      paymentReference: data['payment_reference'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      cancelledAt: data['cancelled_at'] != null
          ? (data['cancelled_at'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_reference': paymentReference,
      'created_at': Timestamp.fromDate(createdAt),
      'cancelled_at': cancelledAt != null
          ? Timestamp.fromDate(cancelledAt!)
          : null,
    };
  }
}

/// SME contact information for premium directory
class SMEContact {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String district;
  final String? subCounty;
  final String? village;
  final List<String> products; // Product categories they're interested in
  final DateTime registeredAt;
  final bool isVerified;
  final String? profileImage;

  SMEContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.district,
    this.subCounty,
    this.village,
    required this.products,
    required this.registeredAt,
    required this.isVerified,
    this.profileImage,
  });

  /// Create from Firestore user document
  factory SMEContact.fromFirestore(Map<String, dynamic> data, String id) {
    // Extract district from nested location object or fallback to direct field
    String districtValue = '';
    if (data['location'] != null && data['location'] is Map) {
      districtValue = (data['location'] as Map)['district'] ?? '';
    } else {
      districtValue = data['district'] ?? '';
    }

    // Extract subcounty and village from location object
    String? subCountyValue;
    String? villageValue;
    if (data['location'] != null && data['location'] is Map) {
      subCountyValue = (data['location'] as Map)['subcounty'];
      villageValue = (data['location'] as Map)['village'];
    } else {
      subCountyValue = data['sub_county'];
      villageValue = data['village'];
    }

    // ✅ FIXED: Safe timestamp conversion with type checking
    DateTime registeredAtValue = DateTime.now();
    final createdAtField = data['created_at'];
    if (createdAtField is Timestamp) {
      registeredAtValue = createdAtField.toDate();
    } else if (createdAtField is String) {
      // Try parsing if it's a string (shouldn't happen but handles edge case)
      try {
        registeredAtValue = DateTime.parse(createdAtField);
      } catch (e) {
        registeredAtValue = DateTime.now();
      }
    }

    return SMEContact(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      district: districtValue,
      subCounty: subCountyValue,
      village: villageValue,
      // Products will be populated separately from order history
      products: [],
      registeredAt: registeredAtValue,
      isVerified: data['is_verified'] ?? false,
      profileImage: data['profile_image'],
    );
  }
}
