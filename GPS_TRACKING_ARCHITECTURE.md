# GPS Tracking Architecture - Visual Data Flow

## 🗺️ System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AGRILINK GPS TRACKING SYSTEM                    │
│                              (Phase 3 - 90% Complete)                   │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   SHG FARMER    │     │   SME BUYER     │     │  PSA SUPPLIER   │
│  (Delivery      │     │  (Recipient)    │     │  (Delivery      │
│   Person)       │     │                 │     │   Person)       │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                        │
         │ Start Delivery        │ Track Delivery         │ Start Delivery
         │                       │                        │
         ▼                       ▼                        ▼
┌────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION LAYER                       │
│                                                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ Delivery Control│  │ Live Tracking   │  │ GPS Location    │  │
│  │    Screen       │  │    Screen       │  │   Picker        │  │
│  │                 │  │                 │  │                 │  │
│  │ • Start         │  │ • Real-time Map │  │ • Google Maps   │  │
│  │ • Complete      │  │ • Progress Bar  │  │ • Use Current   │  │
│  │ • Cancel        │  │ • ETA Display   │  │ • Tap to Select │  │
│  │ • View Map      │  │ • Contact Btns  │  │ • Draggable     │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                     │           │
└───────────┼────────────────────┼─────────────────────┼───────────┘
            │                    │                     │
            │                    │                     │
            ▼                    ▼                     ▼
┌────────────────────────────────────────────────────────────────────┐
│                    SERVICE LAYER                                   │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │         DeliveryTrackingService                          │    │
│  │                                                          │    │
│  │  • createDeliveryTracking()                             │    │
│  │  • startDelivery()                                      │    │
│  │  • updateDeliveryLocation()  ◄─── Timer.periodic(30s)  │    │
│  │  • completeDelivery()                                   │    │
│  │  • cancelDelivery()                                     │    │
│  │  • streamDeliveryTracking()  ──► Real-time Stream       │    │
│  │  • startLocationTracking()                              │    │
│  │  • stopLocationTracking()                               │    │
│  │                                                          │    │
│  │  Dependencies:                                           │    │
│  │  • Geolocator (GPS positioning)                         │    │
│  │  • Cloud Firestore (data storage)                       │    │
│  │  • Timer.periodic (location updates)                    │    │
│  └────────────────────┬──────────────────┬─────────────────┘    │
│                       │                  │                       │
└───────────────────────┼──────────────────┼───────────────────────┘
                        │                  │
                        ▼                  ▼
┌────────────────────────────────┐  ┌──────────────────────────┐
│      GEOLOCATOR PLUGIN         │  │   FIREBASE FIRESTORE     │
│                                │  │                          │
│ • getCurrentPosition()         │  │ Collection:              │
│ • LocationAccuracy.high        │  │ delivery_tracking        │
│ • checkPermission()            │  │                          │
│ • requestPermission()          │  │ • Real-time snapshots()  │
│ • isLocationServiceEnabled()   │  │ • FieldValue.arrayUnion()│
│ • Android: FINE_LOCATION       │  │ • SERVER_TIMESTAMP       │
│ • iOS: whenInUse/always        │  │ • Offline caching        │
└────────────────────────────────┘  └──────────────────────────┘
```

---

## 📊 Data Flow: SHG → SME Delivery

### Flow 1: Order Confirmation → Tracking Creation

```
┌──────────────┐
│  SME Buyer   │
│ Places Order │
└──────┬───────┘
       │
       ▼
┌────────────────────────┐
│  SHG Farmer Confirms   │ ─────────────┐
│        Order           │               │
└────────────────────────┘               │
                                         │ 🚧 TO BE IMPLEMENTED
                                         │
                     ┌───────────────────▼────────────────────┐
                     │  OrderService.confirmOrder()           │
                     │                                        │
                     │  1. Update order status                │
                     │  2. Get seller (SHG) GPS location     │
                     │  3. Get buyer (SME) GPS location      │
                     │  4. Calculate distance (Haversine)    │
                     │  5. Calculate ETA (distance/30 km/h)  │
                     │  6. Create DeliveryTracking record    │
                     └────────────────────────────────────────┘
                                         │
                                         ▼
                     ┌────────────────────────────────────────┐
                     │     Firestore: delivery_tracking       │
                     │                                        │
                     │  {                                     │
                     │    order_id: "order_12345"             │
                     │    delivery_type: "SHG_TO_SME"         │
                     │    status: "pending"                   │
                     │    origin_location: {lat, lng}         │
                     │    destination_location: {lat, lng}    │
                     │    estimated_distance: 2.5 km          │
                     │    estimated_duration: 5 min           │
                     │  }                                     │
                     └────────────────────────────────────────┘
