import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  static const String _prefsKey = 'tetrismile_locale';
  Locale? _locale;
  bool _initialized = false;

  Locale? get locale => _locale;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) {
      _locale = Locale(code);
    }
  }

  Future<void> setLocale(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_prefsKey);
      _locale = null;
    } else {
      await prefs.setString(_prefsKey, code);
      _locale = Locale(code);
    }
    notifyListeners();
  }
}
