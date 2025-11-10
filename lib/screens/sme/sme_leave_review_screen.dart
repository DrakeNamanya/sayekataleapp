import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/order.dart';
import '../../utils/app_theme.dart';
import '../../widgets/photo_upload_widget.dart';
import '../../services/photo_storage_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/rating_service.dart';
import '../../models/review.dart';

/// Screen for SME buyers to leave reviews after order delivery
class SMELeaveReviewScreen extends StatefulWidget {
  final Order order;
  final String farmerName;
  
  const SMELeaveReviewScreen({
    super.key,
    required this.order,
    required this.farmerName,
  });

  @override
  State<SMELeaveReviewScreen> createState() => _SMELeaveReviewScreenState();
}

class _SMELeaveReviewScreenState extends State<SMELeaveReviewScreen> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  final PhotoStorageService _photoService = PhotoStorageService();
  final RatingService _ratingService = RatingService();
  
  // Review criteria with individual ratings
  double _productQualityRating = 5.0;
  double _communicationRating = 5.0;
  double _deliveryRating = 5.0;
  double _packagingRating = 5.0;
  
  // Photos
  List<XFile> _selectedPhotos = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment about your experience'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      final userName = authProvider.currentUser?.name ?? 'Anonymous';

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create review ID
      final reviewId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload photos if any
      List<String> photoUrls = [];
      if (_selectedPhotos.isNotEmpty) {
        // Show uploading progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading photos...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        photoUrls = await _photoService.uploadReviewPhotos(
          reviewId: reviewId,
          photos: _selectedPhotos,
        );
      }

      // Create review object
      final review = Review(
        id: reviewId,
        orderId: widget.order.id,
        userId: userId,
        userName: userName,
        farmId: widget.order.farmerId ?? widget.order.sellerId,
        rating: _rating,
        comment: _commentController.text.trim(),
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      // Submit review to Firestore
      await _ratingService.submitReview(review);
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review submitted successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thank you for rating ${widget.farmerName}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${photoUrls.length} photo(s) uploaded',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate overall rating from criteria
    _rating = (_productQualityRating + _communicationRating + _deliveryRating + _packagingRating) / 4;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Farmer Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.farmerName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order #${widget.order.id}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Overall Rating Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Text(
                    'Overall Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        size: 48,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStarRating(_rating, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Rating Criteria
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate Your Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCriteriaRating(
                    'Product Quality',
                    'Freshness, size, and condition',
                    Icons.inventory_2_outlined,
                    _productQualityRating,
                    (value) => setState(() => _productQualityRating = value),
                  ),
                  const SizedBox(height: 16),
                  _buildCriteriaRating(
                    'Communication',
                    'Responsiveness and clarity',
                    Icons.chat_bubble_outline,
                    _communicationRating,
                    (value) => setState(() => _communicationRating = value),
                  ),
                  const SizedBox(height: 16),
                  _buildCriteriaRating(
                    'Delivery',
                    'Timeliness and accuracy',
                    Icons.local_shipping_outlined,
                    _deliveryRating,
                    (value) => setState(() => _deliveryRating = value),
                  ),
                  const SizedBox(height: 16),
                  _buildCriteriaRating(
                    'Packaging',
                    'Protection and presentation',
                    Icons.inventory_outlined,
                    _packagingRating,
                    (value) => setState(() => _packagingRating = value),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Comment Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell others about your experience with ${widget.farmerName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share details about the products, service, and your overall experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Photo Upload Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PhotoUploadWidget(
                maxPhotos: 5,
                initialPhotos: _selectedPhotos,
                onPhotosSelected: (photos) {
                  setState(() {
                    _selectedPhotos = photos;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Submitting...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCriteriaRating(
    String title,
    String subtitle,
    IconData icon,
    double rating,
    ValueChanged<double> onChanged,
  ) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final starValue = index + 1.0;
                return GestureDetector(
                  onTap: () => onChanged(starValue),
                  child: Icon(
                    starValue <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStarRating(double rating, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return Icon(
          starValue <= rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }
  
  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent!';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Average';
    if (rating >= 2.0) return 'Below Average';
    return 'Poor';
  }
}
