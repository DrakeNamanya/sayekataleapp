import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';

/// Gate widget that blocks PSA access until admin approves their account
///
/// PSAs must complete their profile and wait for admin approval before
/// they can access the dashboard and add products.
class PSAApprovalGate extends StatelessWidget {
  final Widget child;
  final String blockedFeatureName;

  const PSAApprovalGate({
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

    // Check verification status
    final verificationStatus = currentUser.verificationStatus;

    // If verified, allow access
    if (verificationStatus == VerificationStatus.verified) {
      return child;
    }

    // Block access with appropriate message for pending/rejected/inReview
    return _buildBlockedScreen(context, verificationStatus);
  }

  Widget _buildBlockedScreen(
    BuildContext context,
    VerificationStatus status,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
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
                _buildStatusIcon(status),
                const SizedBox(height: 24),
                _buildStatusTitle(status),
                const SizedBox(height: 12),
                _buildStatusMessage(status),
                const SizedBox(height: 32),
                _buildActionButton(context, status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(VerificationStatus status) {
    IconData iconData;
    Color iconColor;

    switch (status) {
      case VerificationStatus.pending:
      case VerificationStatus.inReview:
        iconData = Icons.hourglass_empty;
        iconColor = Colors.orange;
        break;
      case VerificationStatus.rejected:
        iconData = Icons.cancel_outlined;
        iconColor = AppTheme.errorColor;
        break;
      case VerificationStatus.suspended:
        iconData = Icons.block;
        iconColor = AppTheme.errorColor;
        break;
      default:
        iconData = Icons.check_circle_outline;
        iconColor = AppTheme.successColor;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 64, color: iconColor),
    );
  }

  Widget _buildStatusTitle(VerificationStatus status) {
    String title;
    switch (status) {
      case VerificationStatus.pending:
        title = 'Profile Under Review';
        break;
      case VerificationStatus.inReview:
        title = 'Verification in Progress';
        break;
      case VerificationStatus.rejected:
        title = 'Application Rejected';
        break;
      case VerificationStatus.suspended:
        title = 'Account Suspended';
        break;
      default:
        title = 'Account Status';
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStatusMessage(VerificationStatus status) {
    String message;
    switch (status) {
      case VerificationStatus.pending:
        message = 'Your PSA account is awaiting admin approval. '
            'This process usually takes 1-2 business days. '
            'You will be notified once your account is verified.';
        break;
      case VerificationStatus.inReview:
        message = 'Our admin team is currently reviewing your account details. '
            'We may contact you if additional information is needed. '
            'Thank you for your patience.';
        break;
      case VerificationStatus.rejected:
        message = 'Your PSA application has been rejected. '
            'This may be due to incomplete information or verification issues. '
            'Please contact support for more details.';
        break;
      case VerificationStatus.suspended:
        message = 'Your account has been temporarily suspended. '
            'Please contact support to resolve any outstanding issues.';
        break;
      default:
        message = 'Please wait for account verification.';
    }

    return Text(
      message,
      style: const TextStyle(
        fontSize: 15,
        color: AppTheme.textSecondary,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context, VerificationStatus status) {
    if (status == VerificationStatus.rejected ||
        status == VerificationStatus.suspended) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _contactSupport(context);
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Support'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'You will receive a notification once your account is approved.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            _logout(context);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  void _contactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@sayekatale.com'),
            SizedBox(height: 8),
            Text('Phone: +256 XXX XXX XXX'),
            SizedBox(height: 8),
            Text('Working Hours: Mon-Fri, 8AM-5PM'),
          ],
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
