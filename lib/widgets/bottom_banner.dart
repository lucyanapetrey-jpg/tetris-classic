import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';
import '../services/purchase_service.dart';

/// Banner ancorat jos. Se ascunde singur dacă userul a cumpărat „Fără reclame"
/// (ascultă `noAdsNotifier`) sau dacă reclama nu se încarcă. Nu ocupă spațiu
/// până nu e încărcat efectiv (fără gol vizual).
class BottomBanner extends StatefulWidget {
  const BottomBanner({super.key});

  @override
  State<BottomBanner> createState() => _BottomBannerState();
}

class _BottomBannerState extends State<BottomBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    PurchaseService.instance.noAdsNotifier.addListener(_onNoAdsChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      _load();
    }
  }

  void _onNoAdsChanged() {
    if (PurchaseService.instance.noAds) {
      _ad?.dispose();
      _ad = null;
      if (mounted) setState(() => _loaded = false);
    }
  }

  Future<void> _load() async {
    if (!mounted || PurchaseService.instance.noAds) return;
    final widthDp = MediaQuery.of(context).size.width.truncate();
    final banner = await AdService().createAnchoredBanner(
      widthDp: widthDp,
      onLoaded: () {
        if (mounted) setState(() => _loaded = true);
      },
      onFailed: () {
        if (mounted) setState(() => _loaded = false);
      },
    );
    if (banner == null || !mounted) return;
    _ad = banner;
    await banner.load();
  }

  @override
  void dispose() {
    PurchaseService.instance.noAdsNotifier.removeListener(_onNoAdsChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
