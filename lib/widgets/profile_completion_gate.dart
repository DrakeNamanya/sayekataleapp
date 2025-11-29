import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../screens/shg/shg_edit_profile_screen.dart';
import '../screens/sme/sme_edit_profile_screen.dart';
import '../screens/psa/psa_edit_profile_screen.dart';

/// Profile Completion Gate Widget
/// Blocks access to app features if profile is incomplete and deadline has passed
class ProfileCompletionGate extends StatelessWidget {
  final Widget child;
  final String blockedFeatureName;

  const ProfileCompletionGate({
    super.key,
    required this.child,
    this.blockedFeatureName = 'this feature',
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // If user is null, show loading with timeout fallback
    if (user == null) {
      // Navigate to onboarding if still null after brief wait
      Future.delayed(const Duration(seconds: 2), () {
        if (authProvider.currentUser == null && context.mounted) {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if profile is complete
    if (user.isProfileComplete) {
      return child; // Allow access
    }

    // Check if deadline has passed
    final deadline = user.profileCompletionDeadline;
    if (deadline != null && DateTime.now().isAfter(deadline)) {
      // Deadline passed - block access
      return _buildBlockedScreen(context, user, deadline);
    }

    // Deadline not passed yet - show warning but allow access
    return child;
  }

  Widget _buildBlockedScreen(BuildContext context, AppUser user, DateTime deadline) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock Icon
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Profile Completion Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  'Your 24-hour profile completion deadline has passed.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'To continue using the app, please complete your profile with all required information.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Deadline Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppTheme.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Registration Deadline',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expired on ${_formatDeadline(deadline)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Missing Information
                _buildMissingInfoCard(user),
                const SizedBox(height: 32),

                // Complete Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to profile completion
                      _navigateToProfileEdit(context, user.role);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Complete Profile Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Help Text
                TextButton.icon(
                  onPressed: () {
                    _showHelpDialog(context);
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Why is this required?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissingInfoCard(AppUser user) {
    final missingItems = <String>[];
    
    if (user.nationalId == null || user.nationalId!.isEmpty) {
      missingItems.add('National ID Number (NIN)');
    }
    if (user.nationalIdPhoto == null || user.nationalIdPhoto!.isEmpty) {
      missingItems.add('National ID Photo');
    }
    if (user.nameOnIdPhoto == null || user.nameOnIdPhoto!.isEmpty) {
      missingItems.add('Name on ID Photo');
    }
    if (user.dateOfBirth == null) {
      missingItems.add('Date of Birth');
    }
    if (user.sex == null) {
      missingItems.add('Sex');
    }
    if (user.location == null) {
      missingItems.add('Location');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: AppTheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Missing Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...missingItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = now.difference(deadline);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? "s" : ""} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? "s" : ""} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? "s" : ""} ago';
    }
  }

  void _navigateToProfileEdit(BuildContext context, UserRole role) {
    // Navigate directly to role-specific edit profile screen
    switch (role) {
      case UserRole.shg:
        // Navigate directly to SHG edit profile screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SHGEditProfileScreen(),
          ),
        );
        return;
      case UserRole.sme:
        // Navigate directly to SME edit profile screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SMEEditProfileScreen(),
          ),
        );
        return;
      case UserRole.psa:
        // Navigate directly to PSA edit profile screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PSAEditProfileScreen(),
          ),
        );
        return;
      default:
        Navigator.of(context).pushReplacementNamed('/onboarding');
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why Complete Your Profile?'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete profile verification is required for:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('✅ Identity verification and security'),
              SizedBox(height: 8),
              Text('✅ Trust and safety in transactions'),
              SizedBox(height: 8),
              Text('✅ Legal compliance requirements'),
              SizedBox(height: 8),
              Text('✅ Fraud prevention'),
              SizedBox(height: 8),
              Text('✅ Better service experience'),
              SizedBox(height: 16),
              Text(
                'All users must complete their profile within 24 hours of registration to continue using the app.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
