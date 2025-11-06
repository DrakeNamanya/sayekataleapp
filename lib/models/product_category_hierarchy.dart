/// Hierarchical product category system
/// Main categories with their subcategories
class ProductCategoryHierarchy {
  static const Map<String, List<ProductSubcategory>> categoryMap = {
    'crop': [
      ProductSubcategory('tomatoes', 'Tomatoes'),
      ProductSubcategory('watermelon', 'Watermelon'),
      ProductSubcategory('onions', 'Onions'),
    ],
    'oilSeeds': [
      ProductSubcategory('groundNuts', 'Ground Nuts'),
      ProductSubcategory('soya', 'Soya'),
    ],
    'poultry': [
      ProductSubcategory('broilers', 'Broilers'),
      ProductSubcategory('sasso', 'Sasso'),
      ProductSubcategory('eggs', 'Eggs'),
      ProductSubcategory('localChicken', 'Local Chicken'),
      ProductSubcategory('localEggs', 'Local Eggs'),
      ProductSubcategory('henManure', 'Hen Manure'),
    ],
    'goats': [
      ProductSubcategory('liveGoat', 'Live Goat'),
      ProductSubcategory('maleGoat', 'Male Goat'),
    ],
    'cows': [
      ProductSubcategory('liveCow', 'Live Cow'),
      ProductSubcategory('cowManure', 'Cow Manure'),
      ProductSubcategory('milk', 'Milk'),
    ],
  };

  static List<MainCategory> get mainCategories => [
    MainCategory('crop', 'Crops', 'assets/icons/crop.png'),
    MainCategory('oilSeeds', 'Oil Seeds', 'assets/icons/oil_seeds.png'),
    MainCategory('poultry', 'Poultry', 'assets/icons/poultry.png'),
    MainCategory('goats', 'Goats', 'assets/icons/goats.png'),
    MainCategory('cows', 'Cows', 'assets/icons/cows.png'),
  ];

  static List<ProductSubcategory> getSubcategories(String mainCategory) {
    return categoryMap[mainCategory] ?? [];
  }

  static List<String> get unitOptions => [
    'KGs',
    'grams',
    'number',
    'tray',
    '100kg bag',
    'litre',
  ];
}

class MainCategory {
  final String id;
  final String name;
  final String? iconPath;

  const MainCategory(this.id, this.name, [this.iconPath]);
}

class ProductSubcategory {
  final String id;
  final String name;

  const ProductSubcategory(this.id, this.name);
  
  String get value => id;
  String get displayName => name;
}
