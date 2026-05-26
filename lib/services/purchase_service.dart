import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diamond_service.dart';
import 'purchase_notifier.dart';

class DiamondPack {
  final String id;
  final int diamonds;
  final int bonus;
  const DiamondPack(this.id, this.diamonds, this.bonus);
  int get total => diamonds + bonus;
}

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String noAdsId = 'noads_tetrismile';
  static const List<DiamondPack> diamondPacks = [
    DiamondPack('diamonds_100_tetrismile', 100, 0),
    DiamondPack('diamonds_500_tetrismile', 500, 50),
    DiamondPack('diamonds_1200_tetrismile', 1200, 200),
    DiamondPack('diamonds_3000_tetrismile', 3000, 500),
  ];

  static const _kNoAdsKey = 'tetrismile_no_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {};
  bool _available = false;
  bool _noAds = false;
  final ValueNotifier<bool> noAdsNotifier = ValueNotifier(false);

  bool get available => _available;
  bool get noAds => _noAds;
  ProductDetails? productFor(String id) => _products[id];
  List<ProductDetails> get diamondProducts =>
      diamondPacks.map((p) => _products[p.id]).whereType<ProductDetails>().toList();

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    _noAds = prefs.getBool(_kNoAdsKey) ?? false;
    noAdsNotifier.value = _noAds;
    _available = await _iap.isAvailable();
    if (!_available) return;
    final ids = <String>{noAdsId, ...diamondPacks.map((p) => p.id)};
    final response = await _iap.queryProductDetails(ids);
    for (final p in response.productDetails) {
      _products[p.id] = p;
    }
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () => _sub?.cancel());
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _grant(p);
      }
      if (p.status == PurchaseStatus.purchased) {
        unawaited(PurchaseNotifier.notifyPurchase(
          packageName: 'ro.summersmile.tetrisclassic',
          purchase: p,
        ));
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _grant(PurchaseDetails p) async {
    final prefs = await SharedPreferences.getInstance();
    if (p.productID == noAdsId) {
      _noAds = true;
      noAdsNotifier.value = true;
      await prefs.setBool(_kNoAdsKey, true);
      return;
    }
    final pack = diamondPacks.where((dp) => dp.id == p.productID).firstOrNull;
    if (pack != null) {
      await DiamondService().add(pack.total);
    }
  }

  Future<bool> buy(String productId) async {
    final product = _products[productId];
    if (product == null || !_available) return false;
    final param = PurchaseParam(productDetails: product);
    if (productId == noAdsId) {
      return _iap.buyNonConsumable(purchaseParam: param);
    }
    return _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
