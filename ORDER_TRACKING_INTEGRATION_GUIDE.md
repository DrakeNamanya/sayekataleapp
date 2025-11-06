# Order Tracking Integration Guide

## 🎯 Objective
Integrate the GPS delivery tracking system with the existing order management system to provide seamless order-to-delivery workflow.

## 📋 Integration Tasks (1-2 hours)

### Task 1: Auto-Create Delivery Tracking on Order Confirmation

**File:** `lib/services/order_service.dart`

**Location:** Add to `confirmOrder()` method

```dart
import '../models/delivery_tracking.dart';
import 'delivery_tracking_service.dart';

class OrderService {
  final DeliveryTrackingService _trackingService = DeliveryTrackingService();
  
  Future<void> confirmOrder(String orderId) async {
    // ... existing confirmation logic
    
    final order = await getOrder(orderId);
    
    // Get seller (delivery person) info
    final sellerDoc = await _firestore.collection('users').doc(order.sellerId).get();
    final sellerData = sellerDoc.data()!;
    final sellerName = sellerData['name'] ?? 'Unknown';
    final sellerPhone = sellerData['phone'] ?? '';
    final sellerLocation = sellerData['location'];
    
    // Get buyer (recipient) info
    final buyerDoc = await _firestore.collection('users').doc(order.buyerId).get();
    final buyerData = buyerDoc.data()!;
    final buyerName = buyerData['name'] ?? 'Unknown';
    final buyerPhone = buyerData['phone'] ?? '';
    final buyerLocation = buyerData['location'];
    
    // Determine delivery type based on order type
    String deliveryType;
    if (order.orderType == 'SME_TO_SHG') {
      deliveryType = 'SHG_TO_SME';
    } else if (order.orderType == 'SHG_TO_PSA') {
      deliveryType = 'PSA_TO_SHG';
    } else {
      deliveryType = 'SHG_TO_SME'; // Default
    }
    
    // Calculate distance
    final originLat = sellerLocation['latitude']?.toDouble() ?? 0.0;
    final originLng = sellerLocation['longitude']?.toDouble() ?? 0.0;
    final destLat = buyerLocation['latitude']?.toDouble() ?? 0.0;
    final destLng = buyerLocation['longitude']?.toDouble() ?? 0.0;
    
    final originPoint = LocationPoint(
      latitude: originLat,
      longitude: originLng,
      address: sellerLocation['address'],
    );
    
    final destPoint = LocationPoint(
      latitude: destLat,
      longitude: destLng,
      address: buyerLocation['address'],
    );
    
    final distance = originPoint.distanceTo(destPoint);
    final duration = _trackingService.calculateEstimatedDuration(distance);
    
    // Create delivery tracking
    final tracking = DeliveryTracking(
      id: '', // Firestore will generate
      orderId: orderId,
      deliveryType: deliveryType,
      deliveryPersonId: order.sellerId,
      deliveryPersonName: sellerName,
      deliveryPersonPhone: sellerPhone,
      recipientId: order.buyerId,
      recipientName: buyerName,
      recipientPhone: buyerPhone,
      originLocation: originPoint,
      destinationLocation: destPoint,
      status: DeliveryStatus.pending,
      estimatedDistance: distance,
      estimatedDuration: duration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await _trackingService.createDeliveryTracking(tracking);
  }
}
```

---

### Task 2: Add "Track Delivery" Button in Order History

**File:** `lib/screens/sme/sme_order_history_screen.dart` (or similar)

**Add import:**
```dart
import '../../services/delivery_tracking_service.dart';
import '../../models/delivery_tracking.dart';
import '../delivery/live_tracking_screen.dart';
```

**Add method:**
```dart
Future<void> _trackDelivery(Order order) async {
  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Get delivery tracking
    final trackingService = DeliveryTrackingService();
    final tracking = await trackingService.getDeliveryTrackingByOrderId(order.id);
    
    // Close loading
    if (mounted) Navigator.pop(context);
    
    if (tracking == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery tracking not available yet'),
          ),
        );
      }
      return;
    }
    
    // Navigate to live tracking
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveTrackingScreen(trackingId: tracking.id),
        ),
      );
    }
  } catch (e) {
    // Close loading if open
    if (mounted) Navigator.pop(context);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading tracking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Add button in order card:**
```dart
// Inside order card widget
if (order.status == 'confirmed' || order.status == 'shipped' || order.status == 'in_transit')
  ElevatedButton.icon(
    onPressed: () => _trackDelivery(order),
    icon: const Icon(Icons.map, size: 18),
    label: const Text('Track Delivery'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  ),
```

---

### Task 3: Add Delivery Control Entry Point for Delivery Persons

**File:** `lib/screens/shg/shg_dashboard_screen.dart` (SHG Farmers)

**Add navigation card:**
```dart
_buildDashboardCard(
  icon: Icons.local_shipping,
  title: 'My Deliveries',
  subtitle: 'Track and manage your deliveries',
  color: Colors.green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeliveryControlScreen(),
      ),
    );
  },
),
```

**File:** `lib/screens/psa/psa_dashboard_screen.dart` (PSA Suppliers)

**Add similar navigation card** as above.

---

### Task 4: Synchronize Delivery Status with Order Status

**File:** `lib/services/order_service.dart`

**Add listener method:**
```dart
Stream<DeliveryTracking?> streamOrderDelivery(String orderId) {
  return _trackingService.streamDeliveryTracking(orderId);
}

