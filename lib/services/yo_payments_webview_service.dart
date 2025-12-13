import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling YO Payments web-based payments
/// Uses actual YO Payments button configuration (bid: 390)
class YOPaymentsWebViewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // YO Payments configuration (from provided button)
  static const String yoPaymentsEndpoint = 'https://payments.yo.co.ug/webexpress/';
  static const String buttonId = '390';
  static const String accountNumber = '100356616098';
  static const double subscriptionAmount = 50000.0; // UGX
  static const String narrative = 'shg subscription';
  static const String reference = 'SAYE KATALE Premium Subscription';
  static const String providerReferenceText = 
      'Your payment for the SAYE Katale Premium Subscription has been received. Transaction completed successfully.';

  /// Generate unique transaction reference
  String generateTransactionReference() {
    return 'SHG-SUB-${const Uuid().v4().substring(0, 12).toUpperCase()}';
  }

  /// Create payment record in Firestore
  Future<String> createPaymentRecord({
    required String userId,
    required String phoneNumber,
    required String transactionRef,
  }) async {
    try {
      final paymentData = {
        'userId': userId,
        'phoneNumber': phoneNumber,
        'amount': subscriptionAmount,
        'currency': 'UGX',
        'status': 'PENDING',
        'paymentMethod': 'YO Payments - Mobile Money',
        'transactionReference': transactionRef,
        'description': 'Premium SHG subscription - 1 year access to SME directory',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'subscriptionType': 'sme_directory',
          'paymentGateway': 'YO Payments',
          'buttonId': buttonId,
        },
      };

      final docRef = await _firestore.collection('payments').add(paymentData);

      if (kDebugMode) {
        debugPrint('✅ Payment record created: ${docRef.id}');
        debugPrint('📄 Transaction Reference: $transactionRef');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating payment record: $e');
      }
      rethrow;
    }
  }

  /// Launch YO Payments page
  /// Opens YO Payments checkout in external browser or in-app browser
  Future<bool> launchPayment({
    required String userId,
    required String phoneNumber,
    required String userName,
  }) async {
    try {
      // Generate unique transaction reference
      final transactionRef = generateTransactionReference();

      // Create payment record in Firestore
      await createPaymentRecord(
        userId: userId,
        phoneNumber: phoneNumber,
        transactionRef: transactionRef,
      );

      // Build YO Payments payment URL with form parameters
      // Note: YO Payments expects a POST form submission, but we can try GET parameters
      // If this doesn't work, we'll need to use a web view or create an HTML page
      final returnUrl = Uri.encodeComponent(
        'https://sayekataleapp.web.app/payment-success?unique_transaction_id=\$unique_transaction_id&transaction_reference=$transactionRef'
      );

      final paymentUrl = Uri.parse(
        '$yoPaymentsEndpoint?'
        'bid=$buttonId&'
        'currency=UGX&'
        'amount=${subscriptionAmount.toInt()}&'
        'narrative=${Uri.encodeComponent(narrative)}&'
        'reference=${Uri.encodeComponent(reference)}&'
        'provider_reference_text=${Uri.encodeComponent(providerReferenceText)}&'
        'account=$accountNumber&'
        'return=$returnUrl&'
        'prefilled_payer_mobile_payment_msisdn=${Uri.encodeComponent(phoneNumber)}&'
        'prefilled_payer_names=${Uri.encodeComponent(userName)}'
      );

      if (kDebugMode) {
        debugPrint('🌐 Launching YO Payments URL:');
        debugPrint(paymentUrl.toString());
        debugPrint('📱 Phone: $phoneNumber');
        debugPrint('👤 Name: $userName');
        debugPrint('🆔 Transaction Ref: $transactionRef');
      }

      // Launch URL in external browser
      if (await canLaunchUrl(paymentUrl)) {
        final launched = await launchUrl(
          paymentUrl,
          mode: LaunchMode.externalApplication, // Open in external browser
        );

        if (kDebugMode) {
          if (launched) {
            debugPrint('✅ YO Payments page launched successfully');
          } else {
            debugPrint('❌ Failed to launch YO Payments page');
          }
        }

        return launched;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Cannot launch URL: $paymentUrl');
        }
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Error launching payment: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Alternative method: Generate HTML form page
  /// This creates an auto-submitting HTML form (like the button you provided)
  String generateHtmlForm({
    required String transactionRef,
    required String phoneNumber,
    required String userName,
  }) {
    final returnUrl = 'https://sayekataleapp.web.app/payment-success?unique_transaction_id=0&transaction_reference=$transactionRef';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>YO Payments - SAYE KATALE</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }
    .container {
      text-align: center;
      background: white;
      padding: 40px;
      border-radius: 20px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
      max-width: 400px;
    }
    .logo {
      font-size: 32px;
      font-weight: bold;
      color: #667eea;
      margin-bottom: 20px;
    }
    .message {
      font-size: 18px;
      color: #333;
      margin-bottom: 30px;
    }
    .spinner {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #667eea;
      border-radius: 50%;
      width: 50px;
      height: 50px;
      animation: spin 1s linear infinite;
      margin: 0 auto 20px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .details {
      font-size: 14px;
      color: #666;
      margin-top: 20px;
      padding: 15px;
      background: #f5f5f5;
      border-radius: 8px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">SAYE KATALE</div>
    <div class="spinner"></div>
    <div class="message">Redirecting to YO Payments...</div>
    <div class="details">
      <strong>Transaction Reference:</strong><br>
      $transactionRef<br><br>
      <strong>Amount:</strong> UGX 50,000
    </div>
  </div>

  <div align="center">
    <form id="paymentForm" method="post" style="margin:0px" action="$yoPaymentsEndpoint">
      <input type="hidden" name="bid" value="$buttonId" />
      <input type="hidden" name="currency" value="UGX" />
      <input type="hidden" name="amount" value="${subscriptionAmount.toInt()}" />
      <input type="hidden" name="narrative" value="$narrative" />
      <input type="hidden" name="reference" value="$reference" />
      <input type="hidden" name="provider_reference_text" value="$providerReferenceText" />
      <input type="hidden" name="account" value="$accountNumber" />
      <input type="hidden" name="return" value="$returnUrl" />
      <input type="hidden" name="prefilled_payer_email_address" value="" />
      <input type="hidden" name="prefilled_payer_mobile_payment_msisdn" value="$phoneNumber" />
      <input type="hidden" name="prefilled_payer_names" value="$userName" />
      <input type="hidden" name="abort_payment_url" value="" />
    </form>
  </div>

  <script>
    // Auto-submit form after 2 seconds
    setTimeout(function() {
      document.getElementById('paymentForm').submit();
    }, 2000);
  </script>
</body>
</html>
''';
  }

  /// Check payment status
  Future<Map<String, dynamic>?> checkPaymentStatus(String transactionRef) async {
    try {
      final querySnapshot = await _firestore
          .collection('payments')
          .where('transactionReference', isEqualTo: transactionRef)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking payment status: $e');
      }
      return null;
    }
  }
}
