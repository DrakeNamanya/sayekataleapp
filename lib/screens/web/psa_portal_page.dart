import 'package:flutter/material.dart';
import '../auth/psa_login_screen.dart';
import '../auth/psa_registration_screen.dart';

/// PSA (Private Sector Agent / Suppliers) Portal Landing Page
class PSAPortalPage extends StatelessWidget {
  const PSAPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(context),
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
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade400]),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PSA Portal', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                const Text('For Private Sector Agents & Suppliers', style: TextStyle(fontSize: 24, color: Colors.white70)),
                const SizedBox(height: 32),
                const Text(
                  'Supply agricultural products at scale, manage large inventories, handle bulk orders, and expand your supplier network.',
                  style: TextStyle(fontSize: 18, color: Colors.white, height: 1.6),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PSALoginScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      ),
                      child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PSARegistrationScreen())),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                      ),
                      child: const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: Icon(Icons.store, size: 300, color: Colors.white.withValues(alpha: 0.3))),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      child: Column(
        children: [
          const Text('PSA Portal Features', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            children: [
              _buildFeatureCard(Icons.inventory_2, 'Bulk Inventory', 'Manage large-scale product listings', Colors.orange),
              _buildFeatureCard(Icons.shopping_basket, 'Bulk Orders', 'Handle high-volume order processing', Colors.blue),
              _buildFeatureCard(Icons.local_shipping, 'Fleet Management', 'Coordinate multiple deliveries efficiently', Colors.green),
              _buildFeatureCard(Icons.analytics, 'Business Analytics', 'Track performance and optimize operations', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(IconData icon, String title, String description, Color color) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
      color: Colors.orange.shade700,
      child: Column(
        children: [
          const Text('Expand Your Business', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PSARegistrationScreen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 24),
            ),
            child: const Text('Create PSA Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
