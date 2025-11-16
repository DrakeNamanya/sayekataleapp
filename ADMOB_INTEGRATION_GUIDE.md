# AdMob Integration Guide - SayeKatale App

## ✅ Configuration Complete!

Your AdMob account is fully configured and integrated into the SayeKatale app.

---

## 📋 Your AdMob Credentials

### App ID (Android)
```
ca-app-pub-6557386913540479~2174503706
```
**Status**: ✅ Configured in `AndroidManifest.xml`

### Banner Ad Unit ID (Android)
```
ca-app-pub-6557386913540479/5529911893
```
**Status**: ✅ Configured in `Environment.dart`

---

## 🔧 What Was Configured

### 1. Android Manifest (✅ Updated)
- **File**: `android/app/src/main/AndroidManifest.xml`
- **Change**: Updated AdMob App ID from test ID to production ID

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-6557386913540479~2174503706"/>
```

### 2. Environment Configuration (✅ Updated)
- **File**: `lib/config/environment.dart`
- **Added**: AdMob App ID and Banner Ad Unit ID constants

```dart
static const String admobAppIdAndroid = 'ca-app-pub-6557386913540479~2174503706';
static const String admobBannerIdAndroid = 'ca-app-pub-6557386913540479/5529911893';
```

### 3. AdMob Service (✅ Created)
- **File**: `lib/services/admob_service.dart`
- **Purpose**: Manages banner ad loading, disposal, and lifecycle

### 4. Banner Ad Widget (✅ Created)
- **File**: `lib/widgets/banner_ad_widget.dart`
- **Purpose**: Reusable widget for displaying banner ads

### 5. Main App Initialization (✅ Already Done)
- **File**: `lib/main.dart`
- **Status**: AdMob SDK initialization already implemented

---

## 🎯 How to Display Banner Ads

### Method 1: Simple Banner at Bottom of Screen (Recommended)

Add banner ad below your content:

```dart
import 'package:poultry_link/widgets/banner_ad_widget.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Screen')),
      body: YourContent(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BannerAdWidget(), // ← Add this line
          // Your actual bottom navigation bar (if any)
        ],
      ),
    );
  }
}
```

### Method 2: Banner Within Content

Display banner ad inside your content:

```dart
import 'package:poultry_link/widgets/banner_ad_widget.dart';

Column(
  children: [
    YourContent(),
    SizedBox(height: 16),
    BannerAdWidget(), // ← Banner ad in content
    SizedBox(height: 16),
    MoreContent(),
  ],
)
```

### Method 3: Banner in ListView

Display banner between list items:

```dart
import 'package:poultry_link/widgets/banner_ad_widget.dart';

