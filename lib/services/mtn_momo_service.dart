import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// MTN Mobile Money API integration service
/// Handles payment collection and disbursement
class MtnMomoService {
  // MTN MoMo API Configuration
  static const String _sandboxBaseUrl = 'https://sandbox.momodeveloper.mtn.com';
  static const String _productionBaseUrl = 'https://momodeveloper.mtn.com';

  // Collection API Credentials (Receive Payments)
  static const String _collectionApiKey = '671e6e6fda93459987a2c8a9a4ac17ec';
  static const String _collectionSecondaryKey =
      'f509a9d571254950a07d8c074afa9715';
  static const String _collectionSubscriptionKey =
      '671e6e6fda93459987a2c8a9a4ac17ec';

  // Disbursement API Credentials (Send Payments)
  static const String _disbursementApiKey = 'b37dc5e1948f4f8dab7e8e882867c1d1';
  static const String _disbursementSecondaryKey =
      '52d54ed5795f4bb39b9d3c8c0458aabb';
  static const String _disbursementSubscriptionKey =
      'b37dc5e1948f4f8dab7e8e882867c1d1';

  // Environment configuration
  bool _useSandbox = true;
  String? _collectionAccessToken;
  String? _disbursementAccessToken;
  DateTime? _collectionTokenExpiry;
  DateTime? _disbursementTokenExpiry;

  final Uuid _uuid = const Uuid();

  /// Constructor
  MtnMomoService({bool useSandbox = true}) : _useSandbox = useSandbox;

  /// Get base URL based on environment
  String get _baseUrl => _useSandbox ? _sandboxBaseUrl : _productionBaseUrl;

  /// Switch between sandbox and production
  void setEnvironment(bool useSandbox) {
    _useSandbox = useSandbox;
    // Clear tokens when switching environments
    _collectionAccessToken = null;
    _disbursementAccessToken = null;
    if (kDebugMode) {
      debugPrint(
        '🔄 MTN MoMo environment: ${useSandbox ? 'SANDBOX' : 'PRODUCTION'}',
      );
    }
  }

  // ============================================================================
  // AUTHENTICATION
  // ============================================================================

