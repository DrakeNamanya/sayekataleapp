# AdMob Integration Configuration

## Overview
This Flutter app is integrated with Google AdMob for banner advertisements on Android and web platforms (web shows placeholder, ads only work on Android).

## Configuration Details

### App ID
- **Test App ID (Current)**: `ca-app-pub-3940256099942544~3347511713`
- **Location**: `android/app/src/main/AndroidManifest.xml`

**⚠️ IMPORTANT**: Replace with your production App ID before releasing to production.

### Ad Units

#### Ad Unit 1: Banner Ad
- **Description**: Ad
- **Unit ID**: `ca-app-pub-3940256099942544/6300978111`
- **Ad Type**: Banner (320x50 standard size)
- **Platform**: Android only
- **Implementation**: `lib/widgets/admob_banner_widget.dart`
- **Placement**: 
  - SME Dashboard (bottom of content)
  - PSA Dashboard (bottom of content using SliverToBoxAdapter)

## Platform Support

### ✅ Android
- **Status**: Fully supported
- **Configuration**: AndroidManifest.xml with App ID meta-data
- **Ad Display**: Real banner ads with production ad units

### ✅ Web
- **Status**: Placeholder mode (AdMob not supported on web)
- **Behavior**: Shows empty space (SizedBox.shrink)
- **Implementation**: Graceful degradation using `kIsWeb` check

### ❌ iOS
- **Status**: Not configured (per requirements)
- **Behavior**: No ads shown on iOS devices

## Implementation Files

### 1. AndroidManifest.xml
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

### 2. main.dart
- Initializes Mobile Ads SDK on app startup
- Configures request settings (test devices, COPPA compliance)
- Logs initialization status for debugging

### 3. lib/widgets/admob_banner_widget.dart
- Reusable banner ad widget
- Lifecycle event handling
- Error logging and debugging
- Platform-aware implementation

### 4. pubspec.yaml
```yaml
dependencies:
  google_mobile_ads: 5.3.1
```

## Ad Lifecycle Events

The implementation tracks the following ad events:

1. **onAdLoaded** - Ad successfully loaded and ready to display
2. **onAdFailedToLoad** - Ad failed to load with error details
3. **onAdOpened** - User clicked on the ad
4. **onAdClosed** - User returned to app after clicking ad
5. **onAdImpression** - Ad impression recorded
6. **onAdClicked** - Ad click recorded

All events are logged to console in debug mode for monitoring.

## Error Handling

The widget handles errors gracefully:
- Failed ad loads show empty space (no error UI)
- Error details logged to console for debugging
- Ad disposal on errors to prevent memory leaks

## Best Practices Implemented

✅ **Initialization**: SDK initialized before showing ads
✅ **Lifecycle**: Proper dispose() to prevent memory leaks
✅ **Error Handling**: Graceful failure without breaking UI
✅ **Platform Checks**: Web compatibility with empty placeholders
✅ **Logging**: Comprehensive debug logging for troubleshooting
✅ **User Experience**: Non-intrusive placement at bottom of content
✅ **COPPA Compliance**: Configured for non-child-directed content

## Testing

### Debug Mode
- Extensive logging enabled
- Test device IDs configured
- All lifecycle events logged to console

### Production Mode
- Logging disabled for performance
- Production ad units active
- Real ad impressions and clicks tracked

## Production Checklist

Before releasing to production:

- [ ] Replace test App ID with production App ID in AndroidManifest.xml
- [ ] Verify ad unit IDs are correct
- [ ] Test ads on physical Android device
- [ ] Remove test device IDs from request configuration
- [ ] Verify COPPA compliance settings
- [ ] Test ad placement and user experience
- [ ] Monitor AdMob dashboard for ad performance

## Troubleshooting

### Ads not showing?
1. Check AndroidManifest.xml has correct App ID
2. Verify ad unit IDs match AdMob dashboard
3. Check debug logs for error messages
4. Ensure device has internet connection
5. Wait a few minutes for ad cache to populate

### Common Error Codes
- **Error 0**: Internal error
- **Error 1**: Invalid request
- **Error 2**: Network error
- **Error 3**: No ad inventory
- **Error 8**: App ID mismatch

## Support

For AdMob-specific issues, refer to:
- AdMob Support: https://support.google.com/admob
- Flutter AdMob Plugin: https://pub.dev/packages/google_mobile_ads
