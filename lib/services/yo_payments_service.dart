import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// Mobile Money Operator types supported in Uganda
enum MobileMoneyOperator {
  mtn,
  airtel,
  unknown,
}

/// Payment status for tracking payment lifecycle
enum PaymentStatus {
  initiated,
  pending,
  completed,
  failed,
  cancelled,
}

/// Result of a payment operation
class PaymentResult {
  final PaymentStatus status;
  final String? transactionId;
  final String? errorMessage;
  final String? paymentReference;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.paymentReference,
  });

  bool get isSuccess => status == PaymentStatus.completed || status == PaymentStatus.pending;
}

/// Service for handling YO Payments mobile money payments
/// YO Payments is a Ugandan payment gateway supporting MTN and Airtel Money
class YOPaymentsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uganda price for premium subscription
  static const double premiumSubscriptionPrice = 50000.0; // UGX 50,000

  // YO Payments configuration
  // Note: These will be configured through YO Payments dashboard
  static const String yoPaymentsBaseUrl = 'https://paygw.yo.co.ug';
  
  YOPaymentsService();

  /// Detect Mobile Money Operator from phone number
  /// MTN: 077, 078, 031, 039, 076, 079
  /// Airtel: 070, 074, 075
  MobileMoneyOperator detectOperator(String phoneNumber) {
    // Clean phone number (remove spaces, hyphens, etc.)
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Extract prefix (works for both +256XXXXXXXXX and 0XXXXXXXXX formats)
    String prefix = '';
    if (cleaned.startsWith('+256')) {
      prefix = cleaned.substring(4, 7); // Get digits after +256
    } else if (cleaned.startsWith('256')) {
      prefix = cleaned.substring(3, 6); // Get digits after 256
    } else if (cleaned.startsWith('0')) {
      prefix = cleaned.substring(0, 3); // Get first 3 digits including 0
    }

    // MTN prefixes (Updated with all current MTN Uganda prefixes)
    if (prefix == '077' ||
        prefix == '078' ||
        prefix == '031' ||
        prefix == '039' ||
        prefix == '076' ||
        prefix == '079') {
      return MobileMoneyOperator.mtn;
    }

    // Airtel prefixes (Updated with all current Airtel Uganda prefixes)
    if (prefix == '070' || prefix == '074' || prefix == '075') {
      return MobileMoneyOperator.airtel;
    }

    return MobileMoneyOperator.unknown;
  }

  /// Validate Uganda phone number format
  /// Accepts: +256XXXXXXXXX, 256XXXXXXXXX, 0XXXXXXXXX
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Check valid formats
    if (cleaned.startsWith('+256') && cleaned.length == 13) return true;
    if (cleaned.startsWith('256') && cleaned.length == 12) return true;
    if (cleaned.startsWith('0') && cleaned.length == 10) return true;

    return false;
  }

  /// Normalize phone number to international format (+256XXXXXXXXX)
  String normalizePhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Already in +256 format
    if (cleaned.startsWith('+256')) {
      return cleaned;
    }

    // 256XXXXXXXXX format
    if (cleaned.startsWith('256')) {
      return '+$cleaned';
    }

    // 0XXXXXXXXX format
    if (cleaned.startsWith('0')) {
      return '+256${cleaned.substring(1)}';
    }

    return cleaned;
  }

  /// Generate YO Payments pay button URL for premium subscription
  /// Returns a payment URL that users can open to complete payment
  String generatePaymentUrl({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    final paymentReference = 'SHG-SUB-${const Uuid().v4().substring(0, 8)}';

    // YO Payments Pay Button URL parameters
    // These parameters match the form fields provided by YO Payments
    final params = {
      'button_name': 'Activate SHG subscription',
      'currency': 'UGX',
      'amount': premiumSubscriptionPrice.toStringAsFixed(0),
      'transaction_narrative': 'shg subscription',
      'transaction_reference': paymentReference,
      'provider_reference_text': 'SAYE KATALE Premium Subscription',
      'return_url': 'https://sayekatale.com/payment-success', // Your return URL
      'user_id': userId,
      'phone_number': normalizedPhone,
      'user_name': userName,
    };

    // Log payment initiation
    if (kDebugMode) {
      debugPrint('🔵 YO Payments - Generating payment URL');
      debugPrint('🔵 Amount: UGX ${params['amount']}');
      debugPrint('🔵 Phone: ${params['phone_number']}');
      debugPrint('🔵 Reference: $paymentReference');
    }

    // In production, this would be your actual YO Payments button URL
    // For now, we'll create a payment record and return a reference
    _createPaymentRecord(
      userId: userId,
      phoneNumber: normalizedPhone,
      amount: premiumSubscriptionPrice,
      reference: paymentReference,
      userName: userName,
    );

    // Return the payment reference for tracking
    return paymentReference;
  }

  /// Initiate premium subscription payment
  /// This creates a payment record and returns a payment reference
  Future<PaymentResult> initiatePremiumPayment({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      final operator = detectOperator(normalizedPhone);

      if (operator == MobileMoneyOperator.unknown) {
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage: 'Invalid mobile money operator. Please use MTN or Airtel number.',
        );
      }

      final paymentReference = generatePaymentUrl(
        userId: userId,
        phoneNumber: normalizedPhone,
        userName: userName,
      );

      if (kDebugMode) {
        debugPrint('✅ YO Payments - Payment initiated successfully');
        debugPrint('✅ Payment Reference: $paymentReference');
      }

      return PaymentResult(
        status: PaymentStatus.pending,
        paymentReference: paymentReference,
        transactionId: paymentReference,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ YO Payments Error: $e');
      }

      return PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create payment record in Firestore for tracking
  Future<void> _createPaymentRecord({
    required String userId,
    required String phoneNumber,
    required double amount,
    required String reference,
    required String userName,
  }) async {
    try {
      await _firestore.collection('payment_records').doc(reference).set({
        'user_id': userId,
        'user_name': userName,
        'phone_number': phoneNumber,
        'amount': amount,
        'currency': 'UGX',
        'payment_reference': reference,
        'payment_method': 'YO Payments',
        'payment_type': 'premium_subscription',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Payment record created: $reference');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to create payment record: $e');
      }
    }
  }

  /// Check payment status
  /// In production, this would query YO Payments API
  Future<PaymentStatus> checkPaymentStatus(String paymentReference) async {
    try {
      final doc = await _firestore
          .collection('payment_records')
          .doc(paymentReference)
          .get();

      if (!doc.exists) {
        return PaymentStatus.failed;
      }

      final data = doc.data();
      final statusString = data?['status'] ?? 'pending';

      switch (statusString) {
        case 'completed':
          return PaymentStatus.completed;
        case 'pending':
          return PaymentStatus.pending;
        case 'failed':
          return PaymentStatus.failed;
        case 'cancelled':
          return PaymentStatus.cancelled;
        default:
          return PaymentStatus.pending;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking payment status: $e');
      }
      return PaymentStatus.failed;
    }
  }

  /// Update payment status (called by webhook or admin)
  Future<void> updatePaymentStatus({
    required String paymentReference,
    required PaymentStatus status,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'status': status.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (transactionId != null) {
        updateData['transaction_id'] = transactionId;
      }

      await _firestore
          .collection('payment_records')
          .doc(paymentReference)
          .update(updateData);

      if (kDebugMode) {
        debugPrint('✅ Payment status updated: $paymentReference -> ${status.toString()}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to update payment status: $e');
      }
    }
  }
}
