import 'dart:math' as math;

/// Real-time delivery tracking model for SHG→SME and PSA→SHG deliveries
class DeliveryTracking {
  final String id; // Tracking ID
  final String orderId; // Associated order ID
  final String deliveryType; // 'SHG_TO_SME' or 'PSA_TO_SHG'
  final String deliveryPersonId; // SHG farmer ID or PSA supplier ID
  final String deliveryPersonName; // Name of person delivering
  final String deliveryPersonPhone; // Contact number
  final String recipientId; // SME buyer ID or SHG farmer ID
  final String recipientName; // Recipient name
  final String recipientPhone; // Recipient contact

  // GPS Coordinates
  final LocationPoint originLocation; // Starting point (farm/warehouse)
  final LocationPoint destinationLocation; // End point (SME/SHG location)
  final LocationPoint?
  currentLocation; // Real-time location (nullable during pending)

  // Tracking Status
  final DeliveryStatus status;
  final DateTime? startedAt; // When delivery started
  final DateTime? completedAt; // When delivery completed
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional Info
  final double? estimatedDistance; // in kilometers
  final int? estimatedDuration; // in minutes
  final String? notes; // Special instructions
  final List<LocationHistory> locationHistory; // GPS breadcrumb trail

  DeliveryTracking({
    required this.id,
    required this.orderId,
    required this.deliveryType,
    required this.deliveryPersonId,
    required this.deliveryPersonName,
    required this.deliveryPersonPhone,
    required this.recipientId,
    required this.recipientName,
    required this.recipientPhone,
    required this.originLocation,
    required this.destinationLocation,
    this.currentLocation,
    this.status = DeliveryStatus.pending,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedDistance,
    this.estimatedDuration,
    this.notes,
    this.locationHistory = const [],
  });

  /// Check if delivery is in progress
  bool get isInProgress => status == DeliveryStatus.inProgress;

  /// Check if delivery is completed
  bool get isCompleted => status == DeliveryStatus.completed;

  /// Get progress percentage (0-100) - Shows remaining distance
  /// 100% = at origin, 0% = at destination
  double get progressPercentage {
    if (currentLocation == null || status != DeliveryStatus.inProgress) {
      return 100.0; // Start at 100% (full distance remaining)
    }

    final totalDistance = originLocation.distanceTo(destinationLocation);
    if (totalDistance == 0) return 0.0; // Already at destination

    final remainingDistance = currentLocation!.distanceTo(destinationLocation);

    // Return remaining distance as percentage (100% → 0%)
    return (remainingDistance / totalDistance * 100).clamp(0.0, 100.0);
  }

  /// Get traveled distance percentage (0-100) - Shows completed journey
  /// 0% = at origin, 100% = at destination
  double get traveledPercentage {
    if (currentLocation == null || status != DeliveryStatus.inProgress) {
      return 0.0;
    }

    final totalDistance = originLocation.distanceTo(destinationLocation);
    if (totalDistance == 0) return 100.0;

    final remainingDistance = currentLocation!.distanceTo(destinationLocation);
    final traveledDistance = totalDistance - remainingDistance;

    return (traveledDistance / totalDistance * 100).clamp(0.0, 100.0);
  }

  /// Get remaining distance in kilometers
  double? get remainingDistanceKm {
    if (currentLocation == null || status != DeliveryStatus.inProgress) {
      return estimatedDistance;
    }
    return currentLocation!.distanceTo(destinationLocation);
  }

  /// Get estimated time of arrival
  DateTime? get estimatedArrival {
    if (startedAt == null || estimatedDuration == null) return null;
    return startedAt!.add(Duration(minutes: estimatedDuration!));
  }

