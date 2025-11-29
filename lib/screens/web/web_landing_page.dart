import 'package:flutter/material.dart';

/// Main public landing page for datacollectors.org
/// Features: Hero section, role selection, about, contact
class WebLandingPage extends StatelessWidget {
  const WebLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Navigation Bar
            _buildNavigationBar(context),
            
            // Hero Section
            _buildHeroSection(context),
            
            // Role Selection Cards
            _buildRoleSelectionSection(context),
            
            // Features Section
            _buildFeaturesSection(context),
            
            // Statistics Section
            _buildStatsSection(context),
            
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.agriculture, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              const Text(
                'SAYE KATALE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          // Navigation Links
          Row(
            children: [
              _buildNavLink('Home', () => _scrollToTop()),
              const SizedBox(width: 30),
              _buildNavLink('About', () => _scrollToSection('about')),
              const SizedBox(width: 30),
              _buildNavLink('Features', () => _scrollToSection('features')),
              const SizedBox(width: 30),
              _buildNavLink('Contact', () => _scrollToSection('contact')),
              const SizedBox(width: 30),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Get Started', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Row(
        children: [
          // Left: Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Farmers with Buyers',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Uganda\'s premier agricultural marketplace connecting farmers, suppliers, and buyers for seamless trade.',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Join Now',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () => _scrollToSection('features'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade700, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Learn More',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
          
          // Right: Hero Image/Illustration
          Expanded(
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Icon(
                  Icons.agriculture,
                  size: 300,
                  color: Colors.green.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelectionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Choose Your Portal',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select the portal that best fits your role in the agricultural value chain',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 60),
          
          // Role Cards Grid
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _buildRoleCard(
                context,
                title: 'SME Portal',
                subtitle: 'For Buyers & Small-Medium Enterprises',
                icon: Icons.business,
                color: Colors.blue,
                routeName: '/sme',
                description: 'Browse products, place orders, track deliveries',
              ),
              _buildRoleCard(
                context,
                title: 'SHG Portal',
                subtitle: 'For Self-Help Groups & Farmers',
                icon: Icons.groups,
                color: Colors.green,
                routeName: '/shg',
                description: 'Sell products, manage inventory, fulfill orders',
              ),
              _buildRoleCard(
                context,
                title: 'PSA Portal',
                subtitle: 'For Private Sector Agents & Suppliers',
                icon: Icons.store,
                color: Colors.orange,
                routeName: '/psa',
                description: 'Supply products, manage listings, handle deliveries',
              ),
              _buildRoleCard(
                context,
                title: 'Admin Portal',
                subtitle: 'For System Administrators',
                icon: Icons.admin_panel_settings,
                color: Colors.red,
                routeName: '/admin',
                description: 'Manage users, analytics, system configuration',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String routeName,
    required String description,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, routeName),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, routeName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Enter Portal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      key: const Key('features'),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text(
            'Platform Features',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 60),
          
          Wrap(
            spacing: 40,
            runSpacing: 40,
            children: [
              _buildFeatureItem(
                Icons.shopping_cart,
                'Easy Ordering',
                'Simple and intuitive ordering process for buyers',
                Colors.blue,
              ),
              _buildFeatureItem(
                Icons.local_shipping,
                'Real-time Tracking',
                'Track deliveries with live GPS location updates',
                Colors.green,
              ),
              _buildFeatureItem(
                Icons.photo_camera,
                'Photo Verification',
                'Delivery proof with photo documentation',
                Colors.orange,
              ),
              _buildFeatureItem(
                Icons.payment,
                'Secure Payments',
                'Multiple payment options with escrow protection',
                Colors.purple,
              ),
              _buildFeatureItem(
                Icons.bar_chart,
                'Analytics Dashboard',
                'Comprehensive insights and reporting tools',
                Colors.red,
              ),
              _buildFeatureItem(
                Icons.support_agent,
                '24/7 Support',
                'Round-the-clock customer support assistance',
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return SizedBox(
      width: 280,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: Colors.green.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('10,000+', 'Active Users', Icons.people),
          _buildStatItem('5,000+', 'Products Listed', Icons.inventory),
          _buildStatItem('50,000+', 'Orders Delivered', Icons.local_shipping),
          _buildStatItem('98%', 'Success Rate', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 50, color: Colors.white),
        const SizedBox(height: 16),
        Text(
          value,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      key: const Key('contact'),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      color: Colors.grey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAYE KATALE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connecting Uganda\'s agricultural value chain',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'datacollectors.org',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quick Links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Links',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFooterLink('SME Portal', '/sme'),
                    _buildFooterLink('SHG Portal', '/shg'),
                    _buildFooterLink('PSA Portal', '/psa'),
                    _buildFooterLink('Admin Portal', '/admin'),
                  ],
                ),
              ),
              
              // Contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(Icons.email, 'info@datacollectors.org'),
                    _buildContactItem(Icons.phone, '+256 XXX XXX XXX'),
                    _buildContactItem(Icons.location_on, 'Kampala, Uganda'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Text(
            '© ${DateTime.now().year} SAYE KATALE. All rights reserved.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Builder(
        builder: (context) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    // Scroll functionality handled by SingleChildScrollView
  }

  void _scrollToSection(String sectionId) {
    // Scroll to section (simplified for web)
  }
}
