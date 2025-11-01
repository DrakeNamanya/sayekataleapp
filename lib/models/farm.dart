import 'user.dart';

class Farm {
  final String id;
  final String name;
  final String ownerId;
  final Location location;
  final String? contactInfo;
  final double rating;
  final int reviewCount;
  final String? description;
  final String? image;
  final DateTime createdAt;

  Farm({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.location,
    this.contactInfo,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.description,
    this.image,
    required this.createdAt,
  });

  factory Farm.fromFirestore(Map<String, dynamic> data, String id) {
    return Farm(
      id: id,
      name: data['name'] ?? '',
      ownerId: data['owner_id'] ?? '',
      location: Location.fromMap(data['location']),
      contactInfo: data['contact_info'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      description: data['description'],
      image: data['image'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'owner_id': ownerId,
      'location': location.toMap(),
      'contact_info': contactInfo,
      'rating': rating,
      'review_count': reviewCount,
      'description': description,
      'image': image,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
