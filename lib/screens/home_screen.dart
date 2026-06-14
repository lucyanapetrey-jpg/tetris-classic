import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/app_strings.dart';
import '../services/diamond_service.dart';
import '../services/rewards_service.dart';
import '../widgets/bottom_banner.dart';
import '../widgets/glass.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/shop_dialog.dart';
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

  Future<void> _openShop() async {
    await showDialog(context: context, builder: (_) => const ShopDialog());
    _load();
  }

  Widget _pill({
    required IconData icon,
    required Color color,
    required String text,
    VoidCallback? onTap,
  }) {
    return GlassCard(
      radius: 22,
      blur: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderColor: color.withValues(alpha: 0.55),
      glowColor: color,
      glowBlur: 16,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _glassIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GlassCard(
      radius: 18,
      blur: 14,
      padding: const EdgeInsets.all(10),
      borderColor: color.withValues(alpha: 0.5),
      glowColor: color,
      glowBlur: 14,
      onTap: onTap,
      child: Icon(icon, color: color, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      bottomNavigationBar: const SafeArea(child: BottomBanner()),
      body: NeonBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _glassIconButton(
                      Icons.settings,
                      const Color(0xFF00E5FF),
                      () => showDialog(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                    ),
                    Row(
                      children: [
                        _pill(
                          icon: Icons.monetization_on,
                          color: const Color(0xFFFFD740),
                          text: '$_coins',
                        ),
                        const SizedBox(width: 8),
                        // Soldul de diamante — tap deschide magazinul.
                        ValueListenableBuilder<int>(
                          valueListenable: DiamondService().notifier,
                          builder: (_, diamonds, _) => _pill(
                            icon: Icons.diamond,
                            color: const Color(0xFF40C4FF),
                            text: '$diamonds',
                            onTap: _openShop,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _glassIconButton(
                            Icons.storefront, const Color(0xFF00E5FF), _openShop),
                      ],
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                _title('BLOCK', const [Color(0xFF00E5FF), Color(0xFFAB47BC), Color(0xFFFF4081)]),
                _title('SMILE', const [Color(0xFFFF4081), Color(0xFFAB47BC), Color(0xFF00E5FF)]),
                const Spacer(flex: 3),
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  glowColor: const Color(0xFF00E5FF),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: Color(0xFFFFD740), size: 22),
                          const SizedBox(width: 8),
                          Text(s.topScore,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('$_highScore',
                          style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Color(0xFF00E5FF), blurRadius: 18),
                              ])),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                NeonButton(
                  label: s.play,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    );
                    _load();
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text, List<Color> colors) {
    return ShaderMask(
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 66,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8,
          height: 0.95,
          shadows: [Shadow(color: Color(0x8800E5FF), blurRadius: 30)],
        ),
      ),
    );
  }
}
