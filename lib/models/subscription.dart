import 'package:cloud_firestore/cloud_firestore.dart';

/// Subscription model for premium features and PSA access
class Subscription {
  final String id;
  final String userId;
  final String userName;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final double amount;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? transactionId;
  final DateTime? lastReminderSent;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Subscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.amount,
    required this.startDate,
    required this.expiryDate,
    this.transactionId,
    this.lastReminderSent,
    this.autoRenew = false,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  /// Create from Firestore document
  factory Subscription.fromFirestore(Map<String, dynamic> data, String id) {
    return Subscription(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${data['type']}',
        orElse: () => SubscriptionType.shgPremium,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == 'SubscriptionStatus.${data['status']}',
        orElse: () => SubscriptionStatus.active,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      transactionId: data['transactionId'],
      lastReminderSent: data['lastReminderSent'] != null
          ? (data['lastReminderSent'] as Timestamp).toDate()
          : null,
      autoRenew: data['autoRenew'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'amount': amount,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'transactionId': transactionId,
      'lastReminderSent': lastReminderSent != null
          ? Timestamp.fromDate(lastReminderSent!)
          : null,
      'autoRenew': autoRenew,
      'createdAt': Timestamp.fromDate(createdAt),
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
    };
  }

  /// Check if subscription is active
  bool get isActive {
    return status == SubscriptionStatus.active &&
           expiryDate.isAfter(DateTime.now());
  }

  /// Check if subscription is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 30;
  }

  /// Check if subscription has expired
  bool get hasExpired {
    return expiryDate.isBefore(DateTime.now());
  }

  /// Get days until expiry
  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// Get days until expiry message
  String get expiryMessage {
    final days = daysUntilExpiry;
    if (days < 0) {
      return 'Expired ${days.abs()} days ago';
    } else if (days == 0) {
      return 'Expires today';
    } else if (days == 1) {
      return 'Expires tomorrow';
    } else if (days <= 7) {
      return 'Expires in $days days';
    } else {
      return 'Expires on ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}';
    }
  }

  /// Create a copy with updated fields
  Subscription copyWith({
    SubscriptionStatus? status,
    DateTime? expiryDate,
    DateTime? lastReminderSent,
    bool? autoRenew,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      userName: userName,
      type: type,
      status: status ?? this.status,
      amount: amount,
      startDate: startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      transactionId: transactionId,
      lastReminderSent: lastReminderSent ?? this.lastReminderSent,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}

/// Types of subscriptions available
enum SubscriptionType {
  shgPremium,      // SHG premium access (UGX 50,000/year)
  psaAnnual,       // PSA annual subscription (UGX 120,000/year)
}

extension SubscriptionTypeExtension on SubscriptionType {
  String get displayName {
    switch (this) {
      case SubscriptionType.shgPremium:
        return 'Premium Membership';
      case SubscriptionType.psaAnnual:
        return 'PSA Subscription';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionType.shgPremium:
        return 'Access to SME buyer contacts filtered by product and district';
      case SubscriptionType.psaAnnual:
        return 'Post products and appear in marketplace';
    }
  }

  double get price {
    switch (this) {
      case SubscriptionType.shgPremium:
        return 50000.0;  // UGX 50,000
      case SubscriptionType.psaAnnual:
        return 120000.0; // UGX 120,000
    }
  }

  // Alias for price (used in services)
  double get amount => price;

  List<String> get benefits {
    switch (this) {
      case SubscriptionType.shgPremium:
        return [
          'Access to 200+ verified SME buyer contacts',
          'Filter buyers by product type',
          'Filter buyers by district',
          'Direct call and message to SMEs',
          'Valid for 365 days',
        ];
      case SubscriptionType.psaAnnual:
        return [
          'Post unlimited products',
          'Appear in marketplace search',
          'Verified badge on your profile',
          'Star icon next to your name',
          'Visible to SHG and SME buyers',
          'Valid for 365 days',
        ];
    }
  }

  String get icon {
    switch (this) {
      case SubscriptionType.shgPremium:
        return '🌟';
      case SubscriptionType.psaAnnual:
        return '✓';
    }
  }
}

/// Subscription status
enum SubscriptionStatus {
  active,          // Subscription is currently active
  expiringSoon,    // Less than 30 days until expiry
  expired,         // Subscription has expired
  suspended,       // Subscription suspended (payment failed, violation, etc.)
  cancelled,       // User cancelled subscription
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expiringSoon:
        return 'Expiring Soon';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Your subscription is active and all features are available';
      case SubscriptionStatus.expiringSoon:
        return 'Your subscription will expire soon. Renew now to continue access';
      case SubscriptionStatus.expired:
        return 'Your subscription has expired. Renew to restore access';
      case SubscriptionStatus.suspended:
        return 'Your subscription has been suspended. Contact support';
      case SubscriptionStatus.cancelled:
        return 'Your subscription has been cancelled';
    }
  }

  bool get requiresAction {
    return this == SubscriptionStatus.expiringSoon ||
           this == SubscriptionStatus.expired ||
           this == SubscriptionStatus.suspended;
  }

  bool get canRenew {
    return this == SubscriptionStatus.expiringSoon ||
           this == SubscriptionStatus.expired;
  }
}
