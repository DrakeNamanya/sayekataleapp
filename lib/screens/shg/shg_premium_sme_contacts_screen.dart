import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user.dart' as app_user;
import '../../models/subscription.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/subscription_service.dart';

/// SHG Premium Screen - Shows all SME contacts for premium subscribers
/// Premium: UGX 50,000/year
class ShgPremiumSmeContactsScreen extends StatefulWidget {
  const ShgPremiumSmeContactsScreen({super.key});

  @override
  State<ShgPremiumSmeContactsScreen> createState() => _ShgPremiumSmeContactsScreenState();
}

class _ShgPremiumSmeContactsScreenState extends State<ShgPremiumSmeContactsScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  String _searchQuery = '';
  String? _selectedDistrict;
  String? _selectedProduct;
  
  List<String> _districts = [];
  List<String> _products = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      // Load districts
      final districtSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'sme')
          .get();
      
      final districts = districtSnapshot.docs
          .map((doc) => doc.data()['district'] as String?)
          .where((d) => d != null && d.isNotEmpty)
          .toSet()
          .toList();
      
      // Load product categories
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      
      final products = productSnapshot.docs
          .map((doc) => doc.data()['category'] as String?)
          .where((p) => p != null && p.isNotEmpty)
          .toSet()
          .toList();

      setState(() {
        _districts = districts.cast<String>()..sort();
        _products = products.cast<String>()..sort();
      });
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading filter options: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Premium SME Contacts')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium SME Contacts'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<Subscription?>(
        stream: _subscriptionService.streamUserSubscription(
          currentUser.id,
          SubscriptionType.shgPremium,
        ),
        builder: (context, subscriptionSnapshot) {
          if (subscriptionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscription = subscriptionSnapshot.data;

          // Check if user has active premium subscription
          if (subscription == null || !subscription.isActive) {
            return _buildSubscriptionPrompt(context, currentUser, subscription);
          }

          // Show SME contacts for premium users
          return _buildSmeContactsList(context, subscription);
        },
      ),
    );
  }

  // ============================================================================
  // SUBSCRIPTION PROMPT (Non-Premium Users)
  // ============================================================================

  Widget _buildSubscriptionPrompt(
    BuildContext context,
    app_user.AppUser user,
    Subscription? expiredSubscription,
  ) {
    final isExpired = expiredSubscription != null && !expiredSubscription.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'SHG PREMIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Status message
          if (isExpired)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your premium subscription expired on ${_formatDate(expiredSubscription.expiryDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          if (isExpired) const SizedBox(height: 24),

          // Benefits
          const Text(
            'Premium Benefits',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            icon: Icons.contacts,
            title: 'Access All SME Buyer Contacts',
            description: 'View phone numbers, locations, and business details',
          ),
          _buildBenefitItem(
            icon: Icons.filter_alt,
            title: 'Advanced Filtering',
            description: 'Filter by district, product category, and more',
          ),
          _buildBenefitItem(
            icon: Icons.search,
            title: 'Smart Search',
            description: 'Find buyers by name, location, or products',
          ),
          _buildBenefitItem(
            icon: Icons.phone,
            title: 'Direct Contact',
            description: 'Call or message buyers directly from the app',
          ),
          const SizedBox(height: 32),

          // Pricing
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Only',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'UGX 50,000',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'per year',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '≈ UGX 4,167 per month',
                    style: TextStyle(fontSize: 14, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Subscribe button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _showSubscriptionPaymentDialog(context, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isExpired ? 'Renew Premium Subscription' : 'Subscribe Now',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SME CONTACTS LIST (Premium Users)
  // ============================================================================

  Widget _buildSmeContactsList(BuildContext context, Subscription subscription) {
    return Column(
      children: [
        // Premium status banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.amber, Colors.orange],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREMIUM ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Expires: ${_formatDate(subscription.expiryDate)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (subscription.isExpiringSoon)
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to renewal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Renew'),
                ),
            ],
          ),
        ),

        // Search and filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search SME buyers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Districts')),
                        ..._districts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                      ],
                      onChanged: (value) => setState(() => _selectedDistrict = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedProduct,
                      decoration: InputDecoration(
                        labelText: 'Product Interest',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Products')),
                        ..._products.map((p) => DropdownMenuItem(value: p, child: Text(p))),
                      ],
                      onChanged: (value) => setState(() => _selectedProduct = value),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // SME list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildSmeQuery(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final smeDocs = snapshot.data!.docs;

              if (smeDocs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No SME buyers found', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: smeDocs.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final sme = app_user.AppUser.fromFirestore(
                    smeDocs[index].data() as Map<String, dynamic>,
                    smeDocs[index].id,
                  );
                  return _buildSmeCard(context, sme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildSmeQuery() {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'sme');

    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      query = query.where('district', isEqualTo: _selectedDistrict);
    }

    return query.snapshots();
  }

  Widget _buildSmeCard(BuildContext context, app_user.AppUser sme) {
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = sme.name.toLowerCase().contains(searchLower) ||
          (sme.location?.district?.toLowerCase().contains(searchLower) ?? false);
      
      if (!matchesSearch) return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    sme.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sme.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SME - ${sme.id}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.location_on, sme.location?.district ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, sme.phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, sme.email ?? 'N/A'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _callSme(sme.phone),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _messageSme(sme.phone),
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  Future<void> _callSme(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _messageSme(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSubscriptionPaymentDialog(BuildContext context, app_user.AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe to Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your MTN Mobile Money number:'),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '256XXXXXXXXX',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Store phone number
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'You will receive a prompt on your phone to confirm payment of UGX 50,000',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Process subscription payment
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
