import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio_service.dart';

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

  // Unități pentru formatele cu eCPM mare (rewarded video + app-open).
  // DOAR Android deocamdată. Rewarded video are cel mai mare eCPM.
  // ⚠️ Se completează cu unit ID-urile REALE create în consola AdMob —
  // până atunci rămân goale și formatul nu se încarcă (guard `isEmpty`).
  static const String _androidRewardedId =
      'ca-app-pub-5549243085914479/8687077751';
  static const String _androidAppOpenId =
      'ca-app-pub-5549243085914479/8468756769';
  // Interstitial cu recompensă (creat 2026-06-14) — apare automat la
  // tranziții, dar OBLIGATORIU cu ecran de intro (opt-out) înainte.
  static const String _androidRewardedInterstitialId =
      'ca-app-pub-5549243085914479/4146031661';
  // Unități iOS reale create 2026-06-15 (AdMob app Tetris Classic iOS ~1797689638).
  // Activează formatele cu eCPM mare și pe iPhone/iPad (înainte erau dezactivate).
  static const String _iosRewardedId =
      'ca-app-pub-5549243085914479/6452932126';
  static const String _iosAppOpenId =
      'ca-app-pub-5549243085914479/7978061933';
  static const String _iosRewardedInterstitialId =
      'ca-app-pub-5549243085914479/2513687115';
  static String? get _rewardedAdUnitId =>
      Platform.isIOS ? _iosRewardedId : _androidRewardedId;
  static String? get _appOpenAdUnitId =>
      Platform.isIOS ? _iosAppOpenId : _androidAppOpenId;
  static String? get _rewardedInterstitialAdUnitId =>
      Platform.isIOS ? _iosRewardedInterstitialId : _androidRewardedInterstitialId;

  bool _initialized = false;
  InterstitialAd? _interstitialAd;
  bool _interstitialReady = false;
  DateTime? _lastInterstitialAt;

  // Interstitial-urile prea dese încalcă politica AdMob și enervează userul;
  // păstrăm un minim între ele (separat de cadența din game_screen).
  static const Duration _minInterstitialGap = Duration(seconds: 50);

  // ---- Retry cu backoff (crește rata de potrivire) ----
  static const int _maxLoadRetries = 5;
  int _rewardedRetry = 0;
  int _appOpenRetry = 0;
  Timer? _rewardedRetryTimer;
  Timer? _appOpenRetryTimer;
  Duration _backoff(int attempt) =>
      Duration(seconds: math.min(60, math.pow(2, attempt + 1).toInt()));

  // ---- Evită suprapunerea reclamelor fullscreen ----
  bool _showingFullScreen = false;

  // Monetizare exclusiv prin reclame — nu există „fără reclame". Păstrăm
  // getter-ul ca să nu rescriem fiecare guard; reclamele rulează mereu.
  bool get adsDisabled => false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    loadRewardedAd();
    loadAppOpenAd();
    loadRewardedInterstitialAd();
  }

  // ====================================================================
  // INTERSTITIAL
  // ====================================================================
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
    if (adsDisabled || _showingFullScreen) return;
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
        _showingFullScreen = false;
        AudioService().resume();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _interstitialReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        _loadInterstitialAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    _showingFullScreen = true;
    _lastInterstitialAt = DateTime.now();
    await _interstitialAd!.show();
    await completer.future;
  }

  // ====================================================================
  // REWARDED VIDEO (nou) — opt-in, cel mai mare eCPU. Folosit pt revive gratis.
  // ====================================================================
  RewardedAd? _rewardedAd;
  bool _rewardedReady = false;

  void loadRewardedAd() {
    final id = _rewardedAdUnitId;
    if (id == null || id.isEmpty || adsDisabled) return;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedRetry = 0;
          _rewardedRetryTimer?.cancel();
          _rewardedAd = ad;
          _rewardedReady = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedReady = false;
          _rewardedRetryTimer?.cancel();
          if (adsDisabled || _rewardedRetry >= _maxLoadRetries) return;
          _rewardedRetryTimer = Timer(_backoff(_rewardedRetry++), loadRewardedAd);
        },
      ),
    );
  }

  bool get isRewardedReady => _rewardedReady && _rewardedAd != null;

  /// Afișează rewarded video. [onReward] se apelează dacă userul câștigă
  /// recompensa. Întoarce false dacă reclama nu e disponibilă.
  bool showRewarded({required VoidCallback onReward}) {
    if (!isRewardedReady || _showingFullScreen) {
      loadRewardedAd();
      return false;
    }
    var rewarded = false;
    _showingFullScreen = true;
    AudioService().pause();
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadRewardedAd();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      if (!rewarded) {
        rewarded = true;
        onReward();
      }
    });
    return true;
  }

  // ====================================================================
  // REWARDED INTERSTITIAL — apare la tranziții (game over), cu recompensă.
  // Politica AdMob cere un ecran de INTRO (opt-out) afișat de apelant
  // ÎNAINTE de `showRewardedInterstitial`. Vezi game_screen (_offerBonusAd).
  // ====================================================================
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _rewardedInterstitialReady = false;
  int _rewardedInterstitialRetry = 0;
  Timer? _rewardedInterstitialRetryTimer;
  DateTime? _lastRewardedInterstitialAt;
  // Nu prea des: bonus oferit cel mult o dată la câteva minute.
  static const Duration _rewardedInterstitialGap = Duration(minutes: 3);

  void loadRewardedInterstitialAd() {
    final id = _rewardedInterstitialAdUnitId;
    if (id == null || id.isEmpty || adsDisabled) return;
    RewardedInterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialRetry = 0;
          _rewardedInterstitialRetryTimer?.cancel();
          _rewardedInterstitialAd = ad;
          _rewardedInterstitialReady = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialReady = false;
          _rewardedInterstitialRetryTimer?.cancel();
          if (adsDisabled || _rewardedInterstitialRetry >= _maxLoadRetries) {
            return;
          }
          _rewardedInterstitialRetryTimer = Timer(
              _backoff(_rewardedInterstitialRetry++),
              loadRewardedInterstitialAd);
        },
      ),
    );
  }

  /// True dacă există o reclamă pregătită ȘI a trecut cooldown-ul — adică
  /// merită să afișezi ecranul de intro pentru bonus.
  bool get canOfferRewardedInterstitial {
    if (!_rewardedInterstitialReady ||
        _rewardedInterstitialAd == null ||
        _showingFullScreen) {
      return false;
    }
    if (_lastRewardedInterstitialAt != null &&
        DateTime.now().difference(_lastRewardedInterstitialAt!) <
            _rewardedInterstitialGap) {
      return false;
    }
    return true;
  }

  /// Afișează interstitialul cu recompensă (DUPĂ ce userul a acceptat în
  /// ecranul de intro). [onReward] se apelează dacă userul câștigă recompensa.
  bool showRewardedInterstitial({required VoidCallback onReward}) {
    if (!canOfferRewardedInterstitial) {
      loadRewardedInterstitialAd();
      return false;
    }
    var rewarded = false;
    _showingFullScreen = true;
    _lastRewardedInterstitialAt = DateTime.now();
    AudioService().pause();
    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        _rewardedInterstitialReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        _rewardedInterstitialReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadRewardedInterstitialAd();
      },
    );
    _rewardedInterstitialAd!.show(onUserEarnedReward: (ad, reward) {
      if (!rewarded) {
        rewarded = true;
        onReward();
      }
    });
    return true;
  }

  // ====================================================================
  // APP OPEN (nou) — la revenirea în prim-plan, cu cooldown
  // ====================================================================
  AppOpenAd? _appOpenAd;
  bool _appOpenReady = false;
  DateTime? _appOpenLoadTime;
  DateTime? _lastAppOpenShownAt;
  static const Duration _appOpenCooldown = Duration(minutes: 4);
  static const Duration _appOpenMaxCacheAge = Duration(hours: 4);

  void loadAppOpenAd() {
    final id = _appOpenAdUnitId;
    if (id == null || id.isEmpty || adsDisabled) return;
    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenRetry = 0;
          _appOpenRetryTimer?.cancel();
          _appOpenAd = ad;
          _appOpenReady = true;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _appOpenReady = false;
          _appOpenRetryTimer?.cancel();
          if (adsDisabled || _appOpenRetry >= _maxLoadRetries) return;
          _appOpenRetryTimer = Timer(_backoff(_appOpenRetry++), loadAppOpenAd);
        },
      ),
    );
  }

  bool get _isAppOpenAvailable {
    if (!_appOpenReady || _appOpenAd == null || _appOpenLoadTime == null) {
      return false;
    }
    return DateTime.now().difference(_appOpenLoadTime!) < _appOpenMaxCacheAge;
  }

  /// Apelat la revenirea aplicației în prim-plan (vezi main.dart).
  void onAppResumed() {
    if (adsDisabled || _showingFullScreen) {
      if (!_isAppOpenAvailable) loadAppOpenAd();
      return;
    }
    if (_lastAppOpenShownAt != null &&
        DateTime.now().difference(_lastAppOpenShownAt!) < _appOpenCooldown) {
      return;
    }
    if (!_isAppOpenAvailable) {
      loadAppOpenAd();
      return;
    }
    _showingFullScreen = true;
    _lastAppOpenShownAt = DateTime.now();
    AudioService().pause();
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _appOpenReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _appOpenReady = false;
        _showingFullScreen = false;
        AudioService().resume();
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
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
