import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';
import 'premium_sme_directory_screen.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  const SubscriptionPurchaseScreen({super.key});

  @override
  State<SubscriptionPurchaseScreen> createState() => _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState extends State<SubscriptionPurchaseScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  
  String _selectedPaymentMethod = 'MTN Mobile Money';
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  final List<String> _paymentMethods = [
    'MTN Mobile Money',
    'Airtel Money',
    'Bank Transfer',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _referenceController.dispose();
    super.dispose();
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

    if (_selectedPaymentMethod.contains('Money') && _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

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
      // For demo purposes, we'll create an active subscription directly
      // In production, this would involve actual payment processing
      
      final paymentReference = _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : 'SUB-${DateTime.now().millisecondsSinceEpoch}';

      await _subscriptionService.createSubscription(
        userId: userId,
        type: SubscriptionType.smeDirectory,
        paymentMethod: _selectedPaymentMethod,
        paymentReference: paymentReference,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Subscription Activated!'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your premium subscription has been activated successfully.'),
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (kDebugMode) {
        debugPrint('❌ Error creating subscription: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Premium Subscription'),
      ),
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
            
            // Payment Method Selection
            _buildPaymentMethodSection(),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '/year',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'One-time annual payment',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
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
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) {
            return RadioListTile<String>(
              title: Text(method),
              value: method,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }),
          
          if (_selectedPaymentMethod.contains('Money')) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '0700000000',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Payment Reference (Optional)',
              hintText: 'Transaction ID or reference',
              prefixIcon: Icon(Icons.receipt),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    String instructions = '';
    
    switch (_selectedPaymentMethod) {
      case 'MTN Mobile Money':
        instructions = '1. Dial *165# on your MTN phone\n'
                      '2. Select Send Money\n'
                      '3. Enter merchant number: 0700000000\n'
                      '4. Enter amount: 50000\n'
                      '5. Confirm payment\n'
                      '6. Enter transaction reference above';
        break;
      case 'Airtel Money':
        instructions = '1. Dial *185# on your Airtel phone\n'
                      '2. Select Send Money\n'
                      '3. Enter merchant number: 0700000000\n'
                      '4. Enter amount: 50000\n'
                      '5. Confirm payment\n'
                      '6. Enter transaction reference above';
        break;
      case 'Bank Transfer':
        instructions = 'Bank: Stanbic Bank\n'
                      'Account Name: Poultry Link Ltd\n'
                      'Account Number: 1234567890\n'
                      'Amount: UGX 50,000\n'
                      'Reference: Your name + "Premium Sub"\n\n'
                      'After transfer, enter transaction reference above';
        break;
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
                'Payment Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            instructions,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
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
                    'Activate Premium Subscription',
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
              Text('3. Access: Full SME contact directory'),
              Text('4. Auto-renewal: Not enabled by default'),
              Text('5. Cancellation: Contact support'),
              Text('6. Refund: No refunds after activation'),
              Text('7. Updates: Real-time directory updates'),
              Text('8. Usage: For business purposes only'),
              Text('9. Privacy: Respect contact privacy'),
              Text('10. Support: Priority support access'),
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