```

### Flow 2: Starting Delivery → GPS Tracking

```
┌─────────────────┐
│  SHG Farmer     │
│ Opens Delivery  │
│ Control Screen  │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ Taps "Start Delivery"    │
│ Confirms GPS Permission  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  DeliveryTrackingService.startDelivery()                 │
│                                                          │
│  1. Check location permission ─► Request if needed      │
│  2. Get current GPS position (high accuracy)            │
│  3. Update Firestore:                                   │
│     • status = "inProgress"                             │
│     • started_at = SERVER_TIMESTAMP                     │
│     • current_location = {lat, lng, timestamp}          │
│     • location_history[0] = {lat, lng, timestamp}       │
│  4. Start Timer.periodic(30 seconds):                   │
│     • Get GPS position every 30s                        │
│     • Update current_location in Firestore              │
│     • Append to location_history array                  │
└──────────────────────────────────────────────────────────┘
         │
         │ Every 30 seconds
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  Continuous GPS Updates (Timer Loop)                     │
│                                                          │
│  while (status == "inProgress") {                        │
│    wait 30 seconds;                                      │
│    position = await Geolocator.getCurrentPosition();    │
│    await updateDeliveryLocation(trackingId, lat, lng);  │
│  }                                                       │
└──────────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  Firestore: Real-time Updates                            │
│                                                          │
│  {                                                       │
│    status: "inProgress"                                  │
│    started_at: "2025-01-15T08:00:00Z"                   │
│    current_location: {                                   │
│      latitude: 0.3488,                                   │
│      longitude: 32.5837,                                 │
│      timestamp: "2025-01-15T08:15:00Z"                  │
│    }                                                     │
│    location_history: [                                   │
│      {lat: 0.3476, lng: 32.5825, time: "08:00:00"},    │
│      {lat: 0.3482, lng: 32.5831, time: "08:05:00"},    │
│      {lat: 0.3488, lng: 32.5837, time: "08:15:00"}     │
│    ]                                                     │
│  }                                                       │
└──────────────────────────────────────────────────────────┘
```

### Flow 3: Recipient Tracking → Real-time Map

```
┌──────────────────┐
│   SME Buyer      │
│ Opens Order      │
│ History Screen   │
└────────┬─────────┘
         │
         ▼
┌─────────────────────────────┐
│ Taps "Track Delivery" 🚧    │  ◄── TO BE IMPLEMENTED
└────────┬────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  DeliveryTrackingService.streamDeliveryTracking()        │
│                                                          │
│  Firestore.collection('delivery_tracking')              │
│    .doc(trackingId)                                      │
│    .snapshots()  ──► Real-time Stream (~1 update/sec)   │
└────────┬─────────────────────────────────────────────────┘
         │
         │ Stream updates
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  LiveTrackingScreen (Real-time UI Updates)               │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │          Google Maps Widget                    │    │
│  │                                                │    │
│  │  • Origin Marker (Green) ──► Starting point    │    │
│  │  • Destination Marker (Red) ──► End point      │    │
│  │  • Current Marker (Blue) ──► Delivery person   │    │
│  │  • Polyline Route ──► Dotted blue line         │    │
│  │                                                │    │
│  │  Auto-updates every time Firestore changes    │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │          Progress Card                         │    │
│  │                                                │    │
│  │  Progress: 60% ████████████░░░░░░░░░           │    │
│  │  Distance: 2.5 km | Duration: 5 min            │    │
│  │  ETA: 08:25 AM                                 │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │      Delivery Person Contact Card              │    │
│  │                                                │    │
│  │  John Farmer • +256700000001                   │    │
│  │  [📞 Call]  [💬 Message]                       │    │
│  └────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────┘
```

### Flow 4: Completing Delivery → Status Sync

```
┌─────────────────┐
│  SHG Farmer     │
│ Arrives at SME  │
│   Location      │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ Taps "Complete Delivery" │
│ Confirms Completion      │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  DeliveryTrackingService.completeDelivery()              │
│                                                          │
│  1. Update Firestore:                                   │
│     • status = "completed"                              │
│     • completed_at = SERVER_TIMESTAMP                   │
│  2. Stop location tracking (Timer.cancel())             │
│  3. Cleanup resources                                   │
└────────┬─────────────────────────────────────────────────┘
         │
         │ 🚧 TO BE IMPLEMENTED
         │
         ▼