Future<void> syncDeliveryStatusToOrder(String orderId, DeliveryStatus deliveryStatus) async {
  String orderStatus;
  
  switch (deliveryStatus) {
    case DeliveryStatus.pending:
      orderStatus = 'confirmed';
      break;
    case DeliveryStatus.confirmed:
      orderStatus = 'confirmed';
      break;
    case DeliveryStatus.inProgress:
      orderStatus = 'in_transit';
      break;
    case DeliveryStatus.completed:
      orderStatus = 'delivered';
      break;
    case DeliveryStatus.cancelled:
      orderStatus = 'cancelled';
      break;
    case DeliveryStatus.failed:
      orderStatus = 'failed';
      break;
  }
  
  await _firestore.collection('orders').doc(orderId).update({
    'status': orderStatus,
    'updated_at': FieldValue.serverTimestamp(),
  });
}
```

**Update DeliveryTrackingService:**
```dart
// In completeDelivery() method, add:
final tracking = await getDeliveryTracking(trackingId);
if (tracking != null) {
  // Sync with order service
  final orderService = OrderService();
  await orderService.syncDeliveryStatusToOrder(
    tracking.orderId,
    DeliveryStatus.completed,
  );
}
```

---

### Task 5: GPS Validation During Registration

**File:** `lib/screens/shg/shg_registration_screen.dart` (and similar for SME, PSA)

**Add GPS validation:**
```dart
bool _hasValidGPS = false;
double? _latitude;
double? _longitude;

Future<void> _validateGPS() async {
  if (_latitude == null || _longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ GPS location is required to use Agrilink'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
    return;
  }
  
  // Validate coordinates are in Uganda (approximate bounds)
  if (_latitude! < -1.5 || _latitude! > 4.5 ||
      _longitude! < 29.5 || _longitude! > 35.0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ GPS coordinates must be in Uganda'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  setState(() {
    _hasValidGPS = true;
  });
}

// In registration form:
GPSLocationPicker(
  initialLatitude: _latitude,
  initialLongitude: _longitude,
  onLocationSelected: (lat, lng) {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _hasValidGPS = true;
    });
  },
),

// Disable submit button if no GPS
ElevatedButton(
  onPressed: _hasValidGPS ? _submitRegistration : null,
  child: Text(
    _hasValidGPS ? 'Complete Registration' : 'Add GPS Location Required',
  ),
)
```

---

### Task 6: Add Delivery Status to Order Model (Optional Enhancement)

**File:** `lib/models/order.dart`

**Add field:**
```dart
final String? deliveryTrackingId;  // Link to delivery_tracking document

Order({
  // ... existing fields
  this.deliveryTrackingId,
});

// Update fromFirestore and toFirestore methods
```

---

## 🧪 Testing Checklist

After implementing the above integration:

### Functional Tests:
- [ ] Create order → Delivery tracking auto-created
- [ ] Confirm order → Delivery status = "pending"
- [ ] Start delivery → Order status = "in_transit"
- [ ] Complete delivery → Order status = "delivered"
- [ ] Cancel delivery → Order status = "cancelled"
- [ ] "Track Delivery" button appears for active orders
- [ ] "Track Delivery" opens live tracking screen
- [ ] Delivery control screen accessible from SHG/PSA dashboards
- [ ] GPS validation prevents registration without coordinates

### Edge Cases:
- [ ] Order without GPS coordinates (handle gracefully)
- [ ] Delivery tracking not found (show appropriate message)
- [ ] Multiple deliveries for same order (prevent duplicates)
- [ ] Order cancelled before delivery starts (update tracking)

---

## 📊 Expected Firestore Structure After Integration

### `orders` collection:
```javascript
{
  "id": "order_12345",
  "status": "in_transit",  // Synced with delivery status
  "delivery_tracking_id": "tracking_67890",  // Optional link
  // ... other order fields
}
```

### `delivery_tracking` collection:
```javascript
{
  "id": "tracking_67890",
  "order_id": "order_12345",  // Required link
  "status": "inProgress",
  // ... other tracking fields
}
```

---

## 🚀 Deployment Steps

1. **Implement Tasks 1-6** (estimated 1-2 hours)
2. **Run `flutter analyze`** (fix any issues)
3. **Test locally** on Android device or emulator
4. **Build APK:** `flutter build apk --release`
5. **Test APK** on physical device
6. **Deploy to production** (Google Play or beta testing)

---

## 🎯 Success Metrics

After integration, users should experience:

1. **Seamless Order-to-Delivery Flow:**
   - Order confirmation → Delivery tracking auto-created
   - No manual tracking creation needed

2. **Real-time Status Updates:**
   - Order status syncs with delivery status
   - Users always see accurate information

3. **Easy Access to Tracking:**
   - "Track Delivery" button in order history
   - One-tap access to live map

4. **Delivery Person Workflow:**
   - Dashboard access to delivery control
   - Start/complete deliveries with GPS tracking

5. **GPS Requirement Enforcement:**
   - All users must have GPS coordinates
   - Registration blocked without valid GPS

---

## 📝 Integration Completion Checklist

- [ ] Task 1: Auto-create delivery tracking on order confirmation
- [ ] Task 2: Add "Track Delivery" button in order history
- [ ] Task 3: Add delivery control entry points in dashboards
- [ ] Task 4: Synchronize delivery status with order status
- [ ] Task 5: GPS validation during registration
- [ ] Task 6: (Optional) Add deliveryTrackingId to Order model
- [ ] Testing: All functional tests pass
- [ ] Testing: Edge cases handled
- [ ] Code Review: Flutter analyze passes
- [ ] Documentation: Update README with tracking features
- [ ] Deployment: Build and test APK

---

**Estimated Time:** 1-2 hours  
**Difficulty:** Medium  
**Priority:** High (completes Phase 3)  
**Impact:** Enables full GPS tracking feature for users

**Next Step After Integration:** User onboarding and production deployment!
