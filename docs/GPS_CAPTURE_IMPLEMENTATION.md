# 📍 GPS CAPTURE IMPLEMENTATION GUIDE

## **FILE 1: lib/screens/psa/psa_edit_profile_screen.dart**

### **STEP 1: Add GPS Import** (Add to imports section, line ~10)
```dart
import 'package:geolocator/geolocator.dart';  // Add this line
```

### **STEP 2: Add GPS Capture State Variables** (Add after line 48)
```dart
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;  // ADD THIS LINE
```

### **STEP 3: Add GPS Capture Method** (Add after _loadCurrentBusinessData method, ~line 100)
```dart
  /// Capture current GPS location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable in settings.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
```

### **STEP 4: Replace GPS Display Section** (Replace lines ~723-754)

**OLD CODE**:
```dart
            // GPS Coordinates (if available)
            if (_latitude != null && _longitude != null)
              Card(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.gps_fixed, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Coordinates',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
```

**NEW CODE**:
```dart
            // ✅ GPS Coordinates with Capture Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (_latitude != null && _longitude != null)
                    ? Colors.green.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_latitude != null && _longitude != null)
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_latitude != null && _longitude != null)
                        ? Icons.location_on
                        : Icons.location_off,
                    color: (_latitude != null && _longitude != null)
                        ? Colors.green
                        : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Coordinates',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_latitude != null && _longitude != null)
                              ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}'
                              : 'Tap button to capture your location',
                          style: TextStyle(
                            fontSize: 13,
                            color: (_latitude != null && _longitude != null)
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: (_latitude != null && _longitude != null)
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _isLoadingLocation ? 'Getting...' : 'Capture GPS',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
```

---

## **FILE 2: lib/screens/shg/shg_edit_profile_screen.dart**

**Apply the same changes as above:**
1. Add `import 'package:geolocator/geolocator.dart';`
2. Add `bool _isLoadingLocation = false;` state variable
3. Add `_getCurrentLocation()` method
4. Replace GPS display section with new interactive UI

---

## **TESTING STEPS**

### **Test 1: GPS Permissions**
1. Open PSA/SHG edit profile screen
2. Tap "Capture GPS" button
3. Allow location permission when prompted
4. Verify GPS coordinates are displayed

### **Test 2: GPS Capture**
1. Enable device GPS/Location
2. Tap "Capture GPS" button
3. Wait for loading indicator
4. Verify actual coordinates (not 0.000000, 0.000000)
5. Check success message displays coordinates

### **Test 3: Save Profile with GPS**
1. Capture GPS coordinates
2. Save profile
3. Verify coordinates are saved to Firestore
4. Reload profile and check coordinates persist

### **Test 4: GPS Error Handling**
1. Disable device GPS
2. Tap "Capture GPS" button
3. Verify error message: "Location services are disabled"
4. Enable GPS and retry
5. Verify success

---

## **🔍 FIRESTORE DATA VERIFICATION**

After saving, check Firestore `users/{userId}` document:

```json
{
  "location": {
    "latitude": 0.31628,      // ✅ Actual coordinates
    "longitude": 32.58219,     // ✅ Actual coordinates
    "district": "IGANGA",
    "subcounty": "NAKIGO",
    "parish": "BUSOWOOBI",
    "village": "KIWERERE"
  },
  "gps_captured_at": "2025-01-30T10:23:45.000Z"  // Optional timestamp
}
```

---

## **📱 PRODUCTION NOTES**

1. **Location Accuracy**: Uses `LocationAccuracy.high` for best precision
2. **Permission Handling**: Automatically requests permissions if denied
3. **User Feedback**: Shows success/error messages with actual coordinates
4. **Offline Mode**: GPS capture requires active GPS signal
5. **Battery Impact**: GPS capture uses moderate battery, only when button pressed

---

## **✅ COMPLETION CHECKLIST**

- [ ] GPS import added to PSA edit profile screen
- [ ] GPS import added to SHG edit profile screen
- [ ] `_isLoadingLocation` state variable added
- [ ] `_getCurrentLocation()` method implemented
- [ ] GPS display section replaced with interactive UI
- [ ] Location permissions verified in AndroidManifest.xml
- [ ] Test GPS capture in emulator/real device
- [ ] Verify coordinates save to Firestore
- [ ] Test error handling (permissions denied, GPS disabled)
- [ ] Deploy updated APK to production

---

**Implementation Status**: ✅ Ready for Code Application