┌──────────────────────────────────────────────────────────┐
│  OrderService.syncDeliveryStatusToOrder()                │
│                                                          │
│  1. Update order status = "delivered"                   │
│  2. Update order updated_at timestamp                   │
│  3. Trigger notification to buyer                       │
└──────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Synchronization Model

### Real-time Streaming Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT SIDE (Flutter App)                    │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │  StreamBuilder<DeliveryTracking?>                     │    │
│  │                                                       │    │
│  │  stream: trackingService.streamDeliveryTracking(id)  │    │
│  │                                                       │    │
│  │  builder: (context, snapshot) {                      │    │
│  │    if (snapshot.hasData) {                           │    │
│  │      updateMap(snapshot.data);  ◄─── Auto-updates   │    │
│  │      updateProgress(snapshot.data);                  │    │
│  │    }                                                  │    │
│  │  }                                                    │    │
│  └───────────────────────┬───────────────────────────────┘    │
└────────────────────────────┼───────────────────────────────────┘
                             │
                             │ Firestore Real-time Listener
                             │ (~1 update per second)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVER SIDE (Firebase)                       │
│                                                                 │
│  ┌───────────────────────────────────────────────────────┐    │
│  │  Cloud Firestore Collection: delivery_tracking        │    │
│  │                                                       │    │
│  │  DocumentSnapshot.snapshots()                        │    │
│  │                                                       │    │
│  │  • Listens for document changes                      │    │
│  │  • Sends updates to all connected clients            │    │
│  │  • Offline caching support                           │    │
│  │  • Automatic reconnection                            │    │
│  └───────────────────────────────────────────────────────┘    │
│                                                                 │
│  Update Sources:                                                │
│  • Delivery person GPS updates (every 30s)                     │
│  • Status changes (start, complete, cancel)                    │
│  • Manual updates via control screen                           │
└─────────────────────────────────────────────────────────────────┘
```

### Location Update Batching

```
Timer.periodic(Duration(seconds: 30)):

┌──────────────────────────────────────────────────────────────┐
│  T = 0s:  Start delivery                                     │
│           • current_location = {lat: 0.3476, lng: 32.5825}  │
│           • location_history[0] = {lat: 0.3476, lng: 32.5825}│
└──────────────────────────────────────────────────────────────┘
         │
         │ Wait 30 seconds
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  T = 30s: First update                                       │
│           • current_location = {lat: 0.3482, lng: 32.5831}  │
│           • location_history[1] = {lat: 0.3482, lng: 32.5831}│
│           • Progress: 20%                                    │
└──────────────────────────────────────────────────────────────┘
         │
         │ Wait 30 seconds
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  T = 60s: Second update                                      │
│           • current_location = {lat: 0.3488, lng: 32.5837}  │
│           • location_history[2] = {lat: 0.3488, lng: 32.5837}│
│           • Progress: 40%                                    │
└──────────────────────────────────────────────────────────────┘
         │
         │ Continue until delivery complete...
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  Delivery Complete:                                          │
│           • Timer.cancel()                                   │
│           • Final location saved                             │
│           • GPS tracking stopped                             │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 Progress Calculation Algorithm

### Haversine Distance Formula

```dart
/// Calculate distance between two GPS points
double distanceTo(LocationPoint other) {
  const double earthRadius = 6371.0; // kilometers
  
  // Convert degrees to radians
  final lat1Rad = latitude * (pi / 180.0);
  final lat2Rad = other.latitude * (pi / 180.0);
  final deltaLatRad = (other.latitude - latitude) * (pi / 180.0);
  final deltaLonRad = (other.longitude - longitude) * (pi / 180.0);
  
  // Haversine formula
  final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
      sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c; // Returns kilometers
}
```

