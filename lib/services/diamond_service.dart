import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Premium currency. Earned only via IAP (no gameplay grant). Used for revive +
/// future power-ups (extra hold slots, line clear, etc.).
class DiamondService {
  static final DiamondService _instance = DiamondService._internal();
  factory DiamondService() => _instance;
  DiamondService._internal();

  static const _kKey = 'tetrisDiamonds';
  int _balance = 0;
  final ValueNotifier<int> notifier = ValueNotifier(0);

  int get balance => _balance;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    _balance = p.getInt(_kKey) ?? 0;
    notifier.value = _balance;
  }

  Future<void> add(int amount) async {
    _balance += amount;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kKey, _balance);
    notifier.value = _balance;
  }

  bool canAfford(int cost) => _balance >= cost;

  Future<bool> spend(int cost) async {
    if (!canAfford(cost)) return false;
    _balance -= cost;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kKey, _balance);
    notifier.value = _balance;
    return true;
  }
}
