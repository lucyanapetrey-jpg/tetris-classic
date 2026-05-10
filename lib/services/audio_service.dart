import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  static const String _prefsKey = 'tetrismile_music_enabled';
  static const String _musicAsset = 'audio/background.mp3';

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;
  bool _initialized = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsKey) ?? true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.35);
      await _player.setSource(AssetSource(_musicAsset));
    } catch (e) {
      debugPrint('[AudioService] init failed: $e');
    }
    if (_enabled) await _tryPlay();
  }

  Future<void> _tryPlay() async {
    try {
      await _player.resume();
    } catch (_) {
      try {
        await _player.play(AssetSource(_musicAsset));
      } catch (e) {
        debugPrint('[AudioService] play failed: $e');
      }
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
    if (value) {
      await _tryPlay();
    } else {
      try { await _player.pause(); } catch (_) {}
    }
  }

  Future<void> toggle() => setEnabled(!_enabled);
  Future<void> pause() async { try { await _player.pause(); } catch (_) {} }
  Future<void> resume() async { if (_enabled) await _tryPlay(); }
}
