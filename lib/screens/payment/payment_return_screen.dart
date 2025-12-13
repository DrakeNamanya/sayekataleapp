import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/yo_payments_service.dart';
import '../../services/subscription_service.dart';
import '../../models/subscription.dart';
import '../../utils/app_theme.dart';
import '../shg/shg_dashboard_screen.dart';
import '../shg/premium_sme_directory_screen.dart';

/// Payment Return Screen
/// 
/// This screen handles the redirect from YO Payments after payment.
/// URL format: /payment-success?transaction_id={ID}&transaction_reference={REF}
/// 
/// Flow:
/// 1. Extract transaction details from URL parameters
/// 2. Check payment status in Firestore
/// 3. Wait for webhook to activate subscription
/// 4. Show appropriate success/pending/error message
class PaymentReturnScreen extends StatefulWidget {
  final String? transactionId;
  final String? transactionReference;

  const PaymentReturnScreen({
    super.key,
    this.transactionId,
    this.transactionReference,
  });

  @override
  State<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends State<PaymentReturnScreen> {
  final YOPaymentsService _yoPaymentsService = YOPaymentsService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isLoading = true;
  bool _isSuccess = false;
  String _statusMessage = 'Checking payment status...';
  PaymentStatus? _paymentStatus;
  Subscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (kDebugMode) {
      debugPrint('🔍 Checking payment status...');
      debugPrint('Transaction ID: ${widget.transactionId}');
      debugPrint('Transaction Reference: ${widget.transactionReference}');
    }

    // Validate parameters
    if (widget.transactionReference == null || 
        widget.transactionReference!.isEmpty) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Invalid payment reference. Please contact support.';
      });
      return;
    }

    try {
      // Small delay to allow webhook to process
      await Future.delayed(const Duration(seconds: 2));

      // Check payment status
      final paymentStatus = await _yoPaymentsService.checkPaymentStatus(
        widget.transactionReference!,
      );

      if (kDebugMode) {
        debugPrint('Payment Status: $paymentStatus');
      }

      setState(() {
        _paymentStatus = paymentStatus;
      });

      // Check subscription status
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        final subscription = await _subscriptionService.getActiveSubscription(
          userId,
          SubscriptionType.smeDirectory,
        );

        setState(() {
          _subscription = subscription;
        });
      }

      // Determine final status
      if (paymentStatus == PaymentStatus.completed && _subscription != null) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = 'Payment successful! Your premium subscription is now active.';
        });
      } else if (paymentStatus == PaymentStatus.completed) {
        // Payment completed but subscription not yet active (webhook processing)
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = 
              'Payment successful! Your subscription will be activated within 5 minutes.';
        });
      } else if (paymentStatus == PaymentStatus.pending) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = 
              'Payment is being processed. Please check back in a few minutes.';
        });
      } else if (paymentStatus == PaymentStatus.failed) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = 
              'Payment failed. Please try again or contact support.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = 
              'Payment status unknown. Please contact support with reference: ${widget.transactionReference}';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error checking payment status: $e');
      }

      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 
            'Error checking payment status. Please contact support.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Icon
                _buildStatusIcon(),
                const SizedBox(height: 32),

                // Status Card
                _buildStatusCard(),
                const SizedBox(height: 32),

                // Transaction Details
                if (widget.transactionReference != null)
                  _buildTransactionDetails(),
                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue[50],
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _isSuccess ? Colors.green[50] : Colors.orange[50],
        shape: BoxShape.circle,
      ),
      child: Icon(
        _isSuccess ? Icons.check_circle : Icons.access_time,
        size: 60,
        color: _isSuccess ? Colors.green[600] : Colors.orange[600],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isLoading
                ? 'Checking Payment...'
                : _isSuccess
                    ? 'Payment Successful!'
                    : 'Payment Pending',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isLoading
                  ? Colors.blue[700]
                  : _isSuccess
                      ? Colors.green[700]
                      : Colors.orange[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_subscription != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Subscription Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_subscription!.daysRemaining} days remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Reference',
            widget.transactionReference!,
          ),
          if (widget.transactionId != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Transaction ID',
              widget.transactionId!,
            ),
          ],
          const SizedBox(height: 12),
          _buildDetailRow(
            'Amount',
            'UGX 50,000',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Duration',
            '1 Year',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Primary Action Button
        if (_isSuccess && _subscription != null)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PremiumSMEDirectoryScreen(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.contacts),
              label: const Text('Access Premium Directory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // Secondary Action Button
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SHGDashboardScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Go to Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Retry Button (if payment failed)
        if (!_isSuccess && _paymentStatus == PaymentStatus.failed) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],

        // Support Link
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            // TODO: Add support contact functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Support: Contact your administrator'),
                duration: Duration(seconds: 3),
              ),
            );
          },
          icon: const Icon(Icons.help_outline, size: 20),
          label: const Text('Need Help?'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
