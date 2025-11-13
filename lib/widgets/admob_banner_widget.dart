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
  
  const AdMobBannerWidget({
    super.key,
    this.backgroundColor,
  });

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Test Ad Unit IDs for development
  String get _adUnitId {
    if (kIsWeb) {
      return ''; // Web not supported
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS test ID
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
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );

    _bannerAd?.load();
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