ListView.builder(
  itemCount: items.length + 1, // +1 for ad
  itemBuilder: (context, index) {
    if (index == 5) {
      // Show ad after 5th item
      return BannerAdWidget();
    }
    
    int itemIndex = index > 5 ? index - 1 : index;
    return ListTile(title: Text(items[itemIndex]));
  },
)
```

---

## 📱 Recommended Ad Placements

### High-Impact Screens (Place Ads Here)

1. **Home Screen** (`customer_home_screen.dart`)
   - Bottom of screen, above bottom navigation
   - High visibility, frequent visits

2. **Product Listings** (`products/product_list_screen.dart`)
   - Bottom of screen
   - Users browse here frequently

3. **Product Details** (`products/product_detail_screen.dart`)
   - Below product description
   - Users spend time reading details

4. **Order History** (`orders/order_history_screen.dart`)
   - Top or bottom of list
   - Frequent check-ins by users

5. **Wallet/Transactions** (`shg/shg_wallet_screen.dart`)
   - Bottom of screen
   - High engagement area

### Low-Impact Screens (Don't Place Ads)

❌ **Login/Registration Screens** - Focus on onboarding
❌ **Checkout/Payment Screens** - Don't interrupt transactions
❌ **Profile Settings** - Quick visit screens
❌ **Error Screens** - Bad user experience

---

## 🎨 Example: Adding Banner to Home Screen

Here's how to add a banner ad to your home screen:

```dart
// File: lib/screens/customer/customer_home_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/banner_ad_widget.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SayeKatale'),
      ),
      body: YourHomeContent(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad above bottom navigation
          const BannerAdWidget(),
          
          // Your actual bottom navigation bar
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Testing Your Ads

### 1. Test on Real Device
- Ads only work on physical Android devices
- Emulators may not show ads correctly

### 2. Wait for Ad Approval
- New ad units can take **24-48 hours** to start serving ads
- Initially, you may see blank spaces or limited ads

### 3. Check AdMob Dashboard
- Monitor impressions: https://admob.google.com/
- View earnings and performance metrics

### 4. Debug Logs
The app prints ad loading status in debug mode:
```
🎯 Initializing AdMob SDK...
✅ AdMob SDK initialized successfully
📱 Loading banner ad...
✅ Banner ad loaded successfully
```

---

## 💰 Revenue Optimization Tips

### 1. Strategic Placement
- Place ads where users spend most time
- Bottom of screen has highest visibility
- Avoid blocking important content

### 2. Frequency
- **Recommended**: 1 banner per screen
- **Maximum**: 2 banners if screen is long
- Don't overload with ads - hurts user experience

### 3. Timing
- Load ads early in app lifecycle
- Preload ads before showing screen
- Dispose ads when screen is closed (already handled)

### 4. User Experience
- Ensure ads don't cover interactive elements
- Leave space between ad and content
- Use consistent ad placement across app

---

## 📊 Expected Revenue

### Typical AdMob Earnings (Uganda)
- **CPM**: $0.20 - $2.00 per 1000 impressions
- **CTR**: 1-3% (clicks per impression)
- **CPC**: $0.05 - $0.50 per click

### Revenue Projection
With 1000 daily active users:
- ~5000 daily impressions
- ~150,000 monthly impressions
- **Estimated**: $30-300/month

*Note: Actual earnings vary based on user engagement, location, and ad quality*

---

## 🚨 Important AdMob Policies

### Do NOT:
❌ Click your own ads
❌ Ask users to click ads
❌ Place ads too close to clickable elements
❌ Use misleading ad labels
❌ Modify ad code

### Do:
✅ Follow AdMob policies: https://support.google.com/admob/answer/6128543
✅ Respect user privacy
✅ Provide value to users
✅ Monitor policy compliance in dashboard

---

## 🔍 Troubleshooting

### Issue: Ads not showing
**Solutions**:
1. Wait 24-48 hours for ad units to activate
2. Test on real Android device (not emulator)
3. Check AdMob dashboard for account status
4. Verify app is published or in testing

### Issue: Blank space where ad should be
**Solutions**:
1. Check debug logs for errors
2. Verify internet connection
3. Ensure AdMob account is active
4. Wait for ad inventory to fill

### Issue: "Ad failed to load" error
**Solutions**:
1. Check Ad Unit ID is correct
2. Verify App ID in AndroidManifest.xml
3. Ensure device has Google Play Services
4. Check if AdMob account has any restrictions

---

## 📝 Files Modified/Created

### Modified Files
1. ✅ `android/app/src/main/AndroidManifest.xml` - Updated App ID
2. ✅ `lib/config/environment.dart` - Added AdMob constants

### New Files
1. ✅ `lib/services/admob_service.dart` - AdMob service
2. ✅ `lib/widgets/banner_ad_widget.dart` - Banner widget
3. ✅ `ADMOB_INTEGRATION_GUIDE.md` - This guide

---

## ✅ Next Steps

1. **Test Banner Ads** (After APK Build)
   - Build production APK with webhook URLs
   - Install on Android device
   - Navigate to screens with banner ads
   - Verify ads are loading

2. **Add Banner Ads to Screens**
   - Identify high-traffic screens
   - Add `BannerAdWidget()` to bottom
   - Test user experience

3. **Monitor Performance**
   - Check AdMob dashboard daily
   - Track impressions and clicks
   - Optimize ad placement based on data

4. **Comply with Policies**
   - Review AdMob policies regularly
   - Ensure app content is appropriate
   - Add privacy policy to Play Store listing

---

## 🎯 Summary

**AdMob Status**: ✅ **FULLY CONFIGURED**

**What You Have**:
- ✅ AdMob App ID configured
- ✅ Banner Ad Unit ID configured
- ✅ AdMob SDK initialized
- ✅ Reusable banner widget created
- ✅ Environment configuration updated

**What You Need to Do**:
1. Add `BannerAdWidget()` to your screens
2. Build production APK
3. Test on Android device
4. Monitor AdMob dashboard

**Ready for Phase 3**: Build Production APK with all configurations! 🚀

---

## 📞 Support Resources

- **AdMob Help**: https://support.google.com/admob/
- **Flutter Ads Plugin**: https://pub.dev/packages/google_mobile_ads
- **Policy Center**: https://support.google.com/admob/topic/7384409

---

**Documentation Complete**: Phase 2 ✅
**Next Phase**: Build Production Android APK
