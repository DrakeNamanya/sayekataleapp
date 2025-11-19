import 'package:flutter/foundation.dart';
// Import the PawaPayRepo class from pawa_pay_flutter package
import 'package:pawa_pay_flutter/pawa_pay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart' as app_transaction;

/// Mobile Money Operator types supported in Uganda
enum MobileMoneyOperator {
  mtn,
  airtel,
  unknown,
}

/// Payment status for tracking deposit lifecycle
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
  final String? depositId;

  PaymentResult({
    required this.status,
    this.transactionId,
    this.errorMessage,
    this.depositId,
  });

  bool get isSuccess => status == PaymentStatus.completed;
}

/// Service for handling PawaPay mobile money payments
class PawaPayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final PawaPayRepo _pawaPayRepo;
  final String _apiKey;
  final bool _debugMode;

  // Uganda price for premium subscription
  static const double premiumSubscriptionPrice = 50000.0; // UGX 50,000

  PawaPayService({
    required String apiKey,
    bool debugMode = false,
  })  : _apiKey = apiKey,
        _debugMode = debugMode {
    _pawaPayRepo = PawaPayRepo(
      apiKey: _apiKey,
      debugeMode: _debugMode,  // Note: package uses 'debugeMode' (with 'e')
    );
  }

  /// Detect Mobile Money Operator from phone number
  /// MTN: 077, 078, 039, 031
  /// Airtel: 070, 075, 020
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

    // MTN prefixes
    if (prefix == '077' ||
        prefix == '078' ||
        prefix == '039' ||
        prefix == '031') {
      return MobileMoneyOperator.mtn;
    }

    // Airtel prefixes
    if (prefix == '070' || prefix == '075' || prefix == '020') {
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

  /// Normalize phone number to format required by PawaPay (0XXXXXXXXX)
  String normalizePhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+256')) {
      return '0${cleaned.substring(4)}';
    } else if (cleaned.startsWith('256')) {
      return '0${cleaned.substring(3)}';
    } else if (cleaned.startsWith('0')) {
      return cleaned;
    }

    throw ArgumentError('Invalid phone number format: $phoneNumber');
  }

  /// Get operator display name
  String getOperatorName(MobileMoneyOperator operator) {
    switch (operator) {
      case MobileMoneyOperator.mtn:
        return 'MTN Mobile Money';
      case MobileMoneyOperator.airtel:
        return 'Airtel Money';
      case MobileMoneyOperator.unknown:
        return 'Unknown Operator';
    }
  }

  /// Initiate premium subscription payment
  Future<PaymentResult> initiatePremiumPayment({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      // Validate phone number
      if (!isValidPhoneNumber(phoneNumber)) {
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage: 'Invalid phone number format. Use +256XXXXXXXXX or 0XXXXXXXXX',
        );
      }

      // Detect operator
      final operator = detectOperator(phoneNumber);
      if (operator == MobileMoneyOperator.unknown) {
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage:
              'Could not detect mobile money operator. Please use MTN (077, 078) or Airtel (070, 075) number.',
        );
      }

      // Normalize phone number for PawaPay
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // Generate unique deposit ID
      const uuid = Uuid();
      final depositId = uuid.v4();

      if (kDebugMode) {
        debugPrint('🔄 Initiating PawaPay payment:');
        debugPrint('  User: $userId');
        debugPrint('  Phone: $normalizedPhone');
        debugPrint('  Operator: ${getOperatorName(operator)}');
        debugPrint('  Amount: UGX ${premiumSubscriptionPrice.toStringAsFixed(0)}');
        debugPrint('  Deposit ID: $depositId');
      }

      // Create pending transaction record
      await _createPendingTransaction(
        userId: userId,
        depositId: depositId,
        phoneNumber: phoneNumber,
        operator: operator,
      );

      // Initiate deposit with PawaPay
      // Note: Package method is 'customerDeposite' (with 'e')
      final purchaseStatus = await _pawaPayRepo.customerDeposite(
        phone: normalizedPhone,
        amount: premiumSubscriptionPrice,
      );

      if (kDebugMode) {
        debugPrint('📱 PawaPay Response: $purchaseStatus');
      }

      // Handle response
      return _handlePaymentResponse(
        purchaseStatus: purchaseStatus,
        userId: userId,
        depositId: depositId,
        operator: operator,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Payment initiation error: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      return PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: 'Payment initiation failed: ${e.toString()}',
      );
    }
  }

  /// Handle payment response from PawaPay
  PaymentResult _handlePaymentResponse({
    required String purchaseStatus,
    required String userId,
    required String depositId,
    required MobileMoneyOperator operator,
  }) {
    switch (purchaseStatus) {
      case 'PAYMENT_APPROVED':
        if (kDebugMode) {
          debugPrint('✅ Payment approved successfully');
        }
        // Update transaction status to completed
        _updateTransactionStatus(depositId, app_transaction.TransactionStatus.completed);
        return PaymentResult(
          status: PaymentStatus.completed,
          transactionId: depositId,
          depositId: depositId,
        );

      case 'PAYER_LIMIT_REACHED':
        if (kDebugMode) {
          debugPrint('⚠️ Payer limit reached');
        }
        _updateTransactionStatus(depositId, app_transaction.TransactionStatus.failed);
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage:
              'You have reached your ${getOperatorName(operator)} transaction limit. Please try again later or use a different number.',
          depositId: depositId,
        );

      case 'PAYMENT_NOT_APPROVED':
        if (kDebugMode) {
          debugPrint('⚠️ Payment not approved by customer');
        }
        _updateTransactionStatus(depositId, app_transaction.TransactionStatus.failed);
        return PaymentResult(
          status: PaymentStatus.cancelled,
          errorMessage: 'Payment was not approved. Please try again.',
          depositId: depositId,
        );

      case 'INSUFFICIENT_BALANCE':
        if (kDebugMode) {
          debugPrint('⚠️ Insufficient balance');
        }
        _updateTransactionStatus(depositId, app_transaction.TransactionStatus.failed);
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage:
              'Insufficient balance in your ${getOperatorName(operator)} wallet. Please top up and try again.',
          depositId: depositId,
        );

      default:
        if (kDebugMode) {
          debugPrint('❌ Unknown payment status: $purchaseStatus');
        }
        _updateTransactionStatus(depositId, app_transaction.TransactionStatus.failed);
        return PaymentResult(
          status: PaymentStatus.failed,
          errorMessage: 'Payment failed: $purchaseStatus',
          depositId: depositId,
        );
    }
  }

  /// Create pending transaction record in Firestore
  Future<void> _createPendingTransaction({
    required String userId,
    required String depositId,
    required String phoneNumber,
    required MobileMoneyOperator operator,
  }) async {
    try {
      final transaction = app_transaction.Transaction(
        id: depositId,
        type: app_transaction.TransactionType.shgPremiumSubscription,
        buyerId: userId,
        buyerName: 'User', // Will be updated with actual name
        sellerId: 'system',
        sellerName: 'SayeKatale Platform',
        amount: premiumSubscriptionPrice,
        serviceFee: 0.0,
        sellerReceives: premiumSubscriptionPrice,
        status: app_transaction.TransactionStatus.initiated,
        paymentMethod: operator == MobileMoneyOperator.mtn
            ? app_transaction.PaymentMethod.mtnMobileMoney
            : app_transaction.PaymentMethod.airtelMoney,
        paymentReference: depositId,
        createdAt: DateTime.now(),
        metadata: {
          'subscription_type': 'premium_sme_directory',
          'phone_number': phoneNumber,
          'operator': getOperatorName(operator),
          'deposit_id': depositId,
        },
      );

      await _firestore
          .collection('transactions')
          .doc(depositId)
          .set(transaction.toFirestore());

      if (kDebugMode) {
        debugPrint('✅ Transaction record created: $depositId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to create transaction record: $e');
      }
      // Don't throw - allow payment to continue even if transaction logging fails
    }
  }

  /// Update transaction status
  Future<void> _updateTransactionStatus(
    String depositId,
    app_transaction.TransactionStatus status,
  ) async {
    try {
      await _firestore.collection('transactions').doc(depositId).update({
        'status': status.toString().split('.').last,
        'completedAt':
            status == app_transaction.TransactionStatus.completed
                ? Timestamp.now()
                : null,
      });

      if (kDebugMode) {
        debugPrint('✅ Transaction status updated: $depositId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to update transaction status: $e');
      }
    }
  }

  /// Record successful payment in wallet
  Future<void> recordPaymentInWallet({
    required String userId,
    required String transactionId,
    required double amount,
  }) async {
    try {
      // Note: Wallet collection is backend-managed (firestore.rules prevents direct writes)
      // This method is here for future webhook integration
      // For now, wallet updates should be handled by backend webhook handler

      if (kDebugMode) {
        debugPrint('📝 Payment recorded: User $userId, Amount: UGX $amount');
        debugPrint('⚠️  Wallet updates should be handled by PawaPay webhook');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to record payment in wallet: $e');
      }
    }
  }

  /// Get transaction details
  Future<app_transaction.Transaction?> getTransaction(String depositId) async {
    try {
      final docSnapshot = await _firestore
          .collection('transactions')
          .doc(depositId)
          .get();

      if (!docSnapshot.exists) return null;

      return app_transaction.Transaction.fromFirestore(
        docSnapshot.data()!,
        docSnapshot.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error fetching transaction: $e');
      }
      return null;
    }
  }
}
