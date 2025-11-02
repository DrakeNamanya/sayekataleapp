class Product {
  final String id;
  final String farmId;
  final String name;
  final String? description;
  final ProductCategory category;
  final String unit; // tray, kg, bird
  final int unitSize; // e.g., 30 eggs/tray
  final double price;
  final int stockQuantity;
  final int lowStockThreshold;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.farmId,
    required this.name,
    this.description,
    required this.category,
    required this.unit,
    required this.unitSize,
    required this.price,
    required this.stockQuantity,
    this.lowStockThreshold = 10,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;
  bool get isOutOfStock => stockQuantity == 0;

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
      farmId: data['farmer_id'] ?? data['farm_id'] ?? '', // Support both field names
      name: data['name'] ?? '',
      description: data['description'],
      category: ProductCategory.values.firstWhere(
        (e) => e.toString() == 'ProductCategory.${data['category']}',
        orElse: () => ProductCategory.crop,
      ),
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
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'farm_id': farmId,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'unit': unit,
      'unit_size': unitSize,
      'price': price,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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
