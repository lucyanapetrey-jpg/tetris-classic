import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/app_strings.dart';
import '../services/rewards_service.dart';
import '../widgets/settings_dialog.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rewards = RewardsService();
  int _highScore = 0;
  int _coins = 0;

  @override
  void initState() {
    super.initState();
    _checkDaily();
  }

  Future<void> _checkDaily() async {
    final r = await _rewards.claimDailyIfAvailable();
    if (r.reward > 0 && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DailyRewardScreen(day: r.day, reward: r.reward)),
      );
    }
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final c = await _rewards.getCoins();
    if (!mounted) return;
    setState(() {
      _highScore = p.getInt('highScore') ?? 0;
      _coins = c;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D14), Color(0xFF1A0F2E), Color(0xFF0D0D14)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF00E5FF), size: 28),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                      tooltip: 'Settings',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFD740)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFFFFD740), size: 20),
                          const SizedBox(width: 6),
                          Text('$_coins',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFFAB47BC), Color(0xFFFF4081)],
                  ).createShader(r),
                  child: const Text(
                    'TETRIS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      height: 0.95,
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [Color(0xFFFF4081), Color(0xFFAB47BC), Color(0xFF00E5FF)],
                  ).createShader(r),
                  child: const Text(
                    'SMILE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      height: 0.95,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    boxShadow: const [BoxShadow(color: Color(0x2200E5FF), blurRadius: 20)],
                  ),
                  child: Column(
                    children: [
                      Text(s.topScore, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 4),
                      Text('$_highScore',
                          style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00E5FF))),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 12,
                    shadowColor: const Color(0xFF00E5FF),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                    _load();
                  },
                  child: Text(s.play),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
