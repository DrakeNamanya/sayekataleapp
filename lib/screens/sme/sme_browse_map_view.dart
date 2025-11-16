import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import '../../models/farmer.dart';
import '../../models/user.dart';
// import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'sme_farmer_detail_screen.dart';

/// Map-style view for browsing farmers by location
/// Shows farmers organized by district with distance information
class SMEBrowseMapView extends StatefulWidget {
  const SMEBrowseMapView({super.key});

  @override
  State<SMEBrowseMapView> createState() => _SMEBrowseMapViewState();
}

class _SMEBrowseMapViewState extends State<SMEBrowseMapView> {
  String _selectedDistrict = 'All Districts';

  // Mock farmer data with locations (in real app, fetch from Firebase)
  final List<Farmer> _allFarmers = [
    Farmer(
      id: 'farmer1',
      name: 'Ngobi Peter',
      phone: '+256789123456',
      location: Location(
        district: 'Mayuge',
        subcounty: 'Imanyiro',
        parish: 'Mbaale',
        village: 'Wanswa',
        latitude: 0.4278,
        longitude: 33.4889,
      ),
      rating: 4.8,
      totalReviews: 156,
      totalOrders: 234,
      products: [],
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
    ),
    Farmer(
      id: 'farmer2',
      name: 'Sarah Nakato',
      phone: '+256772234567',
      location: Location(
        district: 'Mayuge',
        subcounty: 'Baitambogwe',
        parish: 'Bukabooli',
        village: 'Kigungu',
        latitude: 0.4156,
        longitude: 33.4712,
      ),
      rating: 4.6,
      totalReviews: 89,
      totalOrders: 145,
      products: [],
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 280)),
    ),
    Farmer(
      id: 'farmer3',
      name: 'John Mukasa',
      phone: '+256701345678',
      location: Location(
        district: 'Jinja',
        subcounty: 'Budondo',
        parish: 'Kyabirwa',
        village: 'Masese',
        latitude: 0.4619,
        longitude: 33.2144,
      ),
      rating: 4.9,
      totalReviews: 203,
      totalOrders: 312,
      products: [],
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 450)),
    ),
    Farmer(
      id: 'farmer4',
      name: 'Grace Nambi',
      phone: '+256752456789',
      location: Location(
        district: 'Mayuge',
        subcounty: 'Kigandalo',
        parish: 'Busakira',
        village: 'Namasumbi',
        latitude: 0.4089,
        longitude: 33.5123,
      ),
      rating: 4.7,
      totalReviews: 67,
      totalOrders: 98,
      products: [],
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 180)),
    ),
    Farmer(
      id: 'farmer5',
      name: 'David Ssemakula',
      phone: '+256789567890',
      location: Location(
        district: 'Jinja',
        subcounty: 'Walukuba',
        parish: 'Mpumudde',
        village: 'Bugembe',
        latitude: 0.4497,
        longitude: 33.1956,
      ),
      rating: 4.5,
      totalReviews: 45,
      totalOrders: 67,
      products: [],
      isVerified: false,
      joinedDate: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  List<Farmer> get _filteredFarmers {
    if (_selectedDistrict == 'All Districts') {
      return _allFarmers;
    }
    return _allFarmers
        .where((f) => f.location?.district == _selectedDistrict)
        .toList();
  }

  List<String> get _districts {
    final districts = _allFarmers
        .map((f) => f.location?.district ?? 'Unknown')
        .toSet()
        .toList();
    districts.sort();
    return ['All Districts', ...districts];
  }

  //   Map<String, List<Farmer>> get _farmersByDistrict {
  //     final Map<String, List<Farmer>> grouped = {};
  //     for (var farmer in _filteredFarmers) {
  //       final district = farmer.location?.district ?? 'Unknown';
  //       grouped[district] = [...(grouped[district] ?? []), farmer];
  //     }
  //     return grouped;
  //   }
  @override
  Widget build(BuildContext context) {
    // Auth provider and current user available if needed for future use
    // final authProvider = Provider.of<AuthProvider>(context);
    // final currentUser = authProvider.currentUser;
    final currentUser = null; // Placeholder for user location features

    // Sort farmers by distance if user has location
    final sortedFarmers = _filteredFarmers.toList();
    if (currentUser?.location != null) {
      sortedFarmers.sort((a, b) {
        final distA =
            a.getDistanceFrom(currentUser!.location) ?? double.infinity;
        final distB =
            b.getDistanceFrom(currentUser.location) ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers Near You'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currentUser?.location?.fullAddress ??
                                'Location not set',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                      '${_filteredFarmers.length}',
                      'Farmers',
                      Icons.agriculture,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      _districts.length > 1 ? '${_districts.length - 1}' : '0',
                      'Districts',
                      Icons.map,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      sortedFarmers.isNotEmpty && currentUser?.location != null
                          ? sortedFarmers[0]
                                .getDistanceText(currentUser!.location)
                                .split(' ')[0]
                          : '--',
                      'Nearest',
                      Icons.navigation,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // District Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _districts.map((district) {
                  final isSelected = district == _selectedDistrict;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(district),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedDistrict = district;
                        });
                      },
                      selectedColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      checkmarkColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Farmers List by Distance
          Expanded(
            child: sortedFarmers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No farmers found in $_selectedDistrict',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = sortedFarmers[index];
                      final distance = currentUser?.location != null
                          ? farmer.getDistanceText(currentUser!.location)
                          : 'Distance unknown';

                      return _FarmerMapCard(
                        farmer: farmer,
                        distance: distance,
                        rank: index + 1,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SMEFarmerDetailScreen(farmer: farmer),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Farmers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('By Rating'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // In real app: implement rating filter
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified),
              title: const Text('Verified Only'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // In real app: filter verified farmers
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('By Category'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // In real app: filter by product category
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
  }
}

class _FarmerMapCard extends StatelessWidget {
  final Farmer farmer;
  final String distance;
  final int rank;
  final VoidCallback onTap;

  const _FarmerMapCard({
    required this.farmer,
    required this.distance,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rank <= 3
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3
                          ? Colors.amber.shade800
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Farmer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            farmer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (farmer.isVerified)
                          Icon(
                            Icons.verified,
                            size: 20,
                            color: Colors.blue.shade600,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          farmer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${farmer.totalReviews})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.shopping_bag,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${farmer.totalOrders} orders',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farmer.location?.fullAddress ??
                                'Location not available',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Distance Badge
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation,
                          size: 14,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          distance.split(' ')[0], // Just the number
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    distance.split(' ').skip(1).join(' '), // Unit
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
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
}
