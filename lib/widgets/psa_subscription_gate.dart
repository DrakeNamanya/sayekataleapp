import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/subscription.dart';
import '../utils/app_theme.dart';
import '../screens/psa/psa_subscription_screen.dart';

/// Gate widget that checks if PSA has an active subscription
///
/// PSAs must pay annual subscription (UGX 120,000/year) after admin approval
/// before they can fully access the dashboard and add products.
class PSASubscriptionGate extends StatelessWidget {
  final Widget child;
  final String blockedFeatureName;

  const PSASubscriptionGate({
    super.key,
    required this.child,
    this.blockedFeatureName = 'Feature',
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // If not logged in or not a PSA, let them through
    if (currentUser == null || currentUser.role != UserRole.psa) {
      return child;
    }

    // Check if PSA is verified (admin approved)
    if (currentUser.verificationStatus != VerificationStatus.verified) {
      // If not yet verified, let PSAApprovalGate handle it
      return child;
    }

    // Check if PSA has active subscription
    return FutureBuilder<bool>(
      future: _hasActiveSubscription(currentUser.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSubscription = snapshot.data ?? false;

        if (hasSubscription) {
          // Has active subscription, allow access
          return child;
        }

        // No active subscription, show subscription prompt
        return _buildSubscriptionPrompt(context, currentUser);
      },
    );
  }

  Future<bool> _hasActiveSubscription(String userId) async {
    try {
      final subscriptionSnapshot = await FirebaseFirestore.instance
          .collection('subscriptions')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: 'psaAccountActivation')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (subscriptionSnapshot.docs.isEmpty) {
        return false;
      }

      // Check if subscription is still valid (not expired)
      final subscription = Subscription.fromFirestore(
        subscriptionSnapshot.docs.first.data(),
        subscriptionSnapshot.docs.first.id,
      );

      return subscription.isActive;
    } catch (e) {
      return false;
    }
  }

  Widget _buildSubscriptionPrompt(BuildContext context, AppUser currentUser) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Required'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_membership_outlined,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Account Activation Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                const Text(
                  'Your PSA account has been approved by the admin! '
                  'To start selling, please activate your annual subscription.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Benefits Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Subscription Benefits',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitItem('List unlimited products'),
                      _buildBenefitItem('Reach thousands of SHG/SME buyers'),
                      _buildBenefitItem('Real-time order notifications'),
                      _buildBenefitItem('Delivery tracking system'),
                      _buildBenefitItem('Customer reviews & ratings'),
                      _buildBenefitItem('Business analytics dashboard'),
                      _buildBenefitItem('Direct messaging with customers'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Price
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Annual Subscription',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'UGX 120,000',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'per year (UGX 10,000/month)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Subscribe Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PSASubscriptionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Activate Subscription'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Logout button
                TextButton.icon(
                  onPressed: () {
                    _logout(context);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check,
            color: Colors.green.shade700,
            size: 20,
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

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
