import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../models/delivery_tracking.dart';
import 'package:flutter/foundation.dart';

/// Service for managing real-time delivery tracking
class DeliveryTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionSubscription;

  /// Create a new delivery tracking
  Future<String> createDeliveryTracking(DeliveryTracking tracking) async {
    try {
      final docRef = await _firestore
          .collection('delivery_tracking')
          .add(tracking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create delivery tracking: $e');
    }
  }

  /// Start delivery (delivery person initiates)
  Future<void> startDelivery(String trackingId) async {
    try {
      // Get tracking to access order ID
      final tracking = await getDeliveryTracking(trackingId);
      
      // Get current location
      final position = await _getCurrentPosition();
      
      await _firestore.collection('delivery_tracking').doc(trackingId).update({
        'status': DeliveryStatus.inProgress.toString().split('.').last,
        'started_at': FieldValue.serverTimestamp(),
        'current_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'location_history': FieldValue.arrayUnion([
          {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Update order status to shipped (in transit)
      if (tracking != null) {
        try {
          await _firestore.collection('orders').doc(tracking.orderId).update({
            'status': 'shipped',
            'shipped_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to sync order status: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to start delivery: $e');
    }
  }

  /// Update delivery location (called periodically during delivery)
  Future<void> updateDeliveryLocation(
    String trackingId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _firestore.collection('delivery_tracking').doc(trackingId).update({
        'current_location': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'location_history': FieldValue.arrayUnion([
          {
            'latitude': latitude,
            'longitude': longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }
        ]),
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating delivery location: $e');
      }
      // Don't throw - location updates should fail silently
    }
  }

  /// Complete delivery
  Future<void> completeDelivery(String trackingId) async {
    try {
      // Get tracking to access order ID
      final tracking = await getDeliveryTracking(trackingId);
      
      await _firestore.collection('delivery_tracking').doc(trackingId).update({
        'status': DeliveryStatus.completed.toString().split('.').last,
        'completed_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Stop location tracking
      stopLocationTracking();
      
      // Update order status (avoiding circular dependency)
      if (tracking != null) {
        try {
          await _firestore.collection('orders').doc(tracking.orderId).update({
            'status': 'delivered',
            'delivered_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to sync order status: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to complete delivery: $e');
    }
  }

  /// Cancel delivery
  Future<void> cancelDelivery(String trackingId, String reason) async {
    try {
      // Get tracking to access order ID
      final tracking = await getDeliveryTracking(trackingId);
      
      await _firestore.collection('delivery_tracking').doc(trackingId).update({
        'status': DeliveryStatus.cancelled.toString().split('.').last,
        'notes': reason,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Stop location tracking
      stopLocationTracking();
      
      // Update order status to cancelled
      if (tracking != null) {
        try {
          await _firestore.collection('orders').doc(tracking.orderId).update({
            'status': 'cancelled',
            'updated_at': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Failed to sync order status: $e');
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to cancel delivery: $e');
    }
  }

  /// Get delivery tracking by ID
  Future<DeliveryTracking?> getDeliveryTracking(String trackingId) async {
    try {
      final doc = await _firestore
          .collection('delivery_tracking')
          .doc(trackingId)
          .get();

      if (doc.exists && doc.data() != null) {
        return DeliveryTracking.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get delivery tracking by order ID
  Future<DeliveryTracking?> getDeliveryTrackingByOrderId(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_tracking')
          .where('order_id', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return DeliveryTracking.fromFirestore(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream delivery tracking (real-time updates)
  Stream<DeliveryTracking?> streamDeliveryTracking(String trackingId) {
    return _firestore
        .collection('delivery_tracking')
        .doc(trackingId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return DeliveryTracking.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Get active deliveries for delivery person
  Future<List<DeliveryTracking>> getActiveDeliveriesForPerson(
    String deliveryPersonId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_tracking')
          .where('delivery_person_id', isEqualTo: deliveryPersonId)
          .where('status', whereIn: [
            DeliveryStatus.pending.toString().split('.').last,
            DeliveryStatus.confirmed.toString().split('.').last,
            DeliveryStatus.inProgress.toString().split('.').last,
          ])
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DeliveryTracking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get deliveries for recipient
  Future<List<DeliveryTracking>> getDeliveriesForRecipient(
    String recipientId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('delivery_tracking')
          .where('recipient_id', isEqualTo: recipientId)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => DeliveryTracking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Start continuous location tracking (for delivery person)
  Future<void> startLocationTracking(
    String trackingId, {
    Duration interval = const Duration(seconds: 30),
  }) async {
    // Check location permissions
    final hasPermission = await _checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    // Start periodic location updates
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(interval, (timer) async {
      try {
        final position = await _getCurrentPosition();
        await updateDeliveryLocation(
          trackingId,
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in location tracking: $e');
        }
      }
    });
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Check and request location permission
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  /// Calculate estimated duration based on distance (rough estimate)
  int calculateEstimatedDuration(double distanceKm) {
    // Assume average speed of 30 km/h in Uganda's road conditions
    const averageSpeedKmh = 30.0;
    final hours = distanceKm / averageSpeedKmh;
    return (hours * 60).ceil(); // Convert to minutes
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}
