import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription.dart';
import '../../services/subscription_service.dart';

class PremiumSMEDirectoryScreen extends StatefulWidget {
  const PremiumSMEDirectoryScreen({super.key});

  @override
  State<PremiumSMEDirectoryScreen> createState() =>
      _PremiumSMEDirectoryScreenState();
}

class _PremiumSMEDirectoryScreenState extends State<PremiumSMEDirectoryScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();

  List<SMEContact> _allContacts = [];
  List<SMEContact> _filteredContacts = [];
  bool _isLoading = true;
  String? _error;

  // Filters
  String _selectedDistrict = 'All';
  String _selectedProduct = 'All';
  bool _verifiedOnly = false;

  // Available districts (will be populated from data)
  List<String> _districts = ['All'];

  // Common product categories
  final List<String> _productCategories = [
    'All',
    'Eggs',
    'Broilers',
    'Layers',
    'Day-old Chicks',
    'Chicken Meat',
    'Feeds',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadSMEContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSMEContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contacts = await _subscriptionService.getAllSMEContacts();

      // Extract unique districts
      final districts =
          contacts
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
        debugPrint('✅ Loaded ${contacts.length} SME contacts');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('❌ Error loading SME contacts: $e');
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _isLoading = true;
    });

    // Apply filters in memory for better performance
    var filtered = List<SMEContact>.from(_allContacts);

    // District filter
    if (_selectedDistrict != 'All') {
      filtered = filtered
          .where((c) => c.district == _selectedDistrict)
          .toList();
    }

    // Product filter
    if (_selectedProduct != 'All') {
      filtered = filtered.where((c) {
        return c.products.any(
          (p) => p.toLowerCase().contains(_selectedProduct.toLowerCase()),
        );
      }).toList();
    }

    // Verified filter
    if (_verifiedOnly) {
      filtered = filtered.where((c) => c.isVerified).toList();
    }

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.phone.contains(query) ||
            c.email.toLowerCase().contains(query) ||
            c.district.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredContacts = filtered;
      _isLoading = false;
    });

    if (kDebugMode) {
      debugPrint('📊 Filtered: ${filtered.length} contacts');
    }
  }

  void _clearFilters() {
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text('Premium SME Directory'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSMEContacts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Premium Badge
          _buildPremiumBanner(),

          // Search Bar
          _buildSearchBar(),

          // Filters
          _buildFilters(),

          // Results Count
          _buildResultsCount(),

          // Contacts List
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[700]!, Colors.purple[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Access',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Full access to all SME contacts',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, email, district...',
                border: InputBorder.none,
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // District Filter
          Row(
            children: [
              const Icon(Icons.location_on, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'District:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedDistrict,
                  isExpanded: true,
                  items: _districts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Product Filter
          Row(
            children: [
              const Icon(Icons.category, size: 20, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'Product:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedProduct,
                  isExpanded: true,
                  items: _productCategories.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProduct = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Verified Only Filter
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Row(
              children: [
                Icon(Icons.verified, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text('Verified users only'),
              ],
            ),
            value: _verifiedOnly,
            onChanged: (value) {
              setState(() {
                _verifiedOnly = value ?? false;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '${_filteredContacts.length} SME contact(s) found',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSMEContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No SME contacts found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        return _buildContactCard(_filteredContacts[index]);
      },
    );
  }

  Widget _buildContactCard(SMEContact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and verified badge
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: contact.profileImage != null
                      ? NetworkImage(contact.profileImage!)
                      : null,
                  child: contact.profileImage == null
                      ? const Icon(Icons.person, size: 30, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (contact.isVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since ${contact.registeredAt.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Contact Information
            _buildInfoRow(
              Icons.phone,
              'Phone',
              contact.phone,
              onTap: () => _makeCall(contact.phone),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.email,
              'Email',
              contact.email,
              onTap: () => _sendEmail(contact.email),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'District', contact.district),

            if (contact.subCounty != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_city,
                'Sub-County',
                contact.subCounty!,
              ),
            ],

            if (contact.village != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.home, 'Village', contact.village!),
            ],

            // Products interested in
            if (contact.products.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Interested Products:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: contact.products.map((product) {
                  return Chip(
                    label: Text(product),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap != null ? Colors.blue : Colors.grey[800],
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }
}