  factory DeliveryTracking.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return DeliveryTracking(
      id: id,
      orderId: data['order_id'] ?? '',
      deliveryType: data['delivery_type'] ?? '',
      deliveryPersonId: data['delivery_person_id'] ?? '',
      deliveryPersonName: data['delivery_person_name'] ?? '',
      deliveryPersonPhone: data['delivery_person_phone'] ?? '',
      recipientId: data['recipient_id'] ?? '',
      recipientName: data['recipient_name'] ?? '',
      recipientPhone: data['recipient_phone'] ?? '',
      originLocation: LocationPoint.fromMap(data['origin_location'] ?? {}),
      destinationLocation: LocationPoint.fromMap(
        data['destination_location'] ?? {},
      ),
      currentLocation: data['current_location'] != null
          ? LocationPoint.fromMap(data['current_location'])
          : null,
      status: DeliveryStatus.values.firstWhere(
        (e) => e.toString() == 'DeliveryStatus.${data['status']}',
        orElse: () => DeliveryStatus.pending,
      ),
      startedAt: parseDateTime(data['started_at']),
      completedAt: parseDateTime(data['completed_at']),
      createdAt: parseDateTime(data['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updated_at']) ?? DateTime.now(),
      estimatedDistance: data['estimated_distance']?.toDouble(),
      estimatedDuration: data['estimated_duration'],
      notes: data['notes'],
      locationHistory:
          (data['location_history'] as List<dynamic>?)
              ?.map((e) => LocationHistory.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'delivery_type': deliveryType,
      'delivery_person_id': deliveryPersonId,
      'delivery_person_name': deliveryPersonName,
      'delivery_person_phone': deliveryPersonPhone,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'origin_location': originLocation.toMap(),
      'destination_location': destinationLocation.toMap(),
      'current_location': currentLocation?.toMap(),
      'status': status.toString().split('.').last,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estimated_distance': estimatedDistance,
      'estimated_duration': estimatedDuration,
      'notes': notes,
      'location_history': locationHistory.map((e) => e.toMap()).toList(),
    };
  }
}

/// GPS location point
class LocationPoint {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime? timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    this.address,
    this.timestamp,
  });

  /// Calculate distance to another point (Haversine formula) in kilometers
  double distanceTo(LocationPoint other) {
    const double earthRadius = 6371.0;

    final lat1Rad = latitude * (3.141592653589793 / 180.0);
    final lat2Rad = other.latitude * (3.141592653589793 / 180.0);
    final deltaLatRad =
        (other.latitude - latitude) * (3.141592653589793 / 180.0);
    final deltaLonRad =
        (other.longitude - longitude) * (3.141592653589793 / 180.0);

    final a =
        (deltaLatRad / 2) * (deltaLatRad / 2) +
        lat1Rad.cos() * lat2Rad.cos() * (deltaLonRad / 2) * (deltaLonRad / 2);
    final c = 2 * a.sqrt().asin();

    return earthRadius * c;
  }

  factory LocationPoint.fromMap(Map<String, dynamic> data) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return null;
    }

    return LocationPoint(
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      address: data['address'],
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

/// Historical GPS location point (for breadcrumb trail)
class LocationHistory {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationHistory({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory LocationHistory.fromMap(Map<String, dynamic> data) {
    DateTime parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      if (value.runtimeType.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return LocationHistory(
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: parseDateTime(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Delivery status enum
enum DeliveryStatus {
  pending, // Order created, delivery not started
  confirmed, // Delivery confirmed by delivery person
  inProgress, // Delivery in progress with live GPS
  completed, // Delivery completed successfully
  cancelled, // Delivery cancelled
  failed, // Delivery failed
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get displayName {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.confirmed:
        return 'Confirmed';
      case DeliveryStatus.inProgress:
        return 'In Progress';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
      case DeliveryStatus.failed:
        return 'Failed';
    }
  }

  String get description {
    switch (this) {
      case DeliveryStatus.pending:
        return 'Waiting for delivery to start';
      case DeliveryStatus.confirmed:
        return 'Delivery person confirmed, preparing to start';
      case DeliveryStatus.inProgress:
        return 'Delivery is on the way';
      case DeliveryStatus.completed:
        return 'Delivery completed successfully';
      case DeliveryStatus.cancelled:
        return 'Delivery was cancelled';
      case DeliveryStatus.failed:
        return 'Delivery could not be completed';
    }
  }
}

extension on double {
  double cos() => math.cos(this);
  double sin() => math.sin(this);
  double sqrt() => math.sqrt(this);
  double asin() => math.asin(this);
}
