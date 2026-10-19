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
      loadInterstitial(); // pehle se load rakho taake result par foran dikhe
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

  // --- Interstitial (poori screen ka ad, quiz result ke baad) ---

  static const String _interstitialAdUnitId =
      'ca-app-pub-7871232394986284/7640700686';

  InterstitialAd? _interstitialAd;
  DateTime? _lastInterstitialShown;

  /// Interstitial preload karta hai.
  void loadInterstitial() {
    if (!_initialized) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd?.dispose();
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial failed to load: $err');
        },
      ),
    );
  }

  /// Result screen par call karo. Zyada se zyada 3 minute me 1 baar dikhega
  /// taake user tang na ho. Ad ready na ho to khamoshi se skip.
  void showInterstitialIfDue() {
    if (!_initialized) return;
    final now = DateTime.now();
    if (_lastInterstitialShown != null &&
        now.difference(_lastInterstitialShown!).inMinutes < 3) {
      return; // cooldown — user ko tang nahi karna
    }
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitial(); // agle waqt ke liye preload
      return;
    }
    _interstitialAd = null;
    _lastInterstitialShown = now;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        debugPrint('Interstitial failed to show: $err');
        ad.dispose();
        loadInterstitial();
      },
    );
    ad.show();
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
      adUnitId: 'ca-app-pub-7871232394986284/7153615523',
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
