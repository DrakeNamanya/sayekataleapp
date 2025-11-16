import 'order.dart';

/// Extension methods for OrderStatus compatibility and mapping
extension OrderStatusExtensions on OrderStatus {
  /// Check if status is a legacy status
  bool get isLegacyStatus {
    return this == OrderStatus.preparing ||
        this == OrderStatus.ready ||
        this == OrderStatus.inTransit ||
        this == OrderStatus.delivered ||
        this == OrderStatus.rejected;
  }

  /// Check if status is a monetization status
  bool get isMonetizationStatus {
    return this == OrderStatus.paymentPending ||
        this == OrderStatus.paymentHeld ||
        this == OrderStatus.deliveryPending ||
        this == OrderStatus.deliveredPendingConfirmation ||
        this == OrderStatus.codPendingBothConfirmation ||
        this == OrderStatus.codOverdue;
  }

  /// Map legacy status to monetization status
  OrderStatus get toMonetizationStatus {
    switch (this) {
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.inTransit:
        return OrderStatus.deliveryPending;
      case OrderStatus.delivered:
        return OrderStatus.deliveredPendingConfirmation;
      case OrderStatus.rejected:
        return OrderStatus.cancelled;
      default:
        return this;
    }
  }

  /// Map monetization status to legacy status (for backward compatibility)
  OrderStatus get toLegacyStatus {
    switch (this) {
      case OrderStatus.paymentPending:
      case OrderStatus.paymentHeld:
        return OrderStatus.pending;
      case OrderStatus.deliveryPending:
        return OrderStatus.inTransit;
      case OrderStatus.deliveredPendingConfirmation:
        return OrderStatus.delivered;
      case OrderStatus.codPendingBothConfirmation:
      case OrderStatus.codOverdue:
        return OrderStatus.delivered;
      default:
        return this;
    }
  }

  /// Get display color for status
  String get displayColor {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
        return 'orange';
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.paymentHeld:
      case OrderStatus.deliveryPending:
      case OrderStatus.inTransit:
        return 'blue';
      case OrderStatus.delivered:
      case OrderStatus.deliveredPendingConfirmation:
      case OrderStatus.codPendingBothConfirmation:
        return 'purple';
      case OrderStatus.confirmed:
      case OrderStatus.completed:
        return 'green';
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
      case OrderStatus.codOverdue:
        return 'red';
    }
  }

  /// Check if order is in active state
  bool get isActive {
    return this != OrderStatus.completed &&
        this != OrderStatus.cancelled &&
        this != OrderStatus.rejected;
  }

  /// Check if order is completed
  bool get isCompleted {
    return this == OrderStatus.completed || this == OrderStatus.confirmed;
  }

  /// Check if order is cancelled or rejected
  bool get isCancelled {
    return this == OrderStatus.cancelled || this == OrderStatus.rejected;
  }
}

/// Extension methods for PaymentMethod compatibility and mapping
extension PaymentMethodExtensions on PaymentMethod {
  /// Check if payment method is legacy
  bool get isLegacyMethod {
    return this == PaymentMethod.cash ||
        this == PaymentMethod.mobileMoney ||
        this == PaymentMethod.bankTransfer;
  }

  /// Check if payment method is monetization method
  bool get isMonetizationMethod {
    return this == PaymentMethod.mtnMobileMoney ||
        this == PaymentMethod.airtelMoney ||
        this == PaymentMethod.cashOnDelivery;
  }

  /// Map legacy method to monetization method
  PaymentMethod get toMonetizationMethod {
    switch (this) {
      case PaymentMethod.cash:
        return PaymentMethod.cashOnDelivery;
      case PaymentMethod.mobileMoney:
        return PaymentMethod.mtnMobileMoney;
      case PaymentMethod.bankTransfer:
        return PaymentMethod.mtnMobileMoney; // Default to MTN MoMo
      default:
        return this;
    }
  }

  /// Map monetization method to legacy method (for backward compatibility)
  PaymentMethod get toLegacyMethod {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return PaymentMethod.cash;
      case PaymentMethod.mtnMobileMoney:
      case PaymentMethod.airtelMoney:
        return PaymentMethod.mobileMoney;
      default:
        return this;
    }
  }

  /// Get icon name for payment method
  String get iconName {
    switch (this) {
      case PaymentMethod.mtnMobileMoney:
        return 'mtn_momo';
      case PaymentMethod.airtelMoney:
        return 'airtel_money';
      case PaymentMethod.cashOnDelivery:
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.mobileMoney:
        return 'mobile_money';
      case PaymentMethod.bankTransfer:
        return 'bank';
    }
  }

  /// Check if method requires online payment
  bool get requiresOnlinePayment {
    return this == PaymentMethod.mtnMobileMoney ||
        this == PaymentMethod.airtelMoney ||
        this == PaymentMethod.mobileMoney ||
        this == PaymentMethod.bankTransfer;
  }

  /// Check if method is cash-based
  bool get isCashBased {
    return this == PaymentMethod.cash || this == PaymentMethod.cashOnDelivery;
  }

  /// Get display name for payment method
  String get displayName {
    switch (this) {
      case PaymentMethod.mtnMobileMoney:
        return 'MTN Mobile Money';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  /// Get description for payment method
  String get description {
    switch (this) {
      case PaymentMethod.mtnMobileMoney:
        return 'Pay using MTN Mobile Money';
      case PaymentMethod.airtelMoney:
        return 'Pay using Airtel Money (Coming Soon)';
      case PaymentMethod.cashOnDelivery:
        return 'Pay with cash when order is delivered';
      case PaymentMethod.cash:
        return 'Pay with cash';
      case PaymentMethod.mobileMoney:
        return 'Pay using Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Pay using Bank Transfer';
    }
  }

  /// Get short name for payment method
  String get shortName {
    switch (this) {
      case PaymentMethod.mtnMobileMoney:
        return 'MTN MoMo';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.cashOnDelivery:
        return 'COD';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  /// Get icon asset path for payment method
  String get iconAsset {
    switch (this) {
      case PaymentMethod.mtnMobileMoney:
        return 'assets/icons/mtn_momo.png';
      case PaymentMethod.airtelMoney:
        return 'assets/icons/airtel_money.png';
      case PaymentMethod.cashOnDelivery:
        return 'assets/icons/cod.png';
      case PaymentMethod.cash:
        return 'assets/icons/cash.png';
      case PaymentMethod.mobileMoney:
        return 'assets/icons/mobile_money.png';
      case PaymentMethod.bankTransfer:
        return 'assets/icons/bank.png';
    }
  }

  /// Check if payment method is digital/online payment
  bool get isDigitalPayment {
    return this == PaymentMethod.mtnMobileMoney ||
        this == PaymentMethod.airtelMoney ||
        this == PaymentMethod.mobileMoney;
  }
}
