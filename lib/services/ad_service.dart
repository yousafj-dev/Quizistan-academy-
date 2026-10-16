import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob wrapper — stub-safe: init fail ho to app crash nahi karti,
/// banner ki jagah sirf khali box milta hai.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// MobileAds initialize karta hai. Failure par sirf log hota hai.
  Future<void> init() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdMob init failed: $e');
      _initialized = false;
    }
  }

  /// Banner ad widget; init nahi hua to khali box.
  Widget bannerAd() {
    if (!_initialized) return const SizedBox.shrink();
    return const _BannerAdWidget();
  }
}

class _BannerAdWidget extends StatefulWidget {
  const _BannerAdWidget();

  @override
  State<_BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<_BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner failed: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return Container(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}
