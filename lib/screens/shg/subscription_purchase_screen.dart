import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import '../../services/pawapay_service.dart';
import 'premium_sme_directory_screen.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  const SubscriptionPurchaseScreen({super.key});

  @override
  State<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState
    extends State<SubscriptionPurchaseScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _phoneController = TextEditingController();
  
  // PawaPay API key (from user's credentials)
  static const String pawaPayApiKey = 'eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE5MTEiLCJtYXYiOiIxIiwiZXhwIjoyMDc5MTIwMDM2LCJpYXQiOjE3NjM1ODcyMzYsInBtIjoiREFGLFBBRiIsImp0aSI6Ijc4NWE5ZWFlLWM2YWQtNDNjZC1hN2RlLTA4YzQzNmJkMzQ0ZCJ9.sed2zJT2ZkNSsHm4kB-GXLejgbE5VQLHNGULX9L7mI_Vxcrcqcu6_Vb9i83nuHKZ00c3eV6-s1DWKZ1bzVYunw';
  
  late final PawaPayService _pawaPayService;

  bool _isProcessing = false;
  bool _agreedToTerms = false;
  MobileMoneyOperator? _detectedOperator;

  @override
  void initState() {
    super.initState();
    // Initialize PawaPay service with production API key
    _pawaPayService = PawaPayService(
      apiKey: pawaPayApiKey,
      debugMode: false, // Production mode
    );

    // Listen to phone number changes to detect operator
    _phoneController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length >= 4) {
      setState(() {
        _detectedOperator = _pawaPayService.detectOperator(phone);
      });
    } else {
      setState(() {
        _detectedOperator = null;
      });
    }
  }

  Future<void> _processSubscription() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate phone number
    if (!_pawaPayService.isValidPhoneNumber(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid Uganda phone number (e.g., 0772123456)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final userName = authProvider.currentUser?.name ?? 'User';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Show processing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildProcessingDialog(),
        );
      }

      // Initiate PawaPay payment
      final paymentResult = await _pawaPayService.initiatePremiumPayment(
        userId: userId,
        phoneNumber: phoneNumber,
        userName: userName,
      );

      // Close processing dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (paymentResult.isSuccess) {
        // Create subscription in Firestore
        await _subscriptionService.createSubscription(
          userId: userId,
          type: SubscriptionType.smeDirectory,
          paymentMethod: _detectedOperator == MobileMoneyOperator.mtn
              ? 'MTN Mobile Money'
              : 'Airtel Money',
          paymentReference: paymentResult.depositId ?? 'PAWA-${DateTime.now().millisecondsSinceEpoch}',
        );

        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          // Show success dialog
          _showSuccessDialog();
        }
      } else {
        // Payment failed
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentResult.errorMessage ?? 'Payment failed. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        if (kDebugMode) {
          debugPrint('❌ Payment failed: ${paymentResult.errorMessage}');
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        // Close processing dialog if open
        Navigator.pop(context);

        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('❌ Error creating subscription: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  Widget _buildProcessingDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          const Text(
            'Processing Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Please enter your PIN on your phone to approve the payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Check your phone for payment prompt',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your premium subscription has been activated successfully.',
            ),
            SizedBox(height: 12),
            Text('You now have access to:'),
            SizedBox(height: 8),
            Text('✅ Full SME contact directory'),
            Text('✅ Advanced search and filters'),
            Text('✅ Direct contact information'),
            Text('✅ 1 year unlimited access'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumSMEDirectoryScreen(),
                ),
              );
            },
            child: const Text('Access Directory'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Premium Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Package Card
            _buildPremiumPackageCard(),
            const SizedBox(height: 24),

            // Features List
            _buildFeaturesList(),
            const SizedBox(height: 24),

            // Mobile Money Payment Section
            _buildPaymentSection(),
            const SizedBox(height: 24),

            // Payment Instructions
            _buildPaymentInstructions(),
            const SizedBox(height: 24),

            // Terms and Conditions
            _buildTermsCheckbox(),
            const SizedBox(height: 24),

            // Purchase Button
            _buildPurchaseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPackageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Premium SME Directory',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock Full Access',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UGX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '50,000',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '/year',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'One-time annual payment',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You Get',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            Icons.contacts,
            'Complete SME Directory',
            'Access all registered SME buyer contacts',
          ),
          _buildFeatureItem(
            Icons.filter_alt,
            'Advanced Filters',
            'Search by district, product category, and more',
          ),
          _buildFeatureItem(
            Icons.phone,
            'Direct Contact Info',
            'Phone numbers, emails, and addresses',
          ),
          _buildFeatureItem(
            Icons.verified,
            'Verified Users',
            'Filter to show only verified SME buyers',
          ),
          _buildFeatureItem(
            Icons.calendar_today,
            '1 Year Access',
            'Full access for 365 days from activation',
          ),
          _buildFeatureItem(
            Icons.support_agent,
            'Priority Support',
            'Get dedicated support for your queries',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.purple[700], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'Mobile Money Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '0772123456 or +256772123456',
              prefixIcon: const Icon(Icons.phone),
              suffixIcon: _detectedOperator != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildOperatorBadge(_detectedOperator!),
                    )
                  : null,
              border: const OutlineInputBorder(),
              helperText: 'MTN: 077/078  •  Airtel: 070/075',
            ),
          ),
          if (_detectedOperator == MobileMoneyOperator.unknown) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Unknown operator. Please use MTN or Airtel number.',
                      style: TextStyle(fontSize: 12),
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

  Widget _buildOperatorBadge(MobileMoneyOperator operator) {
    final isMtn = operator == MobileMoneyOperator.mtn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMtn ? Colors.yellow[700] : Colors.red[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isMtn ? 'MTN' : 'Airtel',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    final operator = _detectedOperator;
    String instructions = '';

    if (operator == MobileMoneyOperator.mtn) {
      instructions =
          '1. Enter your MTN phone number above\n'
          '2. Click "Activate Subscription" below\n'
          '3. Check your phone for payment prompt\n'
          '4. Enter your MTN Mobile Money PIN\n'
          '5. Approve the payment of UGX 50,000';
    } else if (operator == MobileMoneyOperator.airtel) {
      instructions =
          '1. Enter your Airtel phone number above\n'
          '2. Click "Activate Subscription" below\n'
          '3. Check your phone for payment prompt\n'
          '4. Enter your Airtel Money PIN\n'
          '5. Approve the payment of UGX 50,000';
    } else {
      instructions =
          '1. Enter your MTN (077, 078) or Airtel (070, 075) number\n'
          '2. Click "Activate Subscription" below\n'
          '3. Check your phone for payment prompt\n'
          '4. Enter your Mobile Money PIN to approve\n'
          '5. Payment of UGX 50,000 will be deducted';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'How to Pay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(instructions, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      value: _agreedToTerms,
      onChanged: (value) {
        setState(() {
          _agreedToTerms = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: const Text(
        'I agree to the terms and conditions of the premium subscription',
        style: TextStyle(fontSize: 14),
      ),
      subtitle: TextButton(
        onPressed: () {
          _showTermsDialog();
        },
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.zero,
        ),
        child: const Text('View Terms & Conditions'),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple[700],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium),
                  SizedBox(width: 12),
                  Text(
                    'Activate Subscription',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Premium SME Directory Subscription Terms:\n'),
              Text('1. Duration: 12 months from activation date'),
              Text('2. Price: UGX 50,000 (non-refundable)'),
              Text('3. Payment: Via MTN Mobile Money or Airtel Money'),
              Text('4. Access: Full SME contact directory'),
              Text('5. Auto-renewal: Not enabled by default'),
              Text('6. Cancellation: Contact support'),
              Text('7. Refund: No refunds after activation'),
              Text('8. Updates: Real-time directory updates'),
              Text('9. Usage: For business purposes only'),
              Text('10. Privacy: Respect contact privacy'),
              Text('11. Support: Priority support access'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
