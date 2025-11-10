import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/psa_verification.dart';
import '../../services/psa_verification_service.dart';
import 'psa_edit_profile_screen.dart';
import 'psa_verification_form_screen.dart';
import 'psa_business_info_screen.dart';
import '../common/help_support_screen.dart';

class PSAProfileScreen extends StatefulWidget {
  const PSAProfileScreen({super.key});

  @override
  State<PSAProfileScreen> createState() => _PSAProfileScreenState();
}

class _PSAProfileScreenState extends State<PSAProfileScreen> {
  final PSAVerificationService _verificationService = PSAVerificationService();
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final userId = user?.id ?? '';

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
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.accentColor,
                    ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 16, color: Colors.white),
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
                const SizedBox(height: 8),

                // Verification Status Banner
                StreamBuilder<PsaVerification?>(
                  stream: _verificationService.streamPsaVerification(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    final verification = snapshot.data;
                    
                    if (verification == null) {
                      // No verification submitted - prompt to complete
                      return _VerificationBanner(
                        status: 'incomplete',
                        title: 'Complete Your Business Verification',
                        subtitle: 'Submit your business documents to start selling',
                        icon: Icons.warning_amber,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PSAVerificationFormScreen(),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    }

                    // Show verification status
                    if (verification.status == PsaVerificationStatus.pending ||
                        verification.status == PsaVerificationStatus.underReview) {
                      return _VerificationBanner(
                        status: 'pending',
                        title: 'Verification Under Review',
                        subtitle: 'Your documents are being reviewed by admin',
                        icon: Icons.hourglass_empty,
                        color: Colors.blue,
                        onTap: null,
                      );
                    }

                    if (verification.status == PsaVerificationStatus.approved) {
                      return _VerificationBanner(
                        status: 'approved',
                        title: 'Verified Business',
                        subtitle: 'Your business is verified and active',
                        icon: Icons.verified,
                        color: Colors.green,
                        onTap: null,
                      );
                    }

                    if (verification.status == PsaVerificationStatus.rejected) {
                      return _VerificationBanner(
                        status: 'rejected',
                        title: 'Verification Rejected',
                        subtitle: verification.rejectionReason ?? 'Please update your documents',
                        icon: Icons.cancel,
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PSAVerificationFormScreen(
                                existingVerification: verification,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                
                const SizedBox(height: 16),

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
                _ProfileOption(
                  icon: Icons.verified,
                  title: 'Verification Documents',
                  subtitle: 'Business license and certifications',
                  onTap: () async {
                    final verification = await _verificationService.getPsaVerification(userId);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PSAVerificationFormScreen(
                            existingVerification: verification,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    }
                  },
                ),

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
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  subtitle: 'Manage alerts and notifications',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
                _ProfileOption(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  subtitle: 'Password and security settings',
                  onTap: () {
                    // TODO: Navigate to security settings
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

                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
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
                        await authProvider.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/onboarding',
                            (route) => false,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor, width: 2),
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _VerificationBanner extends StatelessWidget {
  final String status;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _VerificationBanner({
    required this.status,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
