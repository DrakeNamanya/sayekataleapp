import 'product_with_farmer.dart';
import 'farmer_rating.dart';

/// Model combining ProductWithFarmer and FarmerRating for browse screen
class ProductWithRating {
  final ProductWithFarmer productWithFarmer;
  final FarmerRating? farmerRating;

  ProductWithRating({
    required this.productWithFarmer,
    this.farmerRating,
  });

  /// Quick access to commonly used properties
  String get productId => productWithFarmer.product.id;
  String get farmerId => productWithFarmer.product.farmId;
  String get farmerName => productWithFarmer.farmer.name;
  double? get averageRating => farmerRating?.averageRating;
  int? get totalRatings => farmerRating?.totalRatings;
  bool get hasRating => farmerRating != null && (farmerRating?.totalRatings ?? 0) > 0;
  bool get isHighlyRated => farmerRating?.isHighlyRated ?? false;
  bool get hasSufficientRatings => farmerRating?.hasSufficientRatings ?? false;
}
