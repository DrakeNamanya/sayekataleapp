import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Dialog showing all implemented features and how to access them
class FeaturesGuideDialog extends StatelessWidget {
  final bool isSHG; // true for farmers, false for buyers

  const FeaturesGuideDialog({super.key, required this.isSHG});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'App Features Guide',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Features List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: isSHG ? _buildSHGFeatures() : _buildSMEFeatures(),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSHGFeatures() {
    return [
      const Text(
        'For Farmers (SHG):',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildFeatureCard(
        icon: Icons.location_on,
        title: 'GPS Location Display',
        description: 'Your farm location is shown to buyers with full address',
        color: Colors.green,
      ),
      _buildFeatureCard(
        icon: Icons.receipt_long,
        title: 'Order Management',
        description:
            '📱 Go to Orders tab\n✅ Accept or Reject orders\n🍳 Mark as Preparing\n📦 Mark as Ready',
        color: Colors.blue,
      ),
      _buildFeatureCard(
        icon: Icons.person,
        title: 'Customer Information',
        description: 'See buyer name and phone number on every order',
        color: Colors.purple,
      ),
      _buildFeatureCard(
        icon: Icons.notifications,
        title: 'Order Notifications',
        description: '🔔 Red badge on Orders tab\n🔔 Alert card on Dashboard',
        color: Colors.orange,
      ),
      _buildFeatureCard(
        icon: Icons.shopping_cart,
        title: 'Buy Inputs from PSA',
        description:
            '📱 Go to Buy Inputs tab\n🛒 Add items to cart\n📦 Order supplies',
        color: Colors.teal,
      ),
    ];
  }

  List<Widget> _buildSMEFeatures() {
    return [
      const Text(
        'For Buyers (SME):',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _buildFeatureCard(
        icon: Icons.map,
        title: 'Map View',
        description:
            '📱 Go to Browse tab\n🗺️ Tap Map icon (top-right)\n📍 See farmers by distance',
        color: Colors.blue,
      ),
      _buildFeatureCard(
        icon: Icons.star,
        title: 'Reviews & Ratings',
        description:
            '📱 Go to Orders tab\n✅ View completed orders\n⭐ Click "Leave a Review"',
        color: Colors.amber,
      ),
      _buildFeatureCard(
        icon: Icons.camera_alt,
        title: 'Photo Verification',
        description:
            '📱 Open delivered order\n📸 Tap "Mark as Received & Take Photo"\n✅ Confirm delivery',
        color: Colors.green,
      ),
      _buildFeatureCard(
        icon: Icons.location_on,
        title: 'Location-Based Search',
        description: 'Farmers shown with distance from your location',
        color: Colors.purple,
      ),
      _buildFeatureCard(
        icon: Icons.shopping_cart,
        title: 'Shopping Cart',
        description:
            '🛒 Add products to cart\n💰 Choose payment method\n📦 Track your orders',
        color: Colors.teal,
      ),
    ];
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
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
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