### Progress Percentage

```dart
double get progressPercentage {
  // Total route distance
  final totalDistance = originLocation.distanceTo(destinationLocation);
  
  // Remaining distance
  final remainingDistance = currentLocation!.distanceTo(destinationLocation);
  
  // Traveled distance
  final traveledDistance = totalDistance - remainingDistance;
  
  // Progress as percentage (0-100)
  return (traveledDistance / totalDistance * 100).clamp(0.0, 100.0);
}
```

### ETA Calculation

```dart
DateTime? get estimatedArrival {
  if (startedAt == null || estimatedDuration == null) return null;
  
  // Add estimated duration to start time
  return startedAt!.add(Duration(minutes: estimatedDuration!));
}

int calculateEstimatedDuration(double distanceKm) {
  // Average speed: 30 km/h (Uganda road conditions)
  const averageSpeedKmh = 30.0;
  
  // Calculate time in hours, convert to minutes
  final hours = distanceKm / averageSpeedKmh;
  return (hours * 60).ceil();
}
```

---

## 🔒 Permission Flow

### Android Permission Handling

```
App Launch
    │
    ▼
Check Location Permission
    │
    ├─► Granted ──────────────► Continue
    │
    ├─► Denied ───────────────► Request Permission
    │                                   │
    │                                   ├─► Granted ──► Continue
    │                                   │
    │                                   └─► Denied ───► Show Error
    │
    └─► Denied Forever ───────► Show Settings Dialog
                                        │
                                        └─► Open App Settings
```

### Implementation

```dart
Future<bool> _checkLocationPermission() async {
  // 1. Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false; // Show "Enable location services" message
  }

  // 2. Check current permission status
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied) {
    // 3. Request permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return false; // Permission denied
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // 4. Permission permanently denied - show settings
    // Show dialog: "Please enable location in Settings"
    await Geolocator.openAppSettings();
    return false;
  }

  return true; // Permission granted
}
```

---

## 📈 Performance Metrics

### Battery Optimization

| Scenario | Battery Impact | Strategy |
|----------|----------------|----------|
| No Active Delivery | **0%** | GPS not used |
| Active Delivery (30s interval) | **Low (~5%/hour)** | Periodic updates |
| Continuous GPS (1s interval) | **High (~20%/hour)** | ❌ Avoided |

### Network Usage

| Operation | Data Usage | Frequency |
|-----------|------------|-----------|
| GPS Update | ~200 bytes | Every 30s |
| Real-time Stream | ~100 bytes/update | Continuous |
| Map Tiles | ~500KB | Initial load |
| Photo Upload | ~1-5MB | As needed |

### GPS Accuracy

| Setting | Accuracy | Battery | Use Case |
|---------|----------|---------|----------|
| **LocationAccuracy.high** | **5-10m** | **Medium** | **✅ Delivery tracking** |
| LocationAccuracy.medium | 10-100m | Low | Not suitable |
| LocationAccuracy.low | 100-1000m | Very Low | Not suitable |

---

## 🚀 Production Deployment Checklist

### Pre-Deployment:
- ✅ Models created (DeliveryTracking, LocationPoint)
- ✅ Service layer complete (DeliveryTrackingService)
- ✅ UI screens implemented (Live Map, Control)
- 🟡 Order integration (2 hours remaining)
- 🟡 GPS validation (30 minutes remaining)

### Firebase Configuration:
- ✅ Firestore collection: delivery_tracking
- 🟡 Composite indexes (required for queries)
- ⚪ Security rules (restrict write access)
- ⚪ Cloud Functions (for notifications)

### Testing:
- ✅ GPS tracking works locally
- ✅ Real-time streaming functional
- 🟡 End-to-end order flow (after integration)
- ⚪ Battery impact testing
- ⚪ Network failure scenarios

### Documentation:
- ✅ Architecture documented
- ✅ Integration guide created
- ✅ API reference (inline comments)
- ⚪ User manual
- ⚪ Support documentation

---

**Architecture Version:** 1.0  
**Last Updated:** January 2025  
**Status:** 90% Complete (Functional, pending order integration)