  /// Get Collection API access token
  Future<String> _getCollectionAccessToken() async {
    // Return cached token if still valid
    if (_collectionAccessToken != null &&
        _collectionTokenExpiry != null &&
        DateTime.now().isBefore(_collectionTokenExpiry!)) {
      return _collectionAccessToken!;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/collection/token/'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_collectionApiKey:$_collectionSecondaryKey'))}',
          'Ocp-Apim-Subscription-Key': _collectionSubscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _collectionAccessToken = data['access_token'];

        // Token typically valid for 1 hour, refresh 5 minutes before expiry
        _collectionTokenExpiry = DateTime.now().add(
          const Duration(minutes: 55),
        );

        if (kDebugMode) {
          debugPrint('✅ Collection access token obtained');
        }
        return _collectionAccessToken!;
      } else {
        throw MtnMomoException(
          'Failed to get collection access token: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException('Error obtaining collection token', e.toString());
    }
  }

  /// Get Disbursement API access token
  Future<String> _getDisbursementAccessToken() async {
    // Return cached token if still valid
    if (_disbursementAccessToken != null &&
        _disbursementTokenExpiry != null &&
        DateTime.now().isBefore(_disbursementTokenExpiry!)) {
      return _disbursementAccessToken!;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/disbursement/token/'),
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$_disbursementApiKey:$_disbursementSecondaryKey'))}',
          'Ocp-Apim-Subscription-Key': _disbursementSubscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _disbursementAccessToken = data['access_token'];

        // Token typically valid for 1 hour, refresh 5 minutes before expiry
        _disbursementTokenExpiry = DateTime.now().add(
          const Duration(minutes: 55),
        );

        if (kDebugMode) {
          debugPrint('✅ Disbursement access token obtained');
        }
        return _disbursementAccessToken!;
      } else {
        throw MtnMomoException(
          'Failed to get disbursement access token: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException(
        'Error obtaining disbursement token',
        e.toString(),
      );
    }
  }

  // ============================================================================
  // PAYMENT COLLECTION (Request money from users)
  // ============================================================================

  /// Request payment from user (Collection)
  ///
  /// [amount] - Amount to collect
  /// [phoneNumber] - User's phone number (format: 256XXXXXXXXX)
  /// [payerMessage] - Message shown to payer
  /// [payeeNote] - Internal note for payee
  ///
  /// Returns transaction reference ID
  Future<String> requestPayment({
    required double amount,
    required String phoneNumber,
    required String payerMessage,
    String? payeeNote,
  }) async {
    try {
      final accessToken = await _getCollectionAccessToken();
      final referenceId = _uuid.v4();

      // Format phone number (remove leading + or 0, ensure starts with country code)
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '256${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('256')) {
        formattedPhone = '256$formattedPhone';
      }

      final requestBody = {
        'amount': amount.toStringAsFixed(0),
        'currency': 'UGX',
        'externalId': referenceId,
        'payer': {'partyIdType': 'MSISDN', 'partyId': formattedPhone},
        'payerMessage': payerMessage,
        'payeeNote': payeeNote ?? 'Payment for Poultry Link order',
      };

      if (kDebugMode) {
        debugPrint(
          '💳 Requesting payment: UGX ${amount.toStringAsFixed(0)} from $formattedPhone',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/collection/v1_0/requesttopay'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Reference-Id': referenceId,
          'X-Target-Environment': _useSandbox ? 'sandbox' : 'live',
          'Ocp-Apim-Subscription-Key': _collectionSubscriptionKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 202) {
        if (kDebugMode) {
          debugPrint('✅ Payment request sent successfully: $referenceId');
        }
        return referenceId;
      } else {
        throw MtnMomoException(
          'Payment request failed: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException('Error requesting payment', e.toString());
    }
  }

  /// Check payment status
  ///
  /// [referenceId] - Transaction reference ID from requestPayment
  ///
  /// Returns payment status information
  Future<PaymentStatus> checkPaymentStatus(String referenceId) async {
    try {
      final accessToken = await _getCollectionAccessToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/collection/v1_0/requesttopay/$referenceId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Target-Environment': _useSandbox ? 'sandbox' : 'live',
          'Ocp-Apim-Subscription-Key': _collectionSubscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentStatus.fromJson(data);
      } else {
        throw MtnMomoException(
          'Failed to check payment status: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException('Error checking payment status', e.toString());
    }
  }

  // ============================================================================
  // DISBURSEMENT (Send money to users)
  // ============================================================================

  /// Send money to user (Disbursement)
  ///
  /// [amount] - Amount to send
  /// [phoneNumber] - Recipient's phone number (format: 256XXXXXXXXX)
  /// [payeeNote] - Message shown to recipient
  /// [payerMessage] - Internal note
  ///
  /// Returns transaction reference ID
  Future<String> sendPayment({
    required double amount,
    required String phoneNumber,
    required String payeeNote,
    String? payerMessage,
  }) async {
    try {
      final accessToken = await _getDisbursementAccessToken();
      final referenceId = _uuid.v4();

      // Format phone number
      String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '256${formattedPhone.substring(1)}';
      } else if (!formattedPhone.startsWith('256')) {
        formattedPhone = '256$formattedPhone';
      }

      final requestBody = {
        'amount': amount.toStringAsFixed(0),
        'currency': 'UGX',
        'externalId': referenceId,
        'payee': {'partyIdType': 'MSISDN', 'partyId': formattedPhone},
        'payerMessage': payerMessage ?? 'Payment from Poultry Link',
        'payeeNote': payeeNote,
      };

      if (kDebugMode) {
        debugPrint(
          '💸 Sending payment: UGX ${amount.toStringAsFixed(0)} to $formattedPhone',
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/disbursement/v1_0/transfer'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Reference-Id': referenceId,
          'X-Target-Environment': _useSandbox ? 'sandbox' : 'live',
          'Ocp-Apim-Subscription-Key': _disbursementSubscriptionKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 202) {
        if (kDebugMode) {
          debugPrint('✅ Payment sent successfully: $referenceId');
        }
        return referenceId;
      } else {
        throw MtnMomoException(
          'Payment disbursement failed: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException('Error sending payment', e.toString());
    }
  }

  /// Check disbursement status
  ///
  /// [referenceId] - Transaction reference ID from sendPayment
  ///
  /// Returns disbursement status information
  Future<PaymentStatus> checkDisbursementStatus(String referenceId) async {
    try {
      final accessToken = await _getDisbursementAccessToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/disbursement/v1_0/transfer/$referenceId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Target-Environment': _useSandbox ? 'sandbox' : 'live',
          'Ocp-Apim-Subscription-Key': _disbursementSubscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentStatus.fromJson(data);
      } else {
        throw MtnMomoException(
          'Failed to check disbursement status: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException(
        'Error checking disbursement status',
        e.toString(),
      );
    }
  }

  // ============================================================================
  // ACCOUNT BALANCE
  // ============================================================================

  /// Get collection account balance
  Future<double> getCollectionBalance() async {
    try {
      final accessToken = await _getCollectionAccessToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/collection/v1_0/account/balance'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-Target-Environment': _useSandbox ? 'sandbox' : 'live',
          'Ocp-Apim-Subscription-Key': _collectionSubscriptionKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.tryParse(data['availableBalance']) ?? 0.0;
      } else {
        throw MtnMomoException(
          'Failed to get balance: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw MtnMomoException('Error getting balance', e.toString());
    }
  }
}

// ============================================================================
// PAYMENT STATUS MODEL
// ============================================================================

class PaymentStatus {
  final String status;
  final String? financialTransactionId;
  final String? externalId;
  final double? amount;
  final String? currency;
  final String? reason;

  PaymentStatus({
    required this.status,
    this.financialTransactionId,
    this.externalId,
    this.amount,
    this.currency,
    this.reason,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      status: json['status'] ?? 'UNKNOWN',
      financialTransactionId: json['financialTransactionId'],
      externalId: json['externalId'],
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      currency: json['currency'],
      reason: json['reason'],
    );
  }

  bool get isSuccessful => status == 'SUCCESSFUL';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}

// ============================================================================
// EXCEPTION HANDLING
// ============================================================================

class MtnMomoException implements Exception {
  final String message;
  final String? details;

  MtnMomoException(this.message, [this.details]);

  @override
  String toString() {
    if (details != null) {
      return 'MtnMomoException: $message\nDetails: $details';
    }
    return 'MtnMomoException: $message';
  }
}
