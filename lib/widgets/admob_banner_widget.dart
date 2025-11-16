import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

/// Simple AdMob Banner Widget with Web compatibility
///
/// On Web: Shows placeholder message (AdMob not supported on Web)
/// On Android/iOS: Shows actual AdMob banner with test Ad Unit IDs
class AdMobBannerWidget extends StatefulWidget {
  final Color? backgroundColor;

  const AdMobBannerWidget({super.key, this.backgroundColor});

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Production Ad Unit IDs
  // Ad Unit 1 (Banner Ad): Description - "Ad"
  String get _adUnitId {
    if (kIsWeb) {
      return ''; // Web not supported - AdMob only works on native mobile
    } else if (Platform.isAndroid) {
      // Production Banner Ad Unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS not configured per requirements (Android and web only)
      return '';
    } else {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Ad loaded successfully
        onAdLoaded: (ad) {
          if (kDebugMode) {
            debugPrint('✅ AdMob Banner loaded successfully');
            debugPrint('   Ad Unit ID: $_adUnitId');
            if (ad is BannerAd) {
              debugPrint('   Ad size: ${ad.size.width}x${ad.size.height}');
            }
          }
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },

        // Ad failed to load
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('❌ AdMob Banner failed to load');
            debugPrint('   Error code: ${error.code}');
            debugPrint('   Error message: ${error.message}');
            debugPrint('   Error domain: ${error.domain}');
          }
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },

        // Ad opened (user clicked)
        onAdOpened: (ad) {
          if (kDebugMode) {
            debugPrint('📱 AdMob Banner opened - User clicked ad');
          }
        },

        // Ad closed
        onAdClosed: (ad) {
          if (kDebugMode) {
            debugPrint('📱 AdMob Banner closed - User returned to app');
          }
        },

        // Ad impression logged
        onAdImpression: (ad) {
          if (kDebugMode) {
            debugPrint('👁️ AdMob Banner impression recorded');
          }
        },

        // Ad clicked
        onAdClicked: (ad) {
          if (kDebugMode) {
            debugPrint('🖱️ AdMob Banner clicked');
          }
        },
      ),
    );

    // Load the ad
    _bannerAd?.load();

    if (kDebugMode) {
      debugPrint('🔄 Loading AdMob Banner...');
      debugPrint('   Ad Unit ID: $_adUnitId');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On Web or if ad not loaded, show placeholder
    if (kIsWeb || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // Empty space on Web
    }

    // Show actual ad on mobile
    return Container(
      width: double.infinity,
      height: 60,
      color: widget.backgroundColor ?? Colors.white,
      child: Center(
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
