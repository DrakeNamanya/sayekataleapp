import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/environment.dart';

/// AdMob Service for managing banner ads across the app
/// 
/// Usage:
/// ```dart
/// // Initialize in main()
/// await AdMobService.initialize();
/// 
/// // In your widget
/// final adService = AdMobService();
/// adService.loadBannerAd();
/// 
/// // Display ad
/// AdWidget(ad: adService.bannerAd!)
/// ```
class AdMobService {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  /// Get banner ad instance
  BannerAd? get bannerAd => _bannerAd;

  /// Check if banner ad is loaded
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  // ========================================
  // Initialization
  // ========================================

  /// Initialize Mobile Ads SDK
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('🎯 Initializing AdMob SDK...');
    }

    try {
      await MobileAds.instance.initialize();
      
      if (kDebugMode) {
        debugPrint('✅ AdMob SDK initialized successfully');
        debugPrint('   App ID: ${Environment.admobAppIdAndroid}');
        debugPrint('   Banner ID: ${Environment.admobBannerIdAndroid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AdMob initialization failed: $e');
      }
    }
  }

  // ========================================
  // Banner Ad Management
  // ========================================

  /// Load banner ad
  /// Call this before displaying the ad widget
  void loadBannerAd() {
    if (_isBannerAdLoaded) {
      if (kDebugMode) {
        debugPrint('⚠️ Banner ad already loaded');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('📱 Loading banner ad...');
    }

    _bannerAd = BannerAd(
      adUnitId: _getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          if (kDebugMode) {
            debugPrint('✅ Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          if (kDebugMode) {
            debugPrint('❌ Banner ad failed to load: $error');
          }
          ad.dispose();
        },
        onAdOpened: (ad) {
          if (kDebugMode) {
            debugPrint('📂 Banner ad opened');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            debugPrint('🚪 Banner ad closed');
          }
        },
        onAdImpression: (ad) {
          if (kDebugMode) {
            debugPrint('👁️ Banner ad impression recorded');
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  /// Dispose banner ad
  /// Call this when disposing your widget
  void dispose() {
    if (kDebugMode) {
      debugPrint('🗑️ Disposing banner ad');
    }
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // ========================================
  // Ad Unit IDs
  // ========================================

  /// Get banner ad unit ID based on platform
  String _getBannerAdUnitId() {
    if (Platform.isAndroid) {
      return Environment.admobBannerIdAndroid;
    } else if (Platform.isIOS) {
      // iOS not configured yet
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    } else {
      // Other platforms (web, etc.) - return test ID
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
  }

  // ========================================
  // Helper Methods
  // ========================================

  /// Get standard banner height
  static double get bannerHeight => 50.0;

  /// Check if ads are enabled
  static bool get isEnabled => true; // Can be controlled via environment

  /// Get adaptive banner size for current orientation
  /// Useful for responsive banner ads
  static Future<AdSize> getAdaptiveBannerSize() async {
    return AdSize.banner; // Standard banner for now
  }
}
