import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

/// Reusable Banner Ad Widget
/// 
/// Displays a banner ad at the bottom of the screen
/// Automatically handles loading and disposal
/// 
/// Usage:
/// ```dart
/// // At the bottom of your screen
/// Scaffold(
///   body: YourContent(),
///   bottomNavigationBar: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       BannerAdWidget(),
///       YourActualBottomNavBar(),
///     ],
///   ),
/// )
/// ```
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  final AdMobService _adMobService = AdMobService();

  @override
  void initState() {
    super.initState();
    // Load banner ad when widget is created
    _adMobService.loadBannerAd();
  }

  @override
  void dispose() {
    // Dispose ad when widget is destroyed
    _adMobService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show ad if it's loaded
    if (!_adMobService.isBannerAdLoaded || _adMobService.bannerAd == null) {
      return const SizedBox.shrink(); // Return empty widget if not loaded
    }

    return Container(
      width: double.infinity,
      height: AdMobService.bannerHeight,
      color: Colors.white,
      child: AdWidget(ad: _adMobService.bannerAd!),
    );
  }
}

/// Alternative: Banner Ad Widget with Custom Height
/// 
/// Allows you to specify different banner sizes
class CustomBannerAdWidget extends StatefulWidget {
  final AdSize adSize;
  final Color? backgroundColor;

  const CustomBannerAdWidget({
    super.key,
    this.adSize = AdSize.banner,
    this.backgroundColor,
  });

  @override
  State<CustomBannerAdWidget> createState() => _CustomBannerAdWidgetState();
}

class _CustomBannerAdWidgetState extends State<CustomBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdMobService().bannerAd?.adUnitId ?? '',
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
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
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: widget.adSize.height.toDouble(),
      color: widget.backgroundColor ?? Colors.white,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
