import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio_service.dart';
import 'purchase_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // ---- Ad unit IDs ----
  static String get _interstitialAdUnitId => Platform.isIOS
      ? 'ca-app-pub-5549243085914479/5959509503'
      : 'ca-app-pub-5549243085914479/8442989039';

  // Banner — unități create în AdMob 2026-05-20 pentru iOS app dedicat
  // (Tetris Smile iOS ~4127553081, publisher pub-5549243085914479).
  static String get _bannerAdUnitId => Platform.isIOS
      ? 'ca-app-pub-5549243085914479/2653551243'
      : 'ca-app-pub-5549243085914479/3127362412';

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;
  DateTime? _lastInterstitialAt;

  // Interstitial-urile prea dese încalcă politica AdMob și enervează userul;
  // păstrăm un minim între ele (separat de cadența din game_screen).
  static const Duration _minInterstitialGap = Duration(seconds: 50);

  /// True dacă userul a cumpărat „Fără reclame" — suprimă banner + interstitial.
  bool get adsDisabled => PurchaseService.instance.noAds;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    if (adsDisabled) return;
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (adsDisabled) return;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialReady = false;
        },
      ),
    );
  }

  /// Arată un interstitial. Future-ul se completează DUPĂ ce reclama s-a
  /// închis (sau imediat dacă reclama nu se afișează deloc — cooldown,
  /// remove-ads, nepregătită). Folosește `await` la callsite ca să nu lași
  /// jocul să tickeze peste ecranul de reclamă.
  Future<void> showInterstitial() async {
    if (adsDisabled) return;
    // Respectă un interval minim între interstitial-uri (anti-spam + politică).
    if (_lastInterstitialAt != null &&
        DateTime.now().difference(_lastInterstitialAt!) < _minInterstitialGap) {
      return;
    }
    if (!_interstitialReady || _interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    final completer = Completer<void>();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        AudioService().pause();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialReady = false;
        AudioService().resume();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialReady = false;
        AudioService().resume();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    _lastInterstitialAt = DateTime.now();
    await _interstitialAd!.show();
    await completer.future;
  }

  /// Creează un banner adaptiv ancorat (eCPM/fill mai bun decât 320x50 fix).
  /// Întoarce `null` dacă userul a cumpărat „Fără reclame".
  /// Apelantul trebuie să apeleze `.dispose()` pe banner în `dispose()`.
  Future<BannerAd?> createAnchoredBanner({
    required int widthDp,
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
  }) async {
    if (adsDisabled) return null;
    final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
          Orientation.portrait,
          widthDp,
        ) ??
        AdSize.banner;
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }
}
