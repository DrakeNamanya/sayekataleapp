import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/farmer.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/app_theme.dart';
import 'sme_farmer_detail_screen.dart';
import 'sme_browse_map_view.dart';

class SMEBrowseProductsScreen extends StatefulWidget {
  const SMEBrowseProductsScreen({super.key});

  @override
  State<SMEBrowseProductsScreen> createState() => _SMEBrowseProductsScreenState();
}

class _SMEBrowseProductsScreenState extends State<SMEBrowseProductsScreen> {
  ProductCategory _selectedCategory = ProductCategory.crop;
  String _searchQuery = '';
  bool _showFarmersOnly = false;
  
  // Mock data - In production, this would come from Firebase
  late List<Farmer> _allFarmers;
  
  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }
  
  void _initializeMockData() {
    // Create mock farmers with GPS coordinates around Uganda
    _allFarmers = [
      Farmer(
        id: 'SHG-00001',
        name: 'Green Valley Farm',
        phone: '+256700123456',
        profileImage: null,
        location: Location(
          latitude: 0.3476,
          longitude: 32.5825,
          district: 'Kampala',
          subcounty: 'Central',
          parish: 'Nakasero',
          village: 'Market Street',
        ),
        rating: 4.8,
        totalReviews: 45,
        totalOrders: 120,
        products: [
          Product(
            id: 'prod1',
            name: 'Fresh Onions',
            category: ProductCategory.onions,
            description: 'Organic red onions, freshly harvested',
            price: 3000.0,
            unitSize: 1,
            unit: 'kg',
            stockQuantity: 500,
            images: const [],
            farmId: 'SHG-00001',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod2',
            name: 'Ripe Tomatoes',
            category: ProductCategory.tomatoes,
            description: 'Fresh tomatoes from organic farm',
            price: 2500.0,
            unitSize: 1,
            unit: 'kg',
            stockQuantity: 300,
            images: const [],
            farmId: 'SHG-00001',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      ),
      Farmer(
        id: 'SHG-00002',
        name: 'Sunrise Poultry Farm',
        phone: '+256700234567',
        profileImage: null,
        location: Location(
          latitude: 0.3520,
          longitude: 32.5950,
          district: 'Kampala',
          subcounty: 'Kawempe',
          parish: 'Kazo',
          village: 'Farm Road',
        ),
        rating: 4.6,
        totalReviews: 38,
        totalOrders: 95,
        products: [
          Product(
            id: 'prod3',
            name: 'Broiler Chicken',
            category: ProductCategory.broilers,
            description: 'Live broiler chickens, 2kg average',
            price: 18000.0,
            unitSize: 1,
            unit: 'piece',
            stockQuantity: 50,
            images: const [],
            farmId: 'SHG-00002',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod4',
            name: 'Fresh Eggs',
            category: ProductCategory.eggs,
            description: 'Farm fresh eggs from free-range chickens',
            price: 12000.0,
            unitSize: 1,
            unit: 'tray',
            stockQuantity: 80,
            images: const [],
            farmId: 'SHG-00002',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod5',
            name: 'Organic Manure',
            category: ProductCategory.organicManure,
            description: 'High-quality organic poultry manure',
            price: 5000.0,
            unitSize: 1,
            unit: 'bag',
            stockQuantity: 100,
            images: const [],
            farmId: 'SHG-00002',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 240)),
      ),
      Farmer(
        id: 'SHG-00003',
        name: 'Happy Goat Farm',
        phone: '+256700345678',
        profileImage: null,
        location: Location(
          latitude: 0.3200,
          longitude: 32.5700,
          district: 'Wakiso',
          subcounty: 'Nansana',
          parish: 'Ganda',
          village: 'Goat Valley',
        ),
        rating: 4.9,
        totalReviews: 52,
        totalOrders: 140,
        products: [
          Product(
            id: 'prod6',
            name: 'Male Goats',
            category: ProductCategory.maleGoats,
            description: 'Healthy male goats for breeding',
            price: 250000.0,
            unitSize: 1,
            unit: 'piece',
            stockQuantity: 15,
            images: const [],
            farmId: 'SHG-00003',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod7',
            name: 'Female Goats',
            category: ProductCategory.femaleGoats,
            description: 'Productive female goats',
            price: 280000.0,
            unitSize: 1,
            unit: 'piece',
            stockQuantity: 12,
            images: const [],
            farmId: 'SHG-00003',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod8',
            name: 'Goat Manure',
            category: ProductCategory.goatManure,
            description: 'Premium goat manure for gardens',
            price: 8000.0,
            unitSize: 1,
            unit: 'bag',
            stockQuantity: 60,
            images: const [],
            farmId: 'SHG-00003',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 365)),
      ),
      Farmer(
        id: 'SHG-00004',
        name: 'Fresh Milk Dairy',
        phone: '+256700456789',
        profileImage: null,
        location: Location(
          latitude: 0.3800,
          longitude: 32.6100,
          district: 'Mukono',
          subcounty: 'Seeta',
          parish: 'Namugongo',
          village: 'Dairy Lane',
        ),
        rating: 4.7,
        totalReviews: 41,
        totalOrders: 110,
        products: [
          Product(
            id: 'prod9',
            name: 'Fresh Cow Milk',
            category: ProductCategory.milk,
            description: 'Fresh unpasteurized cow milk',
            price: 2000.0,
            unitSize: 1,
            unit: 'liter',
            stockQuantity: 200,
            images: const [],
            farmId: 'SHG-00004',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod10',
            name: 'Dairy Cows',
            category: ProductCategory.cowsFemale,
            description: 'High-yielding dairy cows',
            price: 3500000.0,
            unitSize: 1,
            unit: 'piece',
            stockQuantity: 5,
            images: const [],
            farmId: 'SHG-00004',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod11',
            name: 'Cow Manure',
            category: ProductCategory.cowManure,
            description: 'Rich cow manure for agriculture',
            price: 10000.0,
            unitSize: 1,
            unit: 'bag',
            stockQuantity: 80,
            images: const [],
            farmId: 'SHG-00004',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 300)),
      ),
      Farmer(
        id: 'SHG-00005',
        name: 'Tropical Fruits Farm',
        phone: '+256700567890',
        profileImage: null,
        location: Location(
          latitude: 0.3100,
          longitude: 32.5600,
          district: 'Wakiso',
          subcounty: 'Kira',
          parish: 'Namugongo',
          village: 'Fruit Garden',
        ),
        rating: 4.5,
        totalReviews: 33,
        totalOrders: 85,
        products: [
          Product(
            id: 'prod12',
            name: 'Watermelon',
            category: ProductCategory.watermelon,
            description: 'Sweet watermelons, 5-8kg each',
            price: 5000.0,
            unitSize: 1,
            unit: 'piece',
            stockQuantity: 40,
            images: const [],
            farmId: 'SHG-00005',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Product(
            id: 'prod13',
            name: 'Passion Fruits',
            category: ProductCategory.passionFruits,
            description: 'Fresh passion fruits',
            price: 4000.0,
            unitSize: 1,
            unit: 'kg',
            stockQuantity: 150,
            images: const [],
            farmId: 'SHG-00005',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 150)),
      ),
    ];
  }
  
  List<Farmer> get _filteredFarmers {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final smeLocation = authProvider.currentUser?.location;
    
    var farmers = _allFarmers;
    
    // Filter by category
    farmers = farmers.where((farmer) {
      final productsInCategory = farmer.getProductsByCategory(_selectedCategory);
      return productsInCategory.isNotEmpty;
    }).toList();
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      farmers = farmers.where((farmer) {
        final matchesName = farmer.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesProduct = farmer.products.any(
          (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        );
        return matchesName || matchesProduct;
      }).toList();
    }
    
    // Sort by distance if SME has location
    if (smeLocation != null) {
      farmers.sort((a, b) {
        final distanceA = a.getDistanceFrom(smeLocation) ?? double.infinity;
        final distanceB = b.getDistanceFrom(smeLocation) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }
    
    return farmers;
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final smeLocation = authProvider.currentUser?.location;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Dashboard',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SMEBrowseMapView(),
                ),
              );
            },
            tooltip: 'Map View',
          ),
          IconButton(
            icon: Icon(_showFarmersOnly ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _showFarmersOnly = !_showFarmersOnly;
              });
            },
            tooltip: _showFarmersOnly ? 'Show Products' : 'Show Farmers',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search farmers or products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Category Tabs
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ProductCategoryExtension.mainCategories.map((category) {
                final isSelected = _selectedCategory == category;
                final count = _allFarmers.fold<int>(
                  0,
                  (sum, farmer) => sum + farmer.getProductsByCategory(category).length,
                );
                
                return _CategoryTab(
                  category: category,
                  count: count,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Location Warning
          if (smeLocation == null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off, color: AppTheme.warningColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete your profile to see farmers sorted by distance',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Farmers List
          Expanded(
            child: _filteredFarmers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No farmers found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFarmers.length,
                    itemBuilder: (context, index) {
                      final farmer = _filteredFarmers[index];
                      return _FarmerCard(
                        farmer: farmer,
                        smeLocation: smeLocation,
                        selectedCategory: _selectedCategory,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final ProductCategory category;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _CategoryTab({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });
  
  IconData get _icon {
    switch (category) {
      case ProductCategory.crop:
        return Icons.grass;
      case ProductCategory.poultry:
        return Icons.egg_outlined;
      case ProductCategory.goats:
        return Icons.pets_outlined;
      case ProductCategory.cows:
        return Icons.agriculture_outlined;
      default:
        return Icons.category;
    }
  }
  
  Color get _color {
    switch (category) {
      case ProductCategory.crop:
        return AppTheme.accentColor;
      case ProductCategory.poultry:
        return AppTheme.primaryColor;
      case ProductCategory.goats:
        return Colors.brown.shade600;
      case ProductCategory.cows:
        return Colors.blue.shade700;
      default:
        return AppTheme.textSecondary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              category.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : _color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : _color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerCard extends StatelessWidget {
  final Farmer farmer;
  final Location? smeLocation;
  final ProductCategory selectedCategory;
  
  const _FarmerCard({
    required this.farmer,
    required this.smeLocation,
    required this.selectedCategory,
  });
  
  @override
  Widget build(BuildContext context) {
    final productsInCategory = farmer.getProductsByCategory(selectedCategory);
    final distance = farmer.getDistanceFrom(smeLocation);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SMEFarmerDetailScreen(farmer: farmer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farmer Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: farmer.profileImage != null
                        ? null
                        : Icon(
                            Icons.store,
                            size: 30,
                            color: AppTheme.primaryColor,
                          ),
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
                                farmer.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (farmer.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 12,
                                      color: AppTheme.successColor,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.successColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: AppTheme.warningColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${farmer.rating.toStringAsFixed(1)} (${farmer.totalReviews})',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.receipt_long,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${farmer.totalOrders} orders',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      farmer.location?.fullAddress ?? 'Location not available',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        farmer.getDistanceText(smeLocation),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              // Products in Category
              Text(
                '${productsInCategory.length} ${selectedCategory.displayName} products',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Product List
              ...productsInCategory.take(3).map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'UGX ${product.price.toStringAsFixed(0)}/${product.unit}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'In stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              )),
              
              if (productsInCategory.length > 3)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SMEFarmerDetailScreen(farmer: farmer),
                      ),
                    );
                  },
                  child: Text('View all ${productsInCategory.length} products'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
