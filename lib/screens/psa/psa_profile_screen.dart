import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'psa_business_info_screen.dart';
import '../common/help_support_screen.dart';
import '../../widgets/account_deletion_dialog.dart';

class PSAProfileScreen extends StatefulWidget {
  const PSAProfileScreen({super.key});

  @override
  State<PSAProfileScreen> createState() => _PSAProfileScreenState();
}

class _PSAProfileScreenState extends State<PSAProfileScreen> {
  // Password change dialog
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: !isCurrentPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isCurrentPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isCurrentPasswordVisible = !isCurrentPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter current password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // New Password
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !isNewPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm new password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  // Change password method
  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Changing password...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Get current user
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password changed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      String errorMessage;
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please logout and login again to change password';
      } else {
        errorMessage = 'Failed to change password: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header with gradient
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Supplier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.id ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.phone ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Supplier (PSA)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Options
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // SIMPLIFIED FLOW: Admin PSA - no verification banner needed
                // Admin is already verified and can add products directly

                // Business Section
                const Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileOption(
                  icon: Icons.business,
                  title: 'Business Profile',
                  subtitle: 'View approved business information',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PSABusinessInfoScreen(),
                      ),
                    );
                  },
                ),
                _ProfileOption(
                  icon: Icons.store,
                  title: 'Store Details',
                  subtitle: 'Store information and hours',
                  onTap: () {
                    // TODO: Navigate to store details
                  },
                ),
                _ProfileOption(
                  icon: Icons.location_on,
                  title: 'Business Location',
                  subtitle: 'Address and service areas',
                  onTap: () {
                    // TODO: Navigate to location settings
                  },
                ),
                
                // SIMPLIFIED FLOW: Verification documents removed
                // Admin PSA doesn't need verification documents

                const SizedBox(height: 24),

                // Financial Section
                const Text(
                  'Financial',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileOption(
                  icon: Icons.account_balance,
                  title: 'Bank Account',
                  subtitle: 'Manage bank details',
                  onTap: () {
                    // TODO: Navigate to bank account
                  },
                ),
                _ProfileOption(
                  icon: Icons.payment,
                  title: 'Payment Methods',
                  subtitle: 'Configure payment options',
                  onTap: () {
                    // TODO: Navigate to payment methods
                  },
                ),
                _ProfileOption(
                  icon: Icons.receipt_long,
                  title: 'Tax Information',
                  subtitle: 'Tax ID and invoicing',
                  onTap: () {
                    // TODO: Navigate to tax info
                  },
                ),

                const SizedBox(height: 24),

                // Settings Section
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileOption(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () {
                    _showChangePasswordDialog(context);
                  },
                ),
                _ProfileOption(
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  subtitle: 'Manage alerts and notifications',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                _ProfileOption(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Change app language',
                  onTap: () {
                    // TODO: Navigate to language settings
                  },
                ),

                const SizedBox(height: 24),

                // Support Section
                const Text(
                  'Support',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileOption(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact us',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                ),
                _ProfileOption(
                  icon: Icons.description,
                  title: 'Terms & Conditions',
                  subtitle: 'Read our terms of service',
                  onTap: () {
                    // TODO: Navigate to terms
                  },
                ),
                _ProfileOption(
                  icon: Icons.policy,
                  title: 'Privacy Policy',
                  subtitle: 'Read our privacy policy',
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
                _ProfileOption(
                  icon: Icons.info,
                  title: 'About AgriConnect',
                  subtitle: 'Version 1.0.0',
                  onTap: () {
                    // TODO: Navigate to about
                  },
                ),

                const SizedBox(height: 16),

                // Privacy & Security - Contains Delete Account
                _ProfileOption(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Account settings and data privacy',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Privacy & Security'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Manage your account security and privacy settings.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_forever,
                                color: AppTheme.errorColor,
                                size: 28,
                              ),
                              title: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                'Permanently delete your account and all data',
                                style: TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                showAccountDeletionDialog(context);
                              },
                            ),
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
                  },
                ),

                const SizedBox(height: 16),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Logging out...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );

                        try {
                          await authProvider.logout();
                          
                          // 🔧 FIX: Wait for AuthProvider to update authentication state
                          if (kDebugMode) {
                            debugPrint('⏳ PSA PROFILE - Waiting for AuthProvider to clear user...');
                          }

                          // Poll until user is cleared (max 5 seconds)
                          int attempts = 0;
                          while (authProvider.isAuthenticated && attempts < 10) {
                            await Future.delayed(const Duration(milliseconds: 500));
                            attempts++;

                            if (kDebugMode) {
                              debugPrint(
                                '⏳ PSA PROFILE - Attempt $attempts: isAuthenticated = ${authProvider.isAuthenticated}',
                              );
                            }
                          }

                          if (kDebugMode) {
                            debugPrint(
                              '✅ PSA PROFILE - AuthProvider cleared user: isAuthenticated = ${authProvider.isAuthenticated}',
                            );
                          }
                          
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/onboarding',
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(
                        color: AppTheme.errorColor,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// SIMPLIFIED FLOW: _VerificationBanner removed
// Admin PSA doesn't need verification banner
