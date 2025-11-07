# 🗺️ Google Maps API Setup Guide for SAYE Katale

## Problem
Live tracking map shows blank screen because Google Maps API key is missing.

## Solution: Get Free Google Maps API Key

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click **Select a Project** → **New Project**
3. Project Name: `SAYE Katale` or any name
4. Click **Create**

### Step 2: Enable Required APIs
1. Go to [Google Maps Platform](https://console.cloud.google.com/google/maps-apis/overview)
2. Click **Enable APIs and Services**
3. Search and enable:
   - ✅ **Maps JavaScript API** (for web preview)
   - ✅ **Maps SDK for Android** (for APK)

### Step 3: Create API Key
1. Go to [Credentials](https://console.cloud.google.com/apis/credentials)
2. Click **Create Credentials** → **API Key**
3. Copy the generated API key (e.g., `AIzaSyC...`)

### Step 4: Restrict API Key (Recommended for Security)
1. Click on the API key you just created
2. Under **API restrictions**:
   - Select **Restrict key**
   - Check: Maps JavaScript API, Maps SDK for Android
3. Under **Application restrictions**:
   - For testing: Leave unrestricted
   - For production: Add your domain and app signature

### Step 5: Add to Flutter App
**Reply with your API key and I'll configure it automatically!**

Or manually add it to:

#### For Web (file: `web/index.html`)
```html
<!-- Replace YOUR_GOOGLE_MAPS_API_KEY with actual key -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
```

#### For Android (file: `android/app/src/main/AndroidManifest.xml`)
```xml
<application>
    ...
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
</application>
```

---

## Free Tier Limits
Google Maps offers **$200 free credit per month**, which covers:
- ~28,500 map loads per month
- ~40,000 directions API calls per month

**This is more than enough for your app's delivery tracking!**

---

## Quick Test After Setup
1. Rebuild Flutter app: `flutter build web --release`
2. Restart server
3. Create test order → Confirm → Track Delivery
4. **Expected:** Interactive map with 3 pins (origin, destination, current location)

---

## Troubleshooting
- **Map still blank?** Check browser console (F12) for API key errors
- **"This page can't load Google Maps correctly"** → API key invalid or APIs not enabled
- **"API key expired"** → Billing account may need to be activated (free tier)

---

**Ready to add your API key? Just reply with it!** 🚀
