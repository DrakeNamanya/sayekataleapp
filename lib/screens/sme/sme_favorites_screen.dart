import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/farmer.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import 'sme_farmer_detail_screen.dart';

class SMEFavoritesScreen extends StatefulWidget {
  const SMEFavoritesScreen({super.key});

  @override
  State<SMEFavoritesScreen> createState() => _SMEFavoritesScreenState();
}

class _SMEFavoritesScreenState extends State<SMEFavoritesScreen> {
  // Mock favorite farmers - In production, this would come from Firebase/SharedPreferences
  late List<String> _favoriteFarmerIds;
  late List<Farmer> _favoriteFarmers;
  
  @override
  void initState() {
    super.initState();
    _initializeMockData();
  }
  
  void _initializeMockData() {
    // Mock favorite farmer IDs
    _favoriteFarmerIds = ['SHG-00001', 'SHG-00002', 'SHG-00003'];
    
    // Mock favorite farmers data
    _favoriteFarmers = [
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
        ],
        isVerified: true,
        joinedDate: DateTime.now().subtract(const Duration(days: 365)),
      ),
    ];
  }
  
  void _removeFavorite(String farmerId) {
    setState(() {
      _favoriteFarmerIds.remove(farmerId);
      _favoriteFarmers.removeWhere((farmer) => farmer.id == farmerId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final smeLocation = authProvider.currentUser?.location;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        automaticallyImplyLeading: false,
      ),
      body: _favoriteFarmers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Favorite Farmers Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Save your favorite farmers here for quick access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteFarmers.length,
              itemBuilder: (context, index) {
                final farmer = _favoriteFarmers[index];
                return _FavoriteFarmerCard(
                  farmer: farmer,
                  smeLocation: smeLocation,
                  onRemove: () => _removeFavorite(farmer.id),
                );
              },
            ),
    );
  }
}

class _FavoriteFarmerCard extends StatelessWidget {
  final Farmer farmer;
  final Location? smeLocation;
  final VoidCallback onRemove;
  
  const _FavoriteFarmerCard({
    required this.farmer,
    required this.smeLocation,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
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
                    child: Icon(
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
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remove from Favorites'),
                          content: Text('Remove ${farmer.name} from your favorites?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                onRemove();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorColor,
                              ),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Remove from favorites',
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
              
              // Products Preview
              Text(
                '${farmer.products.length} products available',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              // Product Categories
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductCategoryExtension.mainCategories
                    .where((category) {
                      return farmer.getProductsByCategory(category).isNotEmpty;
                    })
                    .map((category) {
                      final count = farmer.getProductsByCategory(category).length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${category.displayName} ($count)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    })
                    .toList(),
              ),
              
              const SizedBox(height: 12),
              
              // Quick Order Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SMEFarmerDetailScreen(farmer: farmer),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Browse Products'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
