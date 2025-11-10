import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'shg_edit_profile_screen.dart';
import '../common/help_support_screen.dart';

class SHGProfileScreen extends StatelessWidget {
  const SHGProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    
    if (kDebugMode) {
      debugPrint('🖼️ SHG PROFILE SCREEN - Rendering with:');
      debugPrint('   - user: ${user != null ? user.name : "NULL"}');
      debugPrint('   - profileImage: ${user?.profileImage ?? "NULL"}');
      debugPrint('   - nationalIdPhoto: ${user?.nationalIdPhoto ?? "NULL"}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profileImage != null && user!.profileImage!.isNotEmpty
                          ? NetworkImage(user.profileImage!)
                          : null,
                      child: user?.profileImage == null || user!.profileImage!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'Farmer Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone ?? '+256 XXX XXX XXX',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Farmer (SHG) - ${user?.id ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (user?.isProfileComplete ?? false)
                                ? AppTheme.successColor.withValues(alpha: 0.2)
                                : AppTheme.warningColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (user?.isProfileComplete ?? false)
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (user?.isProfileComplete ?? false)
                                    ? 'Complete'
                                    : 'Incomplete',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Profile Completion Warning
              if (!(user?.isProfileComplete ?? true))
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.warningColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete your profile to start selling products',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Profile Options
              _ProfileOption(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SHGEditProfileScreen()),
                  );
                },
              ),
              _ProfileOption(
                icon: Icons.agriculture_outlined,
                title: 'Farm Details',
                subtitle: 'Manage your farm information',
                onTap: () {
                  // Farm details
                },
              ),
              _ProfileOption(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: user?.location?.address ?? 'Set your location',
                onTap: () {
                  // Update location
                },
              ),
              _ProfileOption(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  // Notification settings
                },
              ),
              _ProfileOption(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  // Privacy settings
                },
              ),
              _ProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help with the app',
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
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  // About
                },
              ),
              const Divider(height: 32),
              // Logout Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
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
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }
}
