class Product {
  final String id;
  final String? systemId; // Unique system-generated ID for product tracking (e.g., PROD-2024-001)
  final String farmId;
  final String name;
  final String? businessName; // Legal business name for PSA products (for searchability)
  final String? description;
  final ProductCategory category;
  final String? mainCategory; // crop, oilSeeds, poultry, goats, cows
  final String? subcategory; // tomatoes, broilers, etc.
  final String unit; // KGs, grams, number, tray, 100kg bag, litre
  final int unitSize; // e.g., 30 eggs/tray
  final double price;
  final int stockQuantity;
  final int lowStockThreshold;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFeatured;
  final int totalSales; // Track sales count for "Top" badge
  final double averageRating; // Track average rating for "Top" badge

  Product({
    required this.id,
    this.systemId,
    required this.farmId,
    required this.name,
    this.businessName,
    this.description,
    required this.category,
    this.mainCategory,
    this.subcategory,
    required this.unit,
    required this.unitSize,
    required this.price,
    required this.stockQuantity,
    this.lowStockThreshold = 10,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isFeatured = false,
    this.totalSales = 0,
    this.averageRating = 0.0,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;
  bool get isOutOfStock => stockQuantity == 0;
  
  /// Calculate if product qualifies for "Top" badge
  /// Criteria: totalSales >= 10 AND averageRating >= 4.0
  bool get isTop => totalSales >= 10 && averageRating >= 4.0;

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    // Helper function to parse DateTime from Firestore Timestamp or String
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return Product(
      id: id,
      systemId: data['system_id'],
      farmId: data['farmer_id'] ?? data['farm_id'] ?? '', // Support both field names
      name: data['name'] ?? '',
      businessName: data['business_name'],
      description: data['description'],
      category: ProductCategory.values.firstWhere(
        (e) => e.toString() == 'ProductCategory.${data['category']}',
        orElse: () => ProductCategory.crop,
      ),
      mainCategory: data['main_category'],
      subcategory: data['subcategory'],
      unit: data['unit'] ?? '',
      unitSize: data['unit_size'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
      stockQuantity: data['stock_quantity'] ?? 0,
      lowStockThreshold: data['low_stock_threshold'] ?? 10,
      images: data['image_url'] != null 
        ? [data['image_url']] 
        : (data['images'] != null ? List<String>.from(data['images']) : []),
      createdAt: parseDateTime(data['created_at']),
      updatedAt: parseDateTime(data['updated_at']),
      isFeatured: data['is_featured'] ?? false,
      totalSales: data['total_sales'] ?? 0,
      averageRating: (data['average_rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'system_id': systemId ?? _generateSystemId(), // Auto-generate if not provided
      'farm_id': farmId,
      'farmer_id': farmId, // Backward compatibility
      'name': name,
      'business_name': businessName,
      'description': description,
      'category': category.toString().split('.').last,
      'main_category': mainCategory,
      'subcategory': subcategory,
      'unit': unit,
      'unit_size': unitSize,
      'price': price,
      'stock_quantity': stockQuantity,
      'is_available': stockQuantity > 0, // CRITICAL: Required for SME product queries
      'low_stock_threshold': lowStockThreshold,
      'images': images,
      'image_url': images.isNotEmpty ? images.first : null, // Backward compatibility
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_featured': isFeatured,
      'total_sales': totalSales,
      'average_rating': averageRating,
    };
  }
  
  /// Generate unique system ID for product (e.g., PROD-2024-123456)
  static String _generateSystemId() {
    final now = DateTime.now();
    final year = now.year;
    final timestamp = now.millisecondsSinceEpoch.toString().substring(7);
    return 'PROD-$year-$timestamp';
  }
}

enum ProductCategory {
  // Main categories
  crop,
  poultry,
  goats,
  cows,
  
  // Crop products
  onions,
  watermelon,
  tomatoes,
  groundNuts,
  soya,
  passionFruits,
  
  // Poultry products
  broilers,
  sasso,
  eggs,
  localEggs,
  localChicken,
  incubationServices,
  organicManure,
  offLayers,
  
  // Goat products
  maleGoats,
  femaleGoats,
  goatManure,
  
  // Cow products
  milk,
  bulls,
  cowsFemale,
  cowManure,
  
  // PSA products (inputs)
  dayOldChicks,
  hoes,
  chemicals,
  fertilizers,
  feeds,
  
  other,
}

extension ProductCategoryExtension on ProductCategory {
  String get displayName {
    switch (this) {
      // Main categories
      case ProductCategory.crop:
        return 'Crop';
      case ProductCategory.poultry:
        return 'Poultry';
      case ProductCategory.goats:
        return 'Goats';
      case ProductCategory.cows:
        return 'Cows';
      
      // Crop products
      case ProductCategory.onions:
        return 'Onions';
      case ProductCategory.watermelon:
        return 'Watermelon';
      case ProductCategory.tomatoes:
        return 'Tomatoes';
      case ProductCategory.groundNuts:
        return 'Ground Nuts';
      case ProductCategory.soya:
        return 'Soya';
      case ProductCategory.passionFruits:
        return 'Passion Fruits';
      
      // Poultry products
      case ProductCategory.broilers:
        return 'Broilers';
      case ProductCategory.sasso:
        return 'Sasso';
      case ProductCategory.eggs:
        return 'Eggs';
      case ProductCategory.localEggs:
        return 'Local Eggs';
      case ProductCategory.localChicken:
        return 'Local Chicken';
      case ProductCategory.incubationServices:
        return 'Incubation Services';
      case ProductCategory.organicManure:
        return 'Organic Manure';
      case ProductCategory.offLayers:
        return 'Off-Layers';
      
      // Goat products
      case ProductCategory.maleGoats:
        return 'Male Goats';
      case ProductCategory.femaleGoats:
        return 'Female Goats';
      case ProductCategory.goatManure:
        return 'Goat Manure';
      
      // Cow products
      case ProductCategory.milk:
        return 'Milk';
      case ProductCategory.bulls:
        return 'Bulls';
      case ProductCategory.cowsFemale:
        return 'Cows';
      case ProductCategory.cowManure:
        return 'Cow Manure';
      
      // PSA products
      case ProductCategory.dayOldChicks:
        return 'Day-Old Chicks';
      case ProductCategory.hoes:
        return 'Hoes';
      case ProductCategory.chemicals:
        return 'Chemicals';
      case ProductCategory.fertilizers:
        return 'Fertilizers';
      case ProductCategory.feeds:
        return 'Feeds';
      
      case ProductCategory.other:
        return 'Other Products';
    }
  }
  
  // Get parent category for subcategories
  ProductCategory get parentCategory {
    switch (this) {
      case ProductCategory.onions:
      case ProductCategory.watermelon:
      case ProductCategory.tomatoes:
      case ProductCategory.groundNuts:
      case ProductCategory.soya:
      case ProductCategory.passionFruits:
        return ProductCategory.crop;
      
      case ProductCategory.broilers:
      case ProductCategory.sasso:
      case ProductCategory.eggs:
      case ProductCategory.localEggs:
      case ProductCategory.localChicken:
      case ProductCategory.incubationServices:
      case ProductCategory.organicManure:
      case ProductCategory.offLayers:
        return ProductCategory.poultry;
      
      case ProductCategory.maleGoats:
      case ProductCategory.femaleGoats:
      case ProductCategory.goatManure:
        return ProductCategory.goats;
      
      case ProductCategory.milk:
      case ProductCategory.bulls:
      case ProductCategory.cowsFemale:
      case ProductCategory.cowManure:
        return ProductCategory.cows;
      
      default:
        return this;
    }
  }
  
  // Check if this is a main category
  bool get isMainCategory {
    return this == ProductCategory.crop ||
           this == ProductCategory.poultry ||
           this == ProductCategory.goats ||
           this == ProductCategory.cows;
  }
  
  // Get all subcategories for a main category
  static List<ProductCategory> getSubcategories(ProductCategory mainCategory) {
    switch (mainCategory) {
      case ProductCategory.crop:
        return [
          ProductCategory.onions,
          ProductCategory.watermelon,
          ProductCategory.tomatoes,
          ProductCategory.groundNuts,
          ProductCategory.soya,
          ProductCategory.passionFruits,
        ];
      case ProductCategory.poultry:
        return [
          ProductCategory.broilers,
          ProductCategory.sasso,
          ProductCategory.eggs,
          ProductCategory.localEggs,
          ProductCategory.localChicken,
          ProductCategory.incubationServices,
          ProductCategory.organicManure,
          ProductCategory.offLayers,
        ];
      case ProductCategory.goats:
        return [
          ProductCategory.maleGoats,
          ProductCategory.femaleGoats,
          ProductCategory.goatManure,
        ];
      case ProductCategory.cows:
        return [
          ProductCategory.milk,
          ProductCategory.bulls,
          ProductCategory.cowsFemale,
          ProductCategory.cowManure,
        ];
      default:
        return [];
    }
  }
  
  // Get all main categories
  static List<ProductCategory> get mainCategories => [
    ProductCategory.crop,
    ProductCategory.poultry,
    ProductCategory.goats,
    ProductCategory.cows,
  ];
}
