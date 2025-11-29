import 'package:flutter/material.dart';
import '../auth/sme_login_screen.dart';
import '../auth/sme_registration_screen.dart';

/// SME (Buyer) Portal Landing Page
/// Features: Product browsing, order management, delivery tracking
class SMEPortalPage extends StatelessWidget {
  const SMEPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            _buildHeroSection(context),
            
            // Features Section
            _buildFeaturesSection(context),
            
            // How It Works
            _buildHowItWorksSection(context),
            
            // CTA Section
            _buildCTASection(context),
          ],
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
          colors: [Colors.blue.shade700, Colors.blue.shade400],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SME Portal',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'For Buyers & Small-Medium Enterprises',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Browse fresh produce, place orders, and track deliveries in real-time. Connect directly with farmers and suppliers for the best prices.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SMELoginScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SMERegistrationScreen(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Icon(
              Icons.business,
              size: 300,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          const Text(
            'SME Portal Features',
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
              _buildFeatureCard(
                Icons.search,
                'Browse Products',
                'Search and filter thousands of fresh agricultural products',
                Colors.blue,
              ),
              _buildFeatureCard(
                Icons.shopping_cart,
                'Easy Ordering',
                'Simple checkout process with multiple payment options',
                Colors.green,
              ),
              _buildFeatureCard(
                Icons.local_shipping,
                'Track Deliveries',
                'Real-time GPS tracking with photo proof of delivery',
                Colors.orange,
              ),
              _buildFeatureCard(
                Icons.location_on,
                'Distance Sorting',
                'Find nearby farmers and suppliers to reduce costs',
                Colors.purple,
              ),
              _buildFeatureCard(
                Icons.receipt,
                'Digital Receipts',
                'Automatic receipt generation for all transactions',
                Colors.red,
              ),
              _buildFeatureCard(
                Icons.favorite,
                'Favorites',
                'Save your favorite products and suppliers',
                Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 12),
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

  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          const Text(
            'How It Works',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStepCard('1', 'Register', 'Create your SME account'),
              const Icon(Icons.arrow_forward, size: 40, color: Colors.blue),
              _buildStepCard('2', 'Browse', 'Find products you need'),
              const Icon(Icons.arrow_forward, size: 40, color: Colors.blue),
              _buildStepCard('3', 'Order', 'Place your order securely'),
              const Icon(Icons.arrow_forward, size: 40, color: Colors.blue),
              _buildStepCard('4', 'Track', 'Monitor delivery in real-time'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: Colors.blue.shade700,
      child: Column(
        children: [
          const Text(
            'Ready to Get Started?',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of SMEs sourcing quality agricultural products',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SMERegistrationScreen(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(
                horizontal: 50,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Create SME Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
