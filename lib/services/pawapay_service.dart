import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// PawaPay Mobile Money Payment Service
/// Handles deposits, payouts, and refunds via PawaPay API
class PawaPayService {
  // PawaPay API Configuration
  static const String _sandboxBaseUrl = 'https://api.sandbox.pawapay.cloud';
  static const String _productionBaseUrl = 'https://api.pawapay.cloud';
  
  // Get API base URL based on environment
  String get _baseUrl => kDebugMode ? _sandboxBaseUrl : _productionBaseUrl;
  
  // API Token (should be stored securely in production)
  // TODO: Move to environment variables or secure storage
  final String _apiToken;
  
  final Uuid _uuid = const Uuid();
  
  PawaPayService({required String apiToken}) : _apiToken = apiToken;
  
  // ============================================================================
  // DEPOSIT (Collect money from customer)
  // ============================================================================
  
  /// Initiate a mobile money deposit (customer pays)
  /// Returns deposit ID for tracking
  Future<Map<String, dynamic>> initiateDeposit({
    required double amount,
    required String currency,
    required String phoneNumber,
    required String correspondentId, // e.g., 'MTN_MOMO_UGA' for MTN Uganda
    required String description,
    String? customerName,
  }) async {
    try {
      final depositId = _uuid.v4();
      
      final requestBody = {
        'depositId': depositId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
        'correspondent': correspondentId,
        'payer': {
          'type': 'MSISDN',
          'address': {
            'value': _formatPhoneNumber(phoneNumber),
          },
        },
        'customerTimestamp': DateTime.now().toUtc().toIso8601String(),
        'statementDescription': description,
      };
      
      if (customerName != null) {
        requestBody['payer']['displayName'] = customerName;
      }
      
      if (kDebugMode) {
        debugPrint('🔵 PawaPay Deposit Request: $depositId');
        debugPrint('   Amount: $currency $amount');
        debugPrint('   Phone: $phoneNumber');
        debugPrint('   Provider: $correspondentId');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/deposits'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (kDebugMode) {
        debugPrint('📥 PawaPay Response: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'depositId': depositId,
          'status': 'ACCEPTED',
          'message': 'Deposit initiated. Customer will receive payment prompt on phone.',
        };
      } else if (response.statusCode == 202) {
        return {
          'success': true,
          'depositId': depositId,
          'status': 'SUBMITTED',
          'message': 'Deposit submitted for processing.',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Deposit failed',
          'errorCode': errorData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PawaPay Deposit Error: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  // ============================================================================
  // PAYOUT (Send money to user)
  // ============================================================================
  
  /// Initiate a mobile money payout (send money to user)
  /// Returns payout ID for tracking
  Future<Map<String, dynamic>> initiatePayout({
    required double amount,
    required String currency,
    required String phoneNumber,
    required String correspondentId,
    required String description,
    String? recipientName,
  }) async {
    try {
      final payoutId = _uuid.v4();
      
      final requestBody = {
        'payoutId': payoutId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
        'correspondent': correspondentId,
        'recipient': {
          'type': 'MSISDN',
          'address': {
            'value': _formatPhoneNumber(phoneNumber),
          },
        },
        'customerTimestamp': DateTime.now().toUtc().toIso8601String(),
        'statementDescription': description,
      };
      
      if (recipientName != null) {
        requestBody['recipient']['displayName'] = recipientName;
      }
      
      if (kDebugMode) {
        debugPrint('🟢 PawaPay Payout Request: $payoutId');
        debugPrint('   Amount: $currency $amount');
        debugPrint('   Phone: $phoneNumber');
        debugPrint('   Provider: $correspondentId');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/payouts'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (kDebugMode) {
        debugPrint('📥 PawaPay Response: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
      }
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'payoutId': payoutId,
          'status': 'ACCEPTED',
          'message': 'Payout initiated successfully.',
        };
      } else if (response.statusCode == 202) {
        return {
          'success': true,
          'payoutId': payoutId,
          'status': 'SUBMITTED',
          'message': 'Payout submitted for processing.',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Payout failed',
          'errorCode': errorData['code'],
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PawaPay Payout Error: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  // ============================================================================
  // STATUS CHECK
  // ============================================================================
  
  /// Check deposit status
  Future<Map<String, dynamic>> checkDepositStatus(String depositId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/deposits/$depositId'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to check status',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Check Deposit Status Error: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  /// Check payout status
  Future<Map<String, dynamic>> checkPayoutStatus(String payoutId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payouts/$payoutId'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'status': data['status'],
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to check status',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Check Payout Status Error: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  // ============================================================================
  // REFUND
  // ============================================================================
  
  /// Initiate a refund for a previous deposit
  Future<Map<String, dynamic>> initiateRefund({
    required String depositId,
    required double amount,
  }) async {
    try {
      final refundId = _uuid.v4();
      
      final requestBody = {
        'refundId': refundId,
        'depositId': depositId,
        'amount': amount.toStringAsFixed(2),
      };
      
      if (kDebugMode) {
        debugPrint('🔴 PawaPay Refund Request: $refundId');
        debugPrint('   Deposit ID: $depositId');
        debugPrint('   Amount: $amount');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/refunds'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'refundId': refundId,
          'message': 'Refund initiated successfully.',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData['message'] ?? 'Refund failed',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ PawaPay Refund Error: $e');
      }
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Format phone number for PawaPay (international format without + sign)
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If starts with 0, replace with country code (Uganda: 256)
    if (cleaned.startsWith('0')) {
      cleaned = '256${cleaned.substring(1)}';
    }
    
    // If doesn't start with country code, add it
    if (!cleaned.startsWith('256')) {
      cleaned = '256$cleaned';
    }
    
    return cleaned;
  }
  
  /// Get supported correspondents (mobile money operators) for Uganda
  static List<Map<String, String>> getSupportedCorrespondents() {
    return [
      {
        'id': 'MTN_MOMO_UGA',
        'name': 'MTN Mobile Money',
        'country': 'Uganda',
      },
      {
        'id': 'AIRTEL_OAPI_UGA',
        'name': 'Airtel Money',
        'country': 'Uganda',
      },
    ];
  }
}
