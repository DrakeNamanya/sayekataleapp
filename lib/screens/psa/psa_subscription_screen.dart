import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/subscription.dart';
import '../../utils/app_theme.dart';

class PSASubscriptionScreen extends StatefulWidget {
  const PSASubscriptionScreen({super.key});

  @override
  State<PSASubscriptionScreen> createState() => _PSASubscriptionScreenState();
}

class _PSASubscriptionScreenState extends State<PSASubscriptionScreen> {
  final _phoneController = TextEditingController();
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'mtn_mobile_money';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PSA Subscription'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subscription Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.card_membership,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'PSA Annual Subscription',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UGX 120,000',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'per year (UGX 10,000/month)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // What You Get Section
              const Text(
                'What You Get',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildFeatureItem(
                'Unlimited product listings on the platform',
                Icons.inventory_2_outlined,
              ),
              _buildFeatureItem(
                'Access to thousands of SHG and SME buyers',
                Icons.people_outline,
              ),
              _buildFeatureItem(
                'Real-time order notifications and tracking',
                Icons.notifications_active_outlined,
              ),
              _buildFeatureItem(
                'Business analytics and sales reports',
                Icons.analytics_outlined,
              ),
              _buildFeatureItem(
                'Direct messaging with customers',
                Icons.chat_bubble_outline,
              ),
              _buildFeatureItem(
                'Customer reviews and ratings system',
                Icons.star_outline,
              ),
              _buildFeatureItem(
                'Priority customer support',
                Icons.support_agent_outlined,
              ),
              const SizedBox(height: 32),

              // Payment Method Section
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodOption(
                'MTN Mobile Money',
                'mtn_mobile_money',
                Icons.phone_android,
              ),
              _buildPaymentMethodOption(
                'Airtel Money',
                'airtel_money',
                Icons.phone_android,
              ),
              const SizedBox(height: 24),

              // Phone Number Input
              const Text(
                'Mobile Money Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '0777 123 456',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 24),

              // Terms and Conditions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'By subscribing, you agree to pay UGX 120,000 annually. '
                        'Your subscription will auto-renew unless cancelled. '
                        'Refunds are available within 7 days if unused.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subscribe Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          _handleSubscribe(context, currentUser!);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    String title,
    String value,
    IconData icon,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPaymentMethod == value
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPaymentMethod = val;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: _selectedPaymentMethod == value
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscribe(
    BuildContext context,
    dynamic currentUser,
  ) async {
    // Validate phone number
    if (_phoneController.text.trim().isEmpty) {
      _showErrorDialog('Please enter your mobile money number');
      return;
    }

    // Format phone number
    String phone = _phoneController.text.trim().replaceAll(' ', '');
    if (!phone.startsWith('256') && !phone.startsWith('+256')) {
      if (phone.startsWith('0')) {
        phone = '256${phone.substring(1)}';
      } else {
        phone = '256$phone';
      }
    }

    // Confirm subscription
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create pending subscription
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 365));

      final subscriptionRef =
          FirebaseFirestore.instance.collection('subscriptions').doc();

      final subscription = Subscription(
        id: subscriptionRef.id,
        userId: currentUser.id,
        type: SubscriptionType.psaAccountActivation,
        status: SubscriptionStatus.pending,
        startDate: startDate,
        endDate: endDate,
        amount: 120000,
        paymentMethod: _selectedPaymentMethod,
        createdAt: DateTime.now(),
      );

      await subscriptionRef.set(subscription.toFirestore());

      // Initiate payment (this would integrate with actual payment gateway)
      // For now, we'll simulate success
      await Future.delayed(const Duration(seconds: 2));

      // Update subscription status to active
      await subscriptionRef.update({
        'status': 'active',
        'payment_reference': 'PSA-${DateTime.now().millisecondsSinceEpoch}',
      });

      setState(() {
        _isProcessing = false;
      });

      // Show success and navigate back
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        _showErrorDialog('Failed to process subscription: $e');
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Subscription'),
            content: Text(
              'You are about to pay UGX 120,000 for annual PSA subscription.\n\n'
              'Payment Method: ${_selectedPaymentMethod == "mtn_mobile_money" ? "MTN Mobile Money" : "Airtel Money"}\n'
              'Phone: ${_phoneController.text}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text(
          'Your subscription has been activated successfully! '
          'You can now access all PSA features.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
