import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../services/subscription_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';

/// Premium Farmer Directory for SME Buyers
/// Allows SME buyers to access farmers by district and product category
class PremiumFarmerDirectoryScreen extends StatefulWidget {
  const PremiumFarmerDirectoryScreen({super.key});

  @override
  State<PremiumFarmerDirectoryScreen> createState() =>
      _PremiumFarmerDirectoryScreenState();
}

class _PremiumFarmerDirectoryScreenState
    extends State<PremiumFarmerDirectoryScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();

  List<FarmerContact> _allContacts = [];
  List<FarmerContact> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;
  bool _hasActiveSubscription = false;

  // Filters
  String _selectedDistrict = 'All';
  String _selectedProduct = 'All';
  bool _verifiedOnly = false;

  // Available districts (will be populated from data)
  List<String> _districts = ['All'];

  // Common product categories for farmers
  final List<String> _productCategories = [
    'All',
    'Poultry (Eggs)',
    'Poultry (Broilers)',
    'Poultry (Layers)',
    'Poultry (Chicks)',
    'Vegetables',
    'Fruits',
    'Grains',
    'Dairy',
    'Livestock',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _checkSubscription();
    _loadFarmerContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscription() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? '';

    try {
      final hasSubscription =
          await _subscriptionService.hasActiveFarmerDirectorySubscription(userId);
      setState(() {
        _hasActiveSubscription = hasSubscription;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking subscription: $e');
      }
    }
  }

  Future<void> _loadFarmerContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contacts = await _subscriptionService.getAllFarmerContacts();

      // Extract unique districts
      final districts = contacts
          .map((c) => c.district)
          .where((d) => d.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _districts = ['All', ...districts];
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('✅ Loaded ${contacts.length} farmer contacts');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('❌ Error loading farmer contacts: $e');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      List<FarmerContact> filtered = List.from(_allContacts);

      // District filter
      if (_selectedDistrict != 'All') {
        filtered = filtered
            .where((c) =>
                c.district.toLowerCase() == _selectedDistrict.toLowerCase())
            .toList();
      }

      // Product filter
      if (_selectedProduct != 'All') {
        filtered = filtered
            .where((c) => c.primaryProducts
                .any((p) => p.toLowerCase().contains(_selectedProduct.toLowerCase())))
            .toList();
      }

      // Verified filter
      if (_verifiedOnly) {
        filtered = filtered.where((c) => c.isVerified).toList();
      }

      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((c) {
          return c.businessName.toLowerCase().contains(searchQuery) ||
              c.district.toLowerCase().contains(searchQuery) ||
              c.primaryProducts.any((p) => p.toLowerCase().contains(searchQuery));
        }).toList();
      }

      setState(() {
        _filteredContacts = filtered;
        _isLoading = false;
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedDistrict = 'All';
      _selectedProduct = 'All';
      _verifiedOnly = false;
      _searchController.clear();
      _filteredContacts = _allContacts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Farmer Directory'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasActiveSubscription)
            IconButton(
              icon: const Icon(Icons.verified),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ You have an active premium subscription'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
        ],
      ),
      body: !_hasActiveSubscription
          ? _buildSubscriptionPrompt()
          : Column(
              children: [
                _buildFilterSection(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? _buildErrorWidget()
                          : _filteredContacts.isEmpty
                              ? _buildEmptyState()
                              : _buildContactsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSubscriptionPrompt() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Unlock Premium Farmer Directory',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Get direct access to verified farmers across Uganda',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureCard(
              icon: Icons.location_on,
              title: 'Search by District',
              description: 'Find farmers in specific locations across Uganda',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.category,
              title: 'Filter by Products',
              description: 'Search for poultry, vegetables, fruits, and more',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.verified_user,
              title: 'Verified Contacts',
              description: 'Access verified farmer phone numbers and details',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.phone,
              title: 'Direct Contact',
              description: 'Call farmers directly for bulk orders and negotiations',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'UGX 50,000',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'per year',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSubscriptionPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Subscribe Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  'Complete Payment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentDetail('Subscription', 'Premium Farmer Directory'),
              _buildPaymentDetail('Duration', '1 Year'),
              _buildPaymentDetail('Amount', 'UGX 50,000'),
              const Divider(height: 32),
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPaymentOption(
                'MTN Mobile Money',
                Icons.phone_android,
                () => _processPayment('MTN MoMo'),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                'Airtel Money',
                Icons.phone_android,
                () => _processPayment('Airtel Money'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Text(
              method,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(String method) async {
    Navigator.pop(context); // Close payment sheet
    
    // Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing payment...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Close processing dialog

    // TODO: Implement actual payment processing
    // For now, show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Initiated'),
        content: Text(
          'Please complete the payment on your $method phone.\n\nOnce payment is confirmed, your subscription will be activated.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh subscription status
              _checkSubscription();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search farmers, products, districts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // District filter
                DropdownButton<String>(
                  value: _selectedDistrict,
                  items: _districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDistrict = value);
                      _applyFilters();
                    }
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 12),
                
                // Product filter
                DropdownButton<String>(
                  value: _selectedProduct,
                  items: _productCategories
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProduct = value);
                      _applyFilters();
                    }
                  },
                  underline: const SizedBox(),
                ),
                const SizedBox(width: 12),
                
                // Verified only filter
                FilterChip(
                  label: const Text('Verified Only'),
                  selected: _verifiedOnly,
                  onSelected: (selected) {
                    setState(() => _verifiedOnly = selected);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 12),
                
                // Reset button
                if (_selectedDistrict != 'All' ||
                    _selectedProduct != 'All' ||
                    _verifiedOnly ||
                    _searchController.text.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Reset'),
                    onPressed: _resetFilters,
                  ),
              ],
            ),
          ),
          
          // Results count
          const SizedBox(height: 8),
          Text(
            '${_filteredContacts.length} farmer${_filteredContacts.length != 1 ? 's' : ''} found',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _filteredContacts.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactCard(contact);
      },
    );
  }

  Widget _buildContactCard(FarmerContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showContactDetails(contact),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (contact.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    contact.district,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: contact.primaryProducts.take(3).map((product) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makePhoneCall(contact.phoneNumber),
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showContactDetails(contact),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactDetails(FarmerContact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contact.businessName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (contact.isVerified)
                  const Icon(Icons.verified, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, contact.district),
            _buildDetailRow(Icons.phone, contact.phoneNumber),
            const SizedBox(height: 16),
            const Text(
              'Primary Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: contact.primaryProducts.map((product) {
                return Chip(
                  label: Text(product),
                  backgroundColor: Colors.green.shade50,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _makePhoneCall(contact.phoneNumber);
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black87,
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No farmers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading contacts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFarmerContacts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
