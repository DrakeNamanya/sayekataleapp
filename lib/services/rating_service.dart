import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/farmer_rating.dart';
import '../models/review.dart';

/// Service for managing and querying farmer ratings
class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get rating for a single farmer
  Future<FarmerRating?> getFarmerRating(String farmerId) async {
    try {
      final doc = await _firestore
          .collection('farmer_ratings')
          .doc(farmerId)
          .get();

      if (doc.exists && doc.data() != null) {
        return FarmerRating.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get ratings for multiple farmers (batch query)
  /// Returns a map of farmerId -> FarmerRating
  Future<Map<String, FarmerRating>> getFarmerRatings(
    List<String> farmerIds,
  ) async {
    try {
      final Map<String, FarmerRating> ratingsMap = {};

      if (farmerIds.isEmpty) {
        return ratingsMap;
      }

      // Remove duplicates
      final uniqueFarmerIds = farmerIds.toSet().toList();

      // Firestore 'in' query has a limit of 10 items
      // Split into batches if more than 10 farmers
      for (int i = 0; i < uniqueFarmerIds.length; i += 10) {
        final batch = uniqueFarmerIds.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('farmer_ratings')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            ratingsMap[doc.id] = FarmerRating.fromFirestore(doc.data(), doc.id);
          }
        }
      }

      return ratingsMap;
    } catch (e) {
      return {};
    }
  }

  /// Get all highly rated farmers (>= 4.0 stars)
  Future<List<FarmerRating>> getHighlyRatedFarmers({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('farmer_ratings')
          .where('average_rating', isGreaterThanOrEqualTo: 4.0)
          .orderBy('average_rating', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FarmerRating.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get top rated farmers
  Future<List<FarmerRating>> getTopRatedFarmers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('farmer_ratings')
          .orderBy('average_rating', descending: true)
          .orderBy('total_ratings', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => FarmerRating.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream rating for a single farmer (real-time updates)
  Stream<FarmerRating?> streamFarmerRating(String farmerId) {
    return _firestore
        .collection('farmer_ratings')
        .doc(farmerId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return FarmerRating.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Submit a new review
  Future<void> submitReview(Review review) async {
    try {
      // Add review to reviews collection
      await _firestore
          .collection('reviews')
          .doc(review.id)
          .set(review.toFirestore());

      // Update farmer rating statistics
      await _updateFarmerRating(review.farmId, review.rating);
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  /// Update farmer rating statistics
  Future<void> _updateFarmerRating(String farmerId, double newRating) async {
    try {
      final ratingDoc = _firestore.collection('farmer_ratings').doc(farmerId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ratingDoc);
        
        if (snapshot.exists) {
          // Update existing rating
          final data = snapshot.data()!;
          final currentAverage = (data['average_rating'] ?? 0.0).toDouble();
          final totalRatings = (data['total_ratings'] ?? 0) as int;
          
          // Calculate new average
          final newTotalRatings = totalRatings + 1;
          final newAverage = ((currentAverage * totalRatings) + newRating) / newTotalRatings;
          
          // Update rating distribution
          final ratingDistribution = List<int>.from(data['rating_distribution'] ?? [0, 0, 0, 0, 0]);
          final ratingIndex = newRating.round() - 1;
          if (ratingIndex >= 0 && ratingIndex < 5) {
            ratingDistribution[ratingIndex]++;
          }
          
          transaction.update(ratingDoc, {
            'average_rating': newAverage,
            'total_ratings': newTotalRatings,
            'rating_distribution': ratingDistribution,
            'last_rated_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new rating document
          final ratingDistribution = [0, 0, 0, 0, 0];
          final ratingIndex = newRating.round() - 1;
          if (ratingIndex >= 0 && ratingIndex < 5) {
            ratingDistribution[ratingIndex] = 1;
          }
          
          transaction.set(ratingDoc, {
            'farmer_name': 'Farmer',
            'average_rating': newRating,
            'total_ratings': 1,
            'total_orders': 0,
            'total_deliveries': 0,
            'rating_distribution': ratingDistribution,
            'last_rated_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to update farmer rating: $e');
    }
  }
}
